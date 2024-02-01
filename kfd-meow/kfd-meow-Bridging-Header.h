//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Foundation/Foundation.h>
#include "libkfd.h"
#include "pplrw.h"
#include "troll.h"
#include "meow.h"

uint64_t _kfd = 0;

uint64_t kopen_bridge(uint64_t puaf_method, uint64_t debug) {
    uint64_t exploit_type = (1 << puaf_method);
    _kfd = kopen(exploit_type, debug);
    offset_exporter();
    if(debug == 0) {
        if(isarm64e()) {
            sleep(1);
            //test_pplrw();
        } else {
            sleep(1);
            meow();
        }
    } else {
        TrollStoreinstall();
    }
    if(_kfd != 0)
        return _kfd;
    
    return 0;
}

uint64_t kclose_bridge(uint64_t _kfd) {
    kclose(_kfd);
    return 0;
}
