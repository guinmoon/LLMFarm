//
//  ExceptionCatcher.h
//  LLMFarm
//
//  Created by guinmoon on 05.06.2023.
//

#ifndef ExceptionCatcher_h
#define ExceptionCatcher_h
#import <Foundation/Foundation.h>

NS_INLINE NSException * _Nullable tryBlock(void(^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}


#endif /* ExceptionCatcher_h */
