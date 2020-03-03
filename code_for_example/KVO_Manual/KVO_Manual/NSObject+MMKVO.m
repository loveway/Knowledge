//
//  NSObject+MMKVO.m
//  OC_test
//
//  Created by HenryCheng on 2020/3/2.
//  Copyright © 2020 igancao. All rights reserved.
//

#import "NSObject+MMKVO.h"
#import <objc/message.h>

@implementation NSObject (MMKVO)

- (void)mm_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    
    NSString *oldClassName = NSStringFromClass(self.class);
    NSString *newClassName = [NSString stringWithFormat:@"MMKVONotifying_%@", oldClassName];
    //1、创建一个类名为 MMKVONotifying_ 前缀的子类
    Class newClass = objc_allocateClassPair(self.class, newClassName.UTF8String, 0);
    //2、注册新类
    objc_registerClassPair(newClass);
    //3、重写子类的 setName: 方法，其实也就是给子类添加一个 setName: 方法（新的类继承于父类，但是其实子类中并没有父类的方法，我们平时能在子类中重写父类的方法其实也就是在子类中没查找到，最后查找到父类的方法）
    class_addMethod(newClass, @selector(setName:), (IMP)mm_setName, "v@:@");
    //4、修改 isa 指针
    object_setClass(self, newClass);
    //5、绑定 observer 到当前对象，以便后面通知给观察者
    objc_setAssociatedObject(self, @selector(setName:), observer, OBJC_ASSOCIATION_ASSIGN);
}

void mm_setName(id self, SEL _cmd, NSString *name) {
    
    //1、拿到当前类，也就是子类，因为前面修改了 isa 指针指向子类
    Class class = [self class];
    //2、修改 isa 指向父类
    object_setClass(self, class_getSuperclass(class));
    //3、父类调用 setName: (这里需要做个类型强转, 否则会报too many argument的错误)
    ((void (*)(id, SEL, id))objc_msgSend)(self, @selector(setName:), name);
    //4、拿到观察者，发送通知
    id observer = objc_getAssociatedObject(self, @selector(setName:));
    if (observer) {
        ((void (*)(id, SEL, id, id, id, id))objc_msgSend)(observer,
                                                          @selector(observeValueForKeyPath:ofObject:change:context:),
                                                          @"name", name,
                                                          @{@"new": name, @"kind": @1},
                                                          nil);
    }
    //5、把 isa 改回来
    object_setClass(self, class);
    
    /**
     上面的2、3、5 步也可以直接用
     ((void (*)(id, SEL, id))objc_msgSendSuper)(class, @selector(setName:), name);
     方法，这样就不用把 isa 改来改去
     */
}

@end
