# iOS 的多线程的问题解答
## Q1、如何终止正在运行的工作线程？

##### 1. 还未执行的线程 
iOS 8 以后，通过 `dispatch_block_cancel` 可以 cancel 掉`dispatch_block_t`，需要注意的是，未执行的可以用此方法 cancel 掉，若已经执行则cancel 不掉；

如果想中断（interrupt）线程，可以使用 `dispatch_block_testcancel` 方法；

值得注意的是，swift3 之后 `DispatchWorkItem` 代替了 `dispatch_block_t` ，有很方便的 `cancel()` 和`isCancelled` 可以使用。

##### 2. 已经执行的线程 
GCD 本身是没有提供这样的 API 的。想要实现这样的功能需要自己在代码里实现：可用 return 方法
```objc
__block BOOL cancel = NO;
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    for (int i = 0; i < 10; i++) {
        NSLog(@"Run i is %d", i);
        sleep(1);
        //加上 self 防止退出 VC 闪退
        if (cancel && self) {
            NSLog(@"Stop now !");
            return;
        }
    }
});
    
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    
    NSLog(@"Will stop !");
    cancel = YES;
});
```

输出

```objc
2020-01-02 15:11:55.031730+0800 OC_test[12598:177074] Run i is 0
2020-01-02 15:11:56.035140+0800 OC_test[12598:177074] Run i is 1
2020-01-02 15:11:57.040171+0800 OC_test[12598:177074] Run i is 2
2020-01-02 15:11:58.031923+0800 OC_test[12598:176922] Will stop !
2020-01-02 15:11:58.045648+0800 OC_test[12598:177074] Stop now !
```

pthread 的 话 pthread_exit、pthread_kill、pthread_cance 都有取消的功能。
NSOperationQueue 可以调用 cancel 方法。

Reference:
> [iOS的GCD中如何关闭或者杀死一个还没执行完的后台线程?](https://www.zhihu.com/question/23919984)


## Q2、iOS 下如何实现指定线程数目的线程池？

1.循环通过 pthread_create 创建线程，创建 s_tfthread 对象做为线程句，加入线程数组, s_tftask_content->methord 初始化为空函数

2.创建任务执行函数，执行完通过task初始化函数后，在执行函数中通过 pthread_cond_wait 信号将当前创建的线程挂起

3.创建完之后，程序中将会有n个挂起状态的线程，当需要执行新的 task 的时候查找，我们就可以根据不同的 task 标志在 k_threads 中查询出空闲线程，并创建新的s_tftask_content 加入 s_tfthread 的任务列表，通过 pthread_cond_signal 重新唤醒该线程继续执行任务