//
//  IOSurface.h
//  kfd
//
//  Created by Lars Fröder on 30.07.23.
//

#ifndef IOSurface_h
#define IOSurface_h

struct IOSurface {
    uint64_t isa;
    uint64_t PixelFormat;
    uint64_t AllocSize;
    uint64_t UseCountPtr;
    uint64_t IndexedTimestampPtr;
    uint64_t ReadDisplacement;
    const uint64_t LockResultSize;
};

static const struct IOSurface IOSurface_versions[] = {
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x360,
        .ReadDisplacement       = 0x14,
        .LockResultSize         = 0xDD0
    }, // iOS 12.0 - 12.5 arm64/arm64e
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x360,
        .ReadDisplacement       = 0x14,
        .LockResultSize         = 0xDD0
    }, // iOS 13.0 - 13.7 arm64/arm64e
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x360,
        .ReadDisplacement       = 0x14,
        .LockResultSize         = 0xF60
    }, // iOS 14.0 - 14.4 arm64/arm64e
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x360,
        .ReadDisplacement       = 0x14,
        .LockResultSize         = 0xF60
    }, // iOS 14.5 - 14.8 arm64/arm64e
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x360,
        .ReadDisplacement       = 0x14,
        .LockResultSize         = 0xF60
    }, // iOS 15.0 - 15.1 arm64
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x360,
        .ReadDisplacement       = 0x14,
        .LockResultSize         = 0xF60
    }, // iOS 15.0 - 15.1 arm64e
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x360,
        .ReadDisplacement       = 0x14,
        .LockResultSize         = 0xF60
    }, // iOS 15.2 - 15.3 arm64
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x360,
        .ReadDisplacement       = 0x14,
        .LockResultSize         = 0xF60
    }, // iOS 15.2 - 15.3 arm64e
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x360,
        .ReadDisplacement       = 0x14,
        .LockResultSize         = 0xF60
    }, // iOS 15.4 - 15.7 arm64
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x360,
        .ReadDisplacement       = 0x14,
        .LockResultSize         = 0xF60
    }, // iOS 15.4 - 15.7 arm64e
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x368,
        .ReadDisplacement       = 0x18,
        .LockResultSize         = 0xA68
    }, // iOS 16.0 - 16.1 arm64
    
    {
        //TODO: check those offsets
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x368,
        .ReadDisplacement       = 0x18,
        .LockResultSize         = 0xA68
    }, // iOS 16.0 - 16.1 arm64e
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x368,
        .ReadDisplacement       = 0x18,
        .LockResultSize         = 0xA68
    }, // iOS 16.2 - 16.3 arm64
    
    {
        //TODO: check those offsets
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x368,
        .ReadDisplacement       = 0x18,
        .LockResultSize         = 0xA68
    }, // iOS 16.2 - 16.3 arm64e
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x368,
        .ReadDisplacement       = 0x18,
        .LockResultSize         = 0xA68
    }, // iOS 16.4 - 16.6 arm64
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xA4,
        .AllocSize              = 0xAC,
        .UseCountPtr            = 0xC0,
        .IndexedTimestampPtr    = 0x368,
        .ReadDisplacement       = 0x18,
        .LockResultSize         = 0xA68
    }, // iOS 16.4 - 16.6 arm64e
    
    {
        .isa                    = 0x0,
        .PixelFormat            = 0xAC,
        .AllocSize              = 0xB4,
        .UseCountPtr            = 0xC8,
        .IndexedTimestampPtr    = 0x390,
        .ReadDisplacement       = 0x18,
        .LockResultSize         = 0xA68
    }, // iOS 17.0 beta 1 arm64
};

typedef uint64_t IOSurface_isa_t;
typedef uint32_t IOSurface_PixelFormat_t;
typedef uint32_t IOSurface_AllocSize_t;
typedef uint64_t IOSurface_UseCountPtr_t;
typedef uint64_t IOSurface_IndexedTimestampPtr_t;
typedef uint32_t IOSurface_ReadDisplacement_t;
typedef uint64_t IOSurface_LockResultSize_t;


#endif /* IOSurface_h */
