# iOS 中的锁

![](https://github.com/loveway/iOS-Knowledge/blob/master/image/iOS-lock.png?raw=true)

上图是 ibireme 在 [不再安全的 OSSpinLock](https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/) 一文中列出的各种锁的性能对比，下面我们来逐个分析。
## iOS 中的各种锁
### 1. OSSpinLock
顾名思义是自旋锁，性能最高的锁。原理很简单，就是一直 do while 忙等。它的缺点是当等待时会消耗大量 CPU 资源，所以它不适用于较长时间的任务。OSSpinLock 不再安全，主要原因发生在低优先级线程拿到锁时，高优先级线程进入忙等(busy-wait)状态，消耗大量 CPU 时间，从而导致低优先级线程拿不到 CPU 时间，也就无法完成任务并释放锁。这种问题被称为优先级反转。

自旋锁的实现思路
```objc
bool lock = false; // 一开始没有锁上，任何线程都可以申请锁  
do {  
    while(lock); // 如果 lock 为 true 就一直死循环，相当于申请锁
    lock = true; // 挂上锁，这样别的线程就无法获得锁
        Critical section  // 临界区
    lock = false; // 相当于释放锁，这样别的线程可以进入临界区
        Reminder section // 不需要锁保护的代码        
}
```

自旋锁的使用
```objc
#import <libkern/OSAtomic.h>
@interface ViewController () {
        OSSpinLock lock;//锁必须定义全局变量，不然容易被释放
}

lock = OS_SPINLOCK_INIT;
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    OSSpinLockLock(&lock);
    NSLog(@"1--");
    sleep(2);
    NSLog(@"2--");
    OSSpinLockUnlock(&lock);
});
    
dispatch_queue_t queue = dispatch_queue_create("mm", DISPATCH_QUEUE_CONCURRENT);
dispatch_async(queue, ^{
    OSSpinLockLock(&lock);
    sleep(1);
    NSLog(@"3--");
    OSSpinLockUnlock(&lock);
});
```

输出

```objc
2020-01-03 11:26:10.651103+0800 OC_test[17893:646992] 1--
2020-01-03 11:26:12.652847+0800 OC_test[17893:646992] 2--
2020-01-03 11:26:13.697083+0800 OC_test[17893:646986] 3--
```

由于 OSSpinLock 已经不再安全，所以在 iOS10 OSSpinLock 已经废弃掉了

```objc
typedef int32_t OSSpinLock OSSPINLOCK_DEPRECATED_REPLACE_WITH(os_unfair_lock);

...

#define OSSPINLOCK_DEPRECATED_REPLACE_WITH(_r) \
	__OS_AVAILABILITY_MSG(macosx, deprecated=10.12, OSSPINLOCK_DEPRECATED_MSG(_r)) \
	__OS_AVAILABILITY_MSG(ios, deprecated=10.0, OSSPINLOCK_DEPRECATED_MSG(_r)) \
	__OS_AVAILABILITY_MSG(tvos, deprecated=10.0, OSSPINLOCK_DEPRECATED_MSG(_r)) \
	__OS_AVAILABILITY_MSG(watchos, deprecated=3.0, OSSPINLOCK_DEPRECATED_MSG(_r))
#else
#undef OSSPINLOCK_DEPRECATED
#define OSSPINLOCK_DEPRECATED 0
#define OSSPINLOCK_DEPRECATED_REPLACE_WITH(_r)
#endif
```

取而代之的是 os_unfair_lock，


Reference:
> [不再安全的 OSSpinLock](https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/)
>
>
>
>
>
