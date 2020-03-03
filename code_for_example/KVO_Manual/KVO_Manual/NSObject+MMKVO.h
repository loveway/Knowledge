//
//  NSObject+MMKVO.h
//  OC_test
//
//  Created by HenryCheng on 2020/3/2.
//  Copyright © 2020 igancao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (MMKVO)

- (void)mm_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;

@end

NS_ASSUME_NONNULL_END
