# 关于 iOS 的多线程
## 一、进程与线程
### [进程](https://zh.wikipedia.org/wiki/%E8%A1%8C%E7%A8%8B)
进程（process）是计算机中的程序关于某数据集合上的一次运行活动，是系统进行资源分配和调度的基本单位，是操作系统结构的基础。在早期面向进程设计的计算机结构中，进程是程序的基本执行实体，在当代面向线程设计的计算机结构中，进程是线程的容器，
程序是指令、数据及其组织形式的描述，进程是程序的实体。

简单来说就是：
1. 进程是指在系统中正在运行的一个应用程序
2. 每个进程之间是独立的，每个进程均运行在其专用且受保护的内存空间内
3. 比如同时打开迅雷、Xcode，系统就会分别启动 2 个进程

### [线程](https://zh.wikipedia.org/wiki/%E7%BA%BF%E7%A8%8B)
线程（thread）是组成进程的子单元，操作系统的调度器可以对线程进行单独的调度。实际上，所有的并发编程 API 都是构建于线程之上的 —— 包括 GCD 和操作队列（operation queues）。

在iOS中每个进程启动后都会建立一个主线程（UI线程），这个线程是其他线程的父线程。由于在iOS中除了主线程，其他子线程是独立于 Cocoa Touch 的，所以只有主线程可以更新 UI 界面。

简单来说，一个进程要想执行任务，必须得有线程。一个进程中至少包含一条线程，即主线程，创建线程的目的就是为了开启一条新的执行路径，运行指定的代码，与主线程中的代码实现同时运行。
### 进程和线程之间的关系
1. 一个线程只能属于一个进程，而一个进程可以有多个线程，但至少有一个线程（通常说的主线程）。   
2. 资源分配给进程，同一进程的所有线程共享该进程的所有资源。    
3. 线程在执行过程中，需要协作同步。不同进程的线程间要利用消息通信的办法实现同步。    
4. 处理机分给线程，即真正在处理机上运行的是线程。    
5. 线程是指进程内的一个执行单元，也是进程内的可调度实体。

### 进程和线程之间的区别
三个角度来看：
1. 调度：线程作为调度和分配的基本单位，进程作为拥有资源的基本单位。
2. 并发性：不仅进程之间可以并发执行，同一个进程的多个线程之间也可以并发执行。
3. 拥有资源：进程是拥有资源的一个独立单位，线程不拥有系统资源，但可以访问隶属于进程的资源。

### 多线程
多线程（multithreading），是指从软件或者硬件上实现多个线程并发执行的技术。具有多线程能力的计算机因有硬件支持而能够在同一时间执行多于一个线程，进而提升整体处理性能。

多线程可以在单核 CPU 上同时（或者至少看作同时）运行。操作系统将小的时间片分配给每一个线程，这样就能够让用户感觉到有多个任务在同时进行。如果 CPU 是多核的，那么线程就可以真正的以并发方式被执行，从而减少了完成某项操作所需要的总时间。

**多线程原理**
* 同一时间，CPU 只能处理1条线程，只有1条线程在工作（执行）
* 多线程并发（同时）执行，其实是CPU快速地在多条线程之间调度（切换）
* 如果CPU调度线程的时间足够快，就造成了多线程并发执行的假象
注意：多线程并发，并不是cpu在同一时刻同时执行多个任务，只是CPU调度足够快，造成的假象

**多线程优点**
* 能适当提高程序的执行效率
* 能适当提高资源利用率（CPU、内存利用率）

**多线程缺点**
* 开启线程需要占用一定的内存空间（默认情况下，主线程占用1M，子线程占用512KB），如果开启大量的线程，会占用大量的内存空间，降低程序的性能
* 线程越多，CPU在调度线程上的开销就越大

## 二、并行与并发
如果某个系统支持两个或者多个动作（Action）**同时存在** ，那么这个系统就是一个并发系统。如果某个系统支持两个或者多个动作 **同时执行** ，那么这个系统就是一个并行系统。并发系统与并行系统这两个定义之间的关键差异在于 **“存在”** 这个词。
在并发程序中可以同时拥有两个或者多个线程。这意味着，如果程序在单核处理器上运行，那么这两个线程将交替地换入或者换出内存。这些线程是同时“存在”的——每个线程都处于执行过程中的某个状态。如果程序能够并行执行，那么就一定是运行在多核处理器上。此时，程序中的每个线程都将分配到一个独立的处理器核上，因此可以同时运行。
我相信你已经能够得出结论—— **“并行”概念是“并发”概念的一个子集。** 也就是说，你可以编写一个拥有多个线程或者进程的并发程序，但如果没有多核处理器来执行这个程序，那么就不能以并行方式来运行代码。因此，凡是在求解单个问题时涉及多个执行流程的编程模式或者执行行为，都属于并发编程的范畴。

摘自：《并发的艺术》 — 〔美〕布雷谢斯

举个例子：
吃饭的时候先接电话跟后接电话的比较更像是中断优先级高低的不同。

并发应该是一手筷子，一手电话，说一句话，咽一口饭。

并行是咽一口饭同时说一句话，而这光靠一张嘴是办不到的，至少两张嘴。


## 三、iOS 中的四种多线程方案
OS 中的多线程的解决方案分别是：pthread，NSThread，GCD， NSOperation。
他们的使用对比如下：

| 类型 | 简介 | 语言 | 生命周期 | 使用频率 | 使用特点 |
| :-------: |:-------|:-------:|:-------:|:-------:|:-------|
| pthread | 1. 一套通用的多线程 API<br>2. 适用于 Linux/Windows/Unix等多系统<br>3. 跨品台可移植<br>4. 使用难度大 | C  | 程序员管理  | 几乎不用 ||
| NSThread | 1. Objective-C 对 pthread 的一个封装<br>2. 通过封装，在 Cocoa 环境中，可以让代码看起来更加亲切<br>3. 更加面向对象，可直接操做线程 | OC  | 程序员管理  | 偶尔使用 |1. 使用 NSThread 对象建立一个线程非常方便<br>2. 要使用 NSThread 管理多个线程非常困难，不推荐使用<br>3. 经常使用 `[NSThread currentThread]` 获得任务所在线程, `[NSThread sleepForTimeInterval:0.3f]` 使线程休眠|
| GCD | 1. 旨在替代 pthread<br>2. 让开发者更加容易的使用设备上的多核CPU<br>| C  | 自动管理  | 经常使用 |1. 是基于C语言的底层API<br>2. 用 Block 定义任务，使用起来非常灵活便捷<br>3.提供了更多的控制能力以及操作队列中所不能使用的底层函数|
| NSOperation | 1. 基于 GCD<br>2. GCD 提供了更加底层的控制，而操作队列则在 GCD 之上实现了一些方便的功能<br>3. 使用更加面向对象| C  | 自动管理  | 经常使用 |1. 是使用 GCD 实现的一套 Objective-C 的 API<br>2. 是面向对象的线程技术<br>3. 提供了一些在 GCD 中不容易实现的特性，如：限制最大并发数量、操作之间的依赖关系|

### GCD 和 NSOperation 有什么区别

1. GCD 是纯 C 语言的 API；NSOperation 是基于 GCD 的 OC 版本封装
2. GCD 只支持 FIFO 的队列；NSOperation 可以很方便地调整执行顺序，设置最大并发数量
3. NSOperationQueue 可以轻松在 operation 间设置依赖关系，而 GCD 需要些很多代码才能实现
4. NSOperationQueue 支持 KVO，可以检测 operation 是否正在执行(isExecuted)，是否结束(isFinish), 是否取消(isCancel)
5. GCD 的执行速度比 NSOperation 快，GCD 给予你更多的控制权力以及操作队列中所不能使用的底层函数

GCD 是比较底层的封装，我们知道较低层的代码一般性能都是比较高的，相对于NSOperationQueue。所以追求性能，而功能够用的话就可以考虑使用GCD。如果异步操作的过程需要更多的用户交互和被UI显示出来，NSOperationQueue 会是一个好选择。如果任务之间没有什么依赖关系，而是需要更高的并发能力，GCD 则更有优势。

### 1、pthread
```objc
#import <pthread.h>

// 1. 创建线程: 定义一个pthread_t类型变量
pthread_t thread;
// 2. 开启线程: 执行任务
pthread_create(&thread, NULL, run, NULL);
// 3. 设置子线程的状态设置为 detached，该线程运行结束后会自动释放所有资源
pthread_detach(thread);

void *run(void *params) {
    NSLog(@"%@", [NSThread currentThread]);
    return NULL;
}
```
输出
```objc
OC_test[96204:2452609] <NSThread: 0x6000000a6b80>{number = 7, name = (null)}
```
一些其他用法

| func | description |
| :------- |:-------|
| `pthread_create()` | 创建一个线程 |
| `pthread_cancel()` | 中断另外一个线程的运行 |
| `pthread_join()`   | 阻塞当前的线程，直到另外一个线程运行结束|
| `pthread_attr_init()` |初始化线程的属性|
| `pthread_attr_setdetachstate()` |设置脱离状态的属性（决定这个线程在终止时是否可以被结合）|
| `pthread_attr_getdetachstate()` |获取脱离状态的属性|
| `pthread_attr_destroy()` |删除线程的属性| 
| `pthread_kill()` |向线程发送一个信号| 

### 2、NSThread
NSThread 是苹果官方提供的，使用起来比 pthread 更加面向对象，简单易用，可以直接操作线程对象。不过也需要需要程序员自己管理线程的生命周期(主要是创建)，我们在开发的过程中偶尔使用 NSThread。比如我们会经常调用 `[NSThread currentThread]` 来显示当前的进程信息。

```objc
//1、创建并启动线程
NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
[thread start];
//2、创建并自动启动线程
[NSThread detachNewThreadSelector:@selector(run) toTarget:self withObject:nil];
```

### 3、GCD
Grand Central Dispatch（GCD） 是 Apple 开发的一个多核编程的较新的解决方法。它主要用于优化应用程序以支持多核处理器以及其他对称多处理系统。它是一个在线程池模式的基础上执行的并发任务。在 Mac OS X 10.6 雪豹中首次推出，也可在 iOS 4 及以上版本使用。

通过 GCD，开发者不用再直接跟线程打交道了，只需要向队列中添加代码块即可，GCD 在后端管理着一个线程池。GCD 不仅决定着你的代码块将在哪个线程被执行，它还根据可用的系统资源对这些线程进行管理。这样可以将开发者从线程管理的工作中解放出来，通过集中的管理线程，来缓解大量线程被创建的问题。

GCD 带来的另一个重要改变是，作为开发者可以将工作考虑为一个队列，而不是一堆线程，这种并行的抽象模型更容易掌握和使用。

#### GCD 实现的原理
GCD有一个底层线程池，这个池中存放的是一个个的线程。线程中的线程是可以重用的，当一段时间后这个线程没有被调用胡话，这个线程就会被销毁。注意：开多少条线程是由底层线程池决定的（线程建议控制再3~5条），池是系统自动来维护，不需要我们来维护。开发者可以创建自定义队列：串行或者并行队列。自定义队列非常强大，在自定义队列中被调度的所有 block 最终都将被放入到系统的全局队列中和线程池中。

![](https://github.com/loveway/iOS-Knowledge/blob/master/image/gcd-queues.png?raw=true)

#### GCD 的优点
1. GCD 可用于多核的并行运算
2. GCD 会自动利用更多的 CPU 内核（比如双核、四核）
3. GCD 会自动管理线程的生命周期（创建线程、调度任务、销毁线程）
4. 程序员只需要告诉 GCD 想要执行什么任务，不需要编写任何线程管理代码。

#### GCD 的任务和队列
##### 任务
任务就是你需要执行的代码，在 GCD 中就是 block 中的代码，它有两种执行方式：
* 同步执行
```objc
dispatch_sync(queue, ^{
    // 这里放同步执行任务代码
});
```
同步添加任务到指定的队列中，在添加的任务执行结束之前，会一直等待，直到队列里面的任务完成之后再继续执行。
只能在当前线程中执行任务，不具备开启新线程的能力。

* 异步执行
 ```objc
dispatch_async(queue, ^{
    // 这里放异步执行任务代码
});
```
异步添加任务到指定的队列中，它不会做任何等待，可以继续执行任务。
可以在新的线程中执行任务，具备开启新线程的能力。

##### 队列
这里的队列指执行任务的等待队列，即用来存放任务的队列。队列是一种特殊的线性表，采用 FIFO（先进先出）的原则，即新任务总是被插入到队列的末尾，而读取任务的时候总是从队列的头部开始读取。每读取一个任务，则从队列中释放一个任务。两种队列分别是
* 串行队列
```objc
dispatch_queue_t queue = dispatch_queue_create("com.mm.test", DISPATCH_QUEUE_SERIAL);
```
每次只有一个任务被执行。让任务一个接着一个地执行。（只开启一个线程，一个任务执行完毕后，再执行下一个任务）

* 并发队列
```objc
dispatch_queue_t queue = dispatch_queue_create("com.mm.test", DISPATCH_QUEUE_CONCURRENT);
```
可以让多个任务并发（同时）执行。（可以开启多个线程，并且同时执行任务）

##### 任务 + 队列

| 任务 | 串行队列(新建 concurrent) | 并发队列(新建 serial) | 主队列(main queue) | 全局并发队列(global queue) |
| :-------: |:-------:|:-------:|:-------:|:-------:|
| 同步(sync) | 没有开启新线程，串行执行任务（main thread）  | 没有开启新线程，串行执行任务（main thread）  | 死锁 | 没有开启新线程，串行执行任务（main thread |
| 异步(async) | 开启新线程（1条），串行执行任务 | 开启新线程，并发执行任务 | 没有开启新线程 | 开启新线程，并发执行任务 |

##### 死锁
一个简单的死锁
```objc
- (void)viewDidLoad {
    [super viewDidLoad];
    dispatch_sync(dispatch_get_main_queue(), ^{
        
    });
}
```
在主线程主队列添加一个同步任务导致死锁， 这是因为 **主队列中追加的同步任务** 和 **主线程本身的任务** 两者之间相互等待。

第二种死锁
```objc
dispatch_queue_t queue = dispatch_queue_create("mm", DISPATCH_QUEUE_SERIAL);
//task 1
dispatch_async(queue, ^{
    NSLog(@"1--%@", [NSThread currentThread]);
    //task 2
    dispatch_sync(queue, ^{
        NSLog(@"2--%@", [NSThread currentThread]);
    });
});
NSLog(@"3--%@", [NSThread currentThread]);
```
输出
```objc
2019-12-30 16:41:50.245060+0800 OC_test[7817:229850] 3--<NSThread: 0x6000032dbac0>{number = 1, name = main}
2019-12-30 16:41:50.245077+0800 OC_test[7817:229940] 1--<NSThread: 0x600003285180>{number = 6, name = (null)}
```
上面形成死锁，这是因为异步执行 *task1* 的时候在 queue 中添加了同步任务 *task2*，那么 *task2* 就得等到 *task1* 执行完毕才能执行，而由于 *task2* 又在 *task1* 中，所以 *task2* 执行完毕后 *task1* 才算执行完，两者互相等待形成了 **死锁**。

#####  GCD 的其他方法
###### 1、dispatch_barrier_async
我们有时需要异步执行两组操作，而且第一组操作执行完之后，才能开始执行第二组操作。这样我们就需要一个相当于 栅栏 一样的一个方法将两组异步执行的操作组给分割起来，当然这里的操作组里可以包含一个或多个任务。这就需要用到 `dispatch_barrier_async` 方法在两个操作组间形成栅栏。

`dispatch_barrier_async` 方法会等待前边追加到并发队列中的任务全部执行完毕之后，再将指定的任务追加到该异步队列中。然后在 `dispatch_barrier_async` 方法追加的任务执行完毕之后，异步队列才恢复为一般动作，接着追加任务到该异步队列并开始执行。

```objc
dispatch_queue_t queue = dispatch_queue_create("mm", DISPATCH_QUEUE_CONCURRENT);
dispatch_async(queue, ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"1--%@", [NSThread currentThread]);
});
dispatch_async(queue, ^{
    [NSThread sleepForTimeInterval:1];
    NSLog(@"2--%@", [NSThread currentThread]);
});
dispatch_async(queue, ^{
    NSLog(@"3--%@", [NSThread currentThread]);
});

dispatch_barrier_async(queue, ^{
    [NSThread sleepForTimeInterval:1];
    NSLog(@"barrier--%@", [NSThread currentThread]);
});

dispatch_async(queue, ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"4--%@", [NSThread currentThread]);
});
dispatch_async(queue, ^{
    [NSThread sleepForTimeInterval:1];
    NSLog(@"5--%@", [NSThread currentThread]);
});
```
输出
```objc
2019-12-30 16:54:32.012007+0800 OC_test[7862:236849] 3--<NSThread: 0x6000011c5f80>{number = 6, name = (null)}
2019-12-30 16:54:33.013276+0800 OC_test[7862:236858] 2--<NSThread: 0x6000011c1300>{number = 7, name = (null)}
2019-12-30 16:54:34.012280+0800 OC_test[7862:236850] 1--<NSThread: 0x6000011fd680>{number = 5, name = (null)}
2019-12-30 16:54:35.012732+0800 OC_test[7862:236850] barrier--<NSThread: 0x6000011fd680>{number = 5, name = (null)}
2019-12-30 16:54:36.013265+0800 OC_test[7862:236858] 5--<NSThread: 0x6000011c1300>{number = 7, name = (null)}
2019-12-30 16:54:37.013311+0800 OC_test[7862:236850] 4--<NSThread: 0x6000011fd680>{number = 5, name = (null)}
```
###### 2、dispatch_after
我们经常会遇到这样的需求：在指定时间（例如 3 秒）之后执行某个任务。可以用 GCD 的`dispatch_after` 方法来实现。

需要注意的是：`dispatch_after` 方法并不是在指定时间之后才开始执行处理，而是在指定时间之后将任务追加到主队列中。

```objc
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    // 2.0 秒后异步追加任务代码到主队列，并开始执行
    NSLog(@"after---%@",[NSThread currentThread]);
});
```

###### 3、dispatch_once
我们在创建单例、或者有整个程序运行过程中只执行一次的代码时，我们就用到了 GCD 的 dispatch_once 方法。使用 dispatch_once 方法能保证某段代码在程序运行过程中只被执行 1 次，并且即使在多线程的环境下，dispatch_once 也可以保证线程安全。

```objc
- (void)once {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 只执行 1 次的代码（这里面默认是线程安全的）
    });
}
```
`dispatch_once` 用原子性操作 block 执行完成标记位，同时用信号量确保只有一个线程执行 block，等 block 执行完再唤醒所有等待中的线程。
关于 `dispatch_once` 的原理可以参考 [深入浅出 GCD 之 dispatch_once](https://xiaozhuanlan.com/topic/7916538240) 。

![](https://github.com/loveway/iOS-Knowledge/blob/master/image/dispatch_once.png?raw=true)

###### 4、dispatch_apply
通常我们会用 for 循环遍历，但是 GCD 给我们提供了快速迭代的方法 `dispatch_apply`。`dispatch_apply` 按照指定的次数将指定的任务追加到指定的队列中，并等待全部队列执行结束。

如果是在串行队列中使用 `dispatch_apply`，那么就和 for 循环一样，按顺序同步执行。但是这样就体现不出快速迭代的意义了。

我们可以利用并发队列进行异步执行。比如说遍历 0~5 这 6 个数字，for 循环的做法是每次取出一个元素，逐个遍历。`dispatch_apply` 可以 在多个线程中同时（异步）遍历多个数字。

还有一点，无论是在串行队列，还是并发队列中，`dispatch_apply` 都会等待全部任务执行完毕，这点就像是同步操作，也像是队列组中的 `dispatch_group_wait` 方法。

```objc
dispatch_queue_t queue = dispatch_queue_create("mm", DISPATCH_QUEUE_CONCURRENT);
NSLog(@"begin--%@", [NSThread currentThread]);
    
dispatch_apply(6, queue, ^(size_t index) {
    NSLog(@"%zu--%@", index, [NSThread currentThread]);
});
    
NSLog(@"end--%@", [NSThread currentThread]);
```

输出

```objc
2019-12-30 17:25:35.671037+0800 OC_test[8222:256731] begin--<NSThread: 0x600002b78e00>{number = 1, name = main}
2019-12-30 17:25:35.671298+0800 OC_test[8222:256731] 0--<NSThread: 0x600002b78e00>{number = 1, name = main}
2019-12-30 17:25:35.671398+0800 OC_test[8222:256810] 1--<NSThread: 0x600002b22d00>{number = 3, name = (null)}
2019-12-30 17:25:35.671562+0800 OC_test[8222:256810] 2--<NSThread: 0x600002b22d00>{number = 3, name = (null)}
2019-12-30 17:25:35.671588+0800 OC_test[8222:256731] 3--<NSThread: 0x600002b78e00>{number = 1, name = main}
2019-12-30 17:25:35.671694+0800 OC_test[8222:256810] 4--<NSThread: 0x600002b22d00>{number = 3, name = (null)}
2019-12-30 17:25:35.671707+0800 OC_test[8222:256731] 5--<NSThread: 0x600002b78e00>{number = 1, name = main}
2019-12-30 17:25:35.671866+0800 OC_test[8222:256731] end--<NSThread: 0x600002b78e00>{number = 1, name = main}
```

因为是在并发队列中异步执行任务，所以各个任务的执行时间长短不定，最后结束顺序也不定。但是 `apply---end` 一定在最后执行。这是因为 `dispatch_apply` 方法会等待全部任务执行完毕。

###### 5、dispatch_group
有时候我们会有这样的需求：分别异步执行 2 个耗时任务，然后当 2 个耗时任务都执行完毕后再回到主线程执行任务。这时候我们可以用到 GCD 的队列组。
* 调用队列组的 `dispatch_group_async` 先把任务放到队列中，然后将队列放入队列组中。或者使用队列组的 `dispatch_group_enter`、`dispatch_group_leave` 组合来实现 `dispatch_group_async`。
* 调用队列组的 dispatch_group_notify 回到指定线程执行任务。或者使用 dispatch_group_wait 回到当前线程继续向下执行（会阻塞当前线程）

```objc
dispatch_queue_t queue = dispatch_queue_create("mm", DISPATCH_QUEUE_CONCURRENT);
dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
dispatch_group_t group = dispatch_group_create();
NSLog(@"begin--%@", [NSThread currentThread]);
dispatch_group_async(group, queue, ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"1--%@", [NSThread currentThread]);
});
dispatch_group_async(group, globalQueue, ^{
    [NSThread sleepForTimeInterval:1];
    NSLog(@"2--%@", [NSThread currentThread]);
});
    
dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    [NSThread sleepForTimeInterval:1];
    NSLog(@"3--%@", [NSThread currentThread]);
    NSLog(@"group end");
});
NSLog(@"end--%@", [NSThread currentThread]);
```

输出

```objc
2019-12-30 17:39:50.279018+0800 OC_test[8316:265481] begin--<NSThread: 0x600001c28c40>{number = 1, name = main}
2019-12-30 17:39:50.279317+0800 OC_test[8316:265481] end--<NSThread: 0x600001c28c40>{number = 1, name = main}
2019-12-30 17:39:51.280501+0800 OC_test[8316:265569] 2--<NSThread: 0x600001c1a740>{number = 5, name = (null)}
2019-12-30 17:39:52.283147+0800 OC_test[8316:265574] 1--<NSThread: 0x600001c6f600>{number = 3, name = (null)}
2019-12-30 17:39:53.284526+0800 OC_test[8316:265481] 3--<NSThread: 0x600001c28c40>{number = 1, name = main}
2019-12-30 17:39:53.284892+0800 OC_test[8316:265481] group end
```

`dispatch_group` 有两个需要注意的地方：
> 1、`dispatch_group_enter` 必须在 `dispatch_group_leave` 之前出现
> 2、`dispatch_group_enter` 和 `dispatch_group_leave` 必须成对出现,
> 3、如果 `dispatch_group_enter` 比 `dispatch_group_leave` 多一次，则 wait 函数等待的线程不会被唤醒和注册 notify 的回调 block 不会执行；
> 4、如果 `dispatch_group_leave` 比 `dispatch_group_enter` 多一次，则会引起崩溃。

###### 6、dispatch_semaphore

GCD 中的信号量是指 Dispatch Semaphore，是持有计数的信号。类似于过高速路收费站的栏杆。可以通过时，打开栏杆，不可以通过时，关闭栏杆。在 Dispatch Semaphore 中，使用计数来完成这个功能，计数小于 0 时等待，不可通过。计数为 0 或大于 0 时，计数减 1 且不等待，可通过。

作用主要是 **保持线程同步** 和 **给线程加锁** 。

* `dispatch_semaphore_create` 可以生成信号量，参数 value 是信号量计数的初始值
* `dispatch_semaphore_wait` 会让信号量值减一，当信号量值为 0 时会等待(直到超时)，否则正常执行
* `dispatch_semaphore_signal` 会让信号量值加一，如果有通
* `dispatch_semaphore_wait` 函数等待 Dispatch Semaphore 的计数值增加的线程，会由系统唤醒最先等待的线程执行。

```objc
dispatch_queue_t queue = dispatch_queue_create("mm", DISPATCH_QUEUE_CONCURRENT);
dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
NSLog(@"1");
dispatch_async(queue, ^{
    NSLog(@"2");
    [NSThread sleepForTimeInterval:3];
    dispatch_semaphore_signal(semaphore);
});
NSLog(@"3");
dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
NSLog(@"4");
```

输出

```objc
2019-12-31 10:24:36.497961+0800 OC_test[12447:634185] 1
2019-12-31 10:24:36.498180+0800 OC_test[12447:634185] 3
2019-12-31 10:24:36.498205+0800 OC_test[12447:634262] 2
2019-12-31 10:24:39.501758+0800 OC_test[12447:634185] 4
```

上面代码中：当执行到 `dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)` 的时候发现 semaphore 的值为 0 ，所以线程会一直阻塞，直到异步执行到 `dispatch_semaphore_signal(semaphore)` 的时候 semaphore 的值为 1，此时再执行 `dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)` 使信号量 -1 然后往下执行。

我们再来看下面这段代码

```objc
dispatch_queue_t queue = dispatch_queue_create("mm", DISPATCH_QUEUE_CONCURRENT);
dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
__block int obj = 0;
for (int i = 0; i < 10; i++) {
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        obj += i;
        dispatch_semaphore_signal(semaphore);
        NSLog(@" i = %d, obj = %d", i , obj);
    });
}
NSLog(@"main thread");
```

输出

```objc
2019-12-31 10:43:35.424219+0800 OC_test[12719:651260] main thread
2019-12-31 10:43:35.424243+0800 OC_test[12719:651403]  i = 0, obj = 0
2019-12-31 10:43:35.424291+0800 OC_test[12719:651404]  i = 2, obj = 2
2019-12-31 10:43:35.424300+0800 OC_test[12719:651402]  i = 1, obj = 3
2019-12-31 10:43:35.424408+0800 OC_test[12719:651413]  i = 3, obj = 6
2019-12-31 10:43:35.424480+0800 OC_test[12719:651414]  i = 4, obj = 10
2019-12-31 10:43:35.424610+0800 OC_test[12719:651404]  i = 6, obj = 21
2019-12-31 10:43:35.424608+0800 OC_test[12719:651403]  i = 5, obj = 15
2019-12-31 10:43:35.424718+0800 OC_test[12719:651415]  i = 7, obj = 28
2019-12-31 10:43:35.424788+0800 OC_test[12719:651414]  i = 8, obj = 36
2019-12-31 10:43:35.424796+0800 OC_test[12719:651413]  i = 9, obj = 45
```

可以看到 obj 到最后最大的值为 45，其实上面 for 循环主要就是求 0-9 的和，我们可以看到虽然异步 i = 2 比 i = 1 先执行，但是并不影响最终结果，所以是线程安全的。原理就是当 *线程1* 执行到 `dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)` 时，semaphor e的信号量为 1，所以使信号量 -1 变为 0，并且 *线程1* 继续往下执行；如果当在 *线程1* `obj += i` 这一行代码还没执行完的时候，又有 *线程2* 来访问，此时 semaphore 信号量为 0，`dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)` 会一直阻塞 *线程2* 直到 *线程1* 执行完毕（此时 *线程2* 处于等待状态）。

 需要注意的是下面代码会使程序崩溃
 
```objc
dispatch_semaphore_t semephore = dispatch_semaphore_create(1);
dispatch_semaphore_wait(semephore, DISPATCH_TIME_FOREVER);
//重新赋值或者将semephore = nil都会造成崩溃,因为此时信号量还在使用中
 semephore = dispatch_semaphore_create(0);
```
 


## 四、iOS 线程间通信
| name | method |
| :------- |:-------|
| NSObject | `- (void)performSelectorOnMainThread:(SEL)aSelector withObject:(nullable id)arg waitUntilDone:(BOOL)wait`<br><br>`- (void)performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(nullable id)arg waitUntilDone:(BOOL)wait` |
| GCD | `dispatch_async(dispatch_get_global_queue())`<br><br> `dispatch_sync(dispatch_get_main_queue())` |
| NSOperation | `[NSOperationQueue mainQueue]`回到主线程 |

##### NSObject 线程通信
```objc
- (void)viewDidLoad {
    [super viewDidLoad];
    [NSThread detachNewThreadSelector:@selector(run) toTarget:self withObject:nil];
}

- (void)notify:(NSDictionary *)dic {
    NSLog(@"%@",dic[@"name"]);
    NSLog(@"2-%@", [NSThread currentThread]);
}

- (void)run {
    NSLog(@"1-%@", [NSThread currentThread]);
    [self performSelectorOnMainThread:@selector(notify:) withObject:@{@"name": @"mm"} waitUntilDone:YES];
}
```
输出
```objc
2019-12-27 15:04:46.408512+0800 OC_test[96466:2477652] 1-<NSThread: 0x600002d00d80>{number = 7, name = (null)}
2019-12-27 15:04:46.499677+0800 OC_test[96466:2477545] mm
2019-12-27 15:04:46.508057+0800 OC_test[96466:2477545] 2-<NSThread: 0x600002d57940>{number = 1, name = main}
```

##### GCD 线程通信
```objc
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"--%@", [NSThread currentThread]);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"--%@", [NSThread currentThread]);
        });
});
```
输出
```objc
2019-12-27 15:16:12.636018+0800 OC_test[96557:2485944] --<NSThread: 0x6000000032c0>{number = 6, name = (null)}
2019-12-27 15:16:12.654791+0800 OC_test[96557:2485861] --<NSThread: 0x600000068d40>{number = 1, name = main}
```
##### NSOperation 线程通信

```objc
NSOperationQueue *queue = [[NSOperationQueue alloc] init];
[queue addOperationWithBlock:^{
    NSLog(@"--%@", [NSThread currentThread]);
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSLog(@"--%@", [NSThread currentThread]);
    }];
}];
```
输出
```objc
2019-12-27 15:25:28.723604+0800 OC_test[96620:2492092] --<NSThread: 0x600002db9f40>{number = 4, name = (null)}
2019-12-27 15:25:28.745156+0800 OC_test[96620:2491999] --<NSThread: 0x600002de6d00>{number = 1, name = main}
```

## 五、iOS 进程间通信
进程是容纳运行一个程序所需要所有信息的容器。在 iOS 中每个 APP 里就一个进程，所以进程间的通信实际上是 APP 之间的通信。iOS 是封闭的系统，每个 APP 都只能访问各自沙盒里的内容。

1. URL Scheme（openURL跳转白名单的 scheme）
2. Keychain（安全、独立于每个App的沙盒之外的，所以即使App被删除之后，Keychain里面的信息依然存在）
3. UIPasteboard（每一个App都可以去访问系统剪切板，所以就能够通过系统剪贴板进行App间的数据传输）
4. UIDocumentInteractionController（用来实现同设备上app之间的共享文档，以及文档预览、打印、发邮件和复制等功能）
5. local socket




Reference:
> [并发与并行的区别？](https://www.zhihu.com/question/33515481)
> 
> [并发编程：API 及挑战](https://objccn.io/issue-2-1/)
> 
> [NSThread](https://developer.apple.com/documentation/foundation/nsthread)
> 
> [进程/线程间通信](http://www.helloted.com/ios/2017/10/20/thread_message/)
> 
> [底层并发 API](https://objccn.io/issue-2-3/)
> 
> [iOS多线程：『GCD』详尽总结](https://juejin.im/post/5a90de68f265da4e9b592b40)
> 
> [陈爱彬小专栏](https://xiaozhuanlan.com/u/3785694919)
