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

取而代之的是 os_unfair_lock，他的用法和 OSSpinLock 差不多。
### 2. os_unfair_lock

```objc
#import <os/lock.h>

@interface ViewController () {
    os_unfair_lock lock;
}
@end

...
//#define OS_UNFAIR_LOCK_INIT ((os_unfair_lock){0})
// 初始化
lock = OS_UNFAIR_LOCK_INIT;
// 尝试加锁
os_unfair_lock_trylock(&lock);
// 加锁
os_unfair_lock_lock(&lock);
// 解锁
os_unfair_lock_unlock(&lock);

```

os_unfair_lock 和 OSSpinLock 的区别就是：OSSpinLock 是自旋锁，等待锁的线程会处于忙等状态，一直占用着CPU资源。而替代 OSSpinLock 的 os_unfair_lock则是互斥锁，它会使等待的线程进入休眠状态，不再占用CPU资源。
#### 自旋锁互斥锁怎么选择
当预计线程等待锁的时间很短，或者加锁的代码（临界区）经常被调用，但竞争情况很少发生，再或者CPU资源不紧张，拥有多核处理器的时候使用自旋锁比较合适。

而当预计线程等待锁的时间较长，CPU是单核处理器，或者临界区有I/O操作，或者临界区代码复杂或者循环量大，临界区竞争非常激烈的时候使用互斥锁比较合适。

### 3. dispatch_semaphore

关于 dispatch_semaphore 我们在 [关于 iOS 的多线程](https://github.com/loveway/iOS-Knowledge/blob/master/knowledge/iOS-multi-threading.md) 已经总结了它的用法。

dispatch_semaphore 使用比较简单，主要就三个API：`create`、`wait` 和 `signal`。

```objc
_lock = dispatch_semaphore_create(1); 
dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER); 

dispatch_semaphore_signal(_lock);
```

信号量最终会调用下面的函数

```objc
int sem_wait (sem_t *sem) {  
  int *futex = (int *) sem;
  if (atomic_decrement_if_positive (futex) > 0)
    return 0;
  int err = lll_futex_wait (futex, 0);
    return -1;
)
```

首先会把信号量的值减一，并判断是否大于零。如果大于零，说明不用等待，所以立刻返回。具体的等待操作在 lll_futex_wait 函数中实现，lll 是 low level lock 的简称。这个函数通过汇编代码实现，调用到 SYS_futex 这个系统调用，使线程进入睡眠状态，主动让出时间片，这个函数在互斥锁的实现中，也有可能被用到。

自旋锁和信号量的实现都非常简单，所以耗时先对来说短。

### 4. pthread_mutex

pthread 表示 POSIX thread，定义了一组跨平台的线程相关的 API，pthread_mutex 表示互斥锁。互斥锁的实现原理与信号量非常相似，不是使用忙等，而是阻塞线程并睡眠，需要进行上下文切换。

```objc
#import <pthread.h>

...
//创建属性
pthread_mutexattr_t attr;
pthread_mutexattr_init(&attr);
pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);
    
pthread_mutex_t mutex;
pthread_mutex_init(&mutex, &attr);//初始化锁
pthread_mutex_lock(&mutex);//申请锁
 //code
pthread_mutex_trylock(&mutex);//尝试锁
pthread_mutex_unlock(&mutex);//释放锁
```

### 5. NSLock



Reference:
> [不再安全的 OSSpinLock](https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/)
>
> [深入理解 iOS 开发中的锁](https://bestswifter.com/ios-lock/)
>
>
>
