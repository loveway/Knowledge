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
// 销毁属性
pthread_mutexattr_destroy(&attr);

```

### 5. NSLock
NSLock 是一种低级别的锁，一旦获取到了锁，执行进入临界区，且不会允许超过一个线程并行执行，释放锁则意味着临界区结束。NSLock 在内部封装了一个 pthread_mutex，属性为 PTHREAD_MUTEX_ERRORCHECK，它会损失一定性能换来错误提示。

```objc
#define    MLOCK \
- (void) lock\
{\
  int err = pthread_mutex_lock(&_mutex);\
  // 错误处理 ……
}
```

这里使用宏定义的原因是，OC 内部还有其他几种锁，他们的 lock 方法都是一模一样，仅仅是内部 pthread_mutex 互斥锁的类型不同。通过宏定义，可以简化方法的定义。

NSLock 比 pthread_mutex 略慢的原因在于它需要经过方法调用，同时由于缓存的存在，多次方法调用不会对性能产生太大的影响。

**需要注意的是使用 `unlock` 释放锁的时候必须是在同一个线程操作，不同线程释放锁会导致不可预知的行为。**

还有就是你不可用 NSLock 来实现递归锁，在同一线程两次调用 `lock` 方法将锁死线程。你可以用 NSRecursiveLock 来实现递归锁。

### 6. NSRecursiveLock

递归锁也是通过 pthread_mutex_lock 函数来实现，在函数内部会判断锁的类型，如果显示是递归锁，就允许递归调用，仅仅将一个计数器加一，锁的释放过程也是同理。

NSRecursiveLock 与 NSLock 的区别在于内部封装的 `pthread_mutex_t` 对象的类型不同，前者的类型为 `PTHREAD_MUTEX_RECURSIVE`。

在调用 `lock` 之前， NSLock 必须先调用 `unlock`。正如名字所暗示的那样，NSRecursiveLock 允许在解锁前调用多次。如果解锁的次数与锁定的次数相匹配，则认定锁被释放，其他线程可以获取锁。

当类中有多个方法使用同一个锁进行同步，且一个方法调用另一个方法时， NSRecursiveLock 就非常有用了

```objc
@property (nonatomic, strong) NSRecursiveLock *lock;

...

//初始化 lock
_lock = [[NSRecursiveLock alloc] init];
    
- (void)func1 {
    [_lock lock];//func1 获取锁
    [self func2];
    [_lock unlock];//释放锁
}

- (void)func2 {
    [_lock lock];//func2 从已经获取到的锁中再次获取到锁
    NSLog(@"do something thread safe !");
    [_lock unlock];//释放锁
}
```

如上代码，由于每个锁定操作都有一个与之相对应的解锁操作，所以锁是被释放成功的，并且可以被其他线程所获取。

### 7. NSCondition

NSCondition 的底层是通过条件变量(condition variable) `pthread_cond_t` 来实现的。条件变量有点像信号量，提供了线程阻塞与信号机制，因此可以用来阻塞某个线程，并等待某个数据就绪，随后唤醒线程，比如常见的生产者-消费者模式。

```objc
NSCondition *condition = [NSCondition new];
NSMutableArray *collector = @[].mutableCopy;
    
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    while (1) {
        [condition lock];
        if (collector.count == 0) {
            NSLog(@"consumer wait ...");
            [condition wait];
        }
        [collector removeLastObject];
        NSLog(@"consume a product.");
        [condition unlock];
    }

});
    
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    while (1) {
        [condition lock];
        [collector addObject:@"1"];
        NSLog(@"produce %ld product.", collector.count);
        [condition signal];
        [condition unlock];
        sleep(1);
    }
});
```

输出

```objc
2020-01-03 16:35:20.009392+0800 OC_test[21416:794029] produce 1 product.
2020-01-03 16:35:20.009656+0800 OC_test[21416:794032] consume a product.
2020-01-03 16:35:20.009959+0800 OC_test[21416:794032] consumer wait ...
2020-01-03 16:35:21.014093+0800 OC_test[21416:794029] produce 1 product.
2020-01-03 16:35:21.014283+0800 OC_test[21416:794032] consume a product.
2020-01-03 16:35:21.014399+0800 OC_test[21416:794032] consumer wait ...
2020-01-03 16:35:22.015470+0800 OC_test[21416:794029] produce 1 product.
2020-01-03 16:35:22.015717+0800 OC_test[21416:794032] consume a product.
2020-01-03 16:35:22.015956+0800 OC_test[21416:794032] consumer wait ...

...

```

它需要与互斥锁配合使用:

```objc
void consumer () { // 消费者  
    pthread_mutex_lock(&mutex);
    while (data == NULL) {
        pthread_cond_wait(&condition_variable_signal, &mutex); // 等待数据
    }
    // --- 有新的数据，以下代码负责处理 ↓↓↓↓↓↓
    // temp = data;
    // --- 有新的数据，以上代码负责处理 ↑↑↑↑↑↑
    pthread_mutex_unlock(&mutex);
}

void producer () {  
    pthread_mutex_lock(&mutex);
    // 生产数据
    pthread_cond_signal(&condition_variable_signal); // 发出信号给消费者，告诉他们有了新的数据
    pthread_mutex_unlock(&mutex);
}
```

自然我们会有疑问:“如果不用互斥锁，只用条件变量会有什么问题呢？”。问题在于，temp = data; 这段代码不是线程安全的，也许在你把 data 读出来以前，已经有别的线程修改了数据。因此我们需要保证消费者拿到的数据是线程安全的。

为什么要使用 NSCondition？信号量可以一定程度上替代 condition，但是互斥锁不行。在以上给出的生产者-消费者模式的代码中， `pthread_cond_wait` 方法的本质是锁的转移，消费者放弃锁，然后生产者获得锁，同理，`pthread_cond_signal` 则是一个锁从生产者到消费者转移的过程。

`[condition broadcast]` 方法会通知所有的等待线程，而 `signal` 只会通知一个线程。

### 7. NSConditionLock

NSConditionLock 借助 NSCondition 来实现，它的本质就是一个生产者-消费者模型。NSConditionLock 的内部持有一个 NSCondition 对象，以及 _condition_value 属性，在初始化时就会对这个属性进行赋值:

```objc
- (id) initWithCondition: (NSInteger)value {
    if (nil != (self = [super init])) {
        _condition = [NSCondition new]
        _condition_value = value;
    }
    return self;
}

...

- (void) lockWhenCondition: (NSInteger)value {
    [_condition lock];
    while (value != _condition_value) {
        [_condition wait];
    }
}

...

- (void) unlockWithCondition: (NSInteger)value {
    _condition_value = value;
    [_condition broadcast];
    [_condition unlock];
}
```

使用 

```objc
#define START 1
#define TASK_1_FINISHED 2
#define TASK_2_FINISHED 3
#define TASK_3_FINISHED 4
#define TASK_4_FINISHED 5

...

//main thread
   NSConditionLock *lock = [[NSConditionLock alloc] initWithCondition:START];

   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       [lock lockWhenCondition:START];
       NSLog(@"first thread lock");
       sleep(2);
       NSLog(@"first thread unlock");
       [lock unlockWithCondition:TASK_1_FINISHED];
   });
   
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       [lock lockWhenCondition:TASK_1_FINISHED];
       NSLog(@"second thread lock");
       sleep(3);
       NSLog(@"second thread unlock");
       [lock unlockWithCondition:TASK_2_FINISHED];
   });
   
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       [lock lockWhenCondition:TASK_2_FINISHED];
       NSLog(@"third thread lock");
       sleep(1);
       NSLog(@"third thread unlock");
       [lock unlockWithCondition:TASK_3_FINISHED];
   });
   
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       [lock lockWhenCondition:TASK_4_FINISHED];
       NSLog(@"fourth thread lock");
       sleep(2);
       NSLog(@"fourth thread unlock");
       [lock unlockWithCondition:TASK_4_FINISHED];
   });
```

输出

```objc
2020-01-06 16:51:52.938745+0800 OC_test[2462:92960] first thread lock
2020-01-06 16:51:54.940206+0800 OC_test[2462:92960] first thread unlock
2020-01-06 16:51:54.940708+0800 OC_test[2462:92963] second thread lock
2020-01-06 16:51:57.941255+0800 OC_test[2462:92963] second thread unlock
2020-01-06 16:51:57.941691+0800 OC_test[2462:92964] third thread lock
2020-01-06 16:51:58.942492+0800 OC_test[2462:92964] third thread unlock
```

可以看到 `fourth thread lock` 和 `fourth thread unlock` 并没有输出，这是因为 线程3 走完条件变成了 `TASK_3_FINISHED`，而 线程4 上锁的条件是 `TASK_4_FINISHED`，所以并没有锁定。

### 8. @synchronized

这其实是一个 OC 层面的锁， 主要是通过牺牲性能换来语法上的简洁与可读。

synchronized 中传入的 object 的内存地址，被用作 key，通过 hash map 对应的一个系统维护的递归锁。
* synchronized 是使用的递归 mutex 来做同步。
* `@synchronized(nil)` 不起任何作用

慎用 `@synchronized(self)`，尽量粒度区分开，如下

```objc
@synchronized (tokenA) {
    [arrA addObject:obj];
}

@synchronized (tokenB) {
    [arrB addObject:obj];
}
```

Reference:
> [不再安全的 OSSpinLock](https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/)
>
> [深入理解 iOS 开发中的锁](https://bestswifter.com/ios-lock/)
>
> [NSLock](https://developer.apple.com/documentation/foundation/nslock)
>
> [关于 @synchronized，这儿比你想知道的还要多](http://yulingtianxia.com/blog/2015/11/01/More-than-you-want-to-know-about-synchronized/)
> 
> [正确使用多线程同步锁@synchronized()](http://mrpeak.cn/blog/synchronized/)
