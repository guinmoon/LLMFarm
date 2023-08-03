#import "spm-headers/package_helper.h"
#import <Foundation/Foundation.h>

NSString * get_core_bundle_path(){
    NSString *path = [SWIFTPM_MODULE_BUNDLE resourcePath];
    return  path;
}
