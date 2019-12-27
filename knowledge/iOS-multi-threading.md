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

###GCD 和 NSOperation 有什么区别

1. GCD 是纯 C 语言的 API；NSOperation 是基于 GCD 的 OC 版本封装
2. GCD 只支持 FIFO 的队列；NSOperation 可以很方便地调整执行顺序，设置最大并发数量
3. NSOperationQueue 可以轻松在 operation 间设置依赖关系，而 GCD 需要些很多代码才能实现
4. NSOperationQueue 支持 KVO，可以检测 operation 是否正在执行(isExecuted)，是否结束(isFinish), 是否取消(isCancel)
5. GCD 的执行速度比 NSOperation 快

GCD 是比较底层的封装，我们知道较低层的代码一般性能都是比较高的，相对于NSOperationQueue。所以追求性能，而功能够用的话就可以考虑使用GCD。如果异步操作的过程需要更多的用户交互和被UI显示出来，NSOperationQueue 会是一个好选择。如果任务之间没有什么依赖关系，而是需要更高的并发能力，GCD 则更有优势。

## pthread
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

## NSThread
NSThread 是苹果官方提供的，使用起来比 pthread 更加面向对象，简单易用，可以直接操作线程对象。不过也需要需要程序员自己管理线程的生命周期(主要是创建)，我们在开发的过程中偶尔使用 NSThread。比如我们会经常调用 `[NSThread currentThread]` 来显示当前的进程信息。

```objc
//1、创建并启动线程
NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
[thread start];
//2、创建并自动启动线程
[NSThread detachNewThreadSelector:@selector(run) toTarget:self withObject:nil];
```

## iOS 线程间通信
| thread | method |
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
        dispatch_sync(dispatch_get_main_queue(), ^{
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

Reference:
> [并发与并行的区别？](https://www.zhihu.com/question/33515481)
> 
> [并发编程：API 及挑战](https://objccn.io/issue-2-1/)
> 
> [NSThread](https://developer.apple.com/documentation/foundation/nsthread)
> 
> [进程/线程间通信](http://www.helloted.com/ios/2017/10/20/thread_message/)