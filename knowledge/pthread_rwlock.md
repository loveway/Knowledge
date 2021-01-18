# iOS 中的读写锁 pthread_rwlock

这个锁一般用来属性的读写，主要由以下几个特点
* 可以多个线程同时进行读操作
* 同时只允许一个线程进行写操作
* 读和写互斥（读的时候不能进行写操作，写的时候不能进行读操作）

我们针对这个需求，就可以使用读写锁 pthread_rwlock，如下
```objc
#import "ViewController.h"
#import <pthread/pthread.h>

@interface ViewController ()

@property (nonatomic, assign) pthread_rwlock_t rwlock;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    pthread_rwlock_init(&_rwlock, NULL);
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    for (int i = 0; i < 10; i++) {
        dispatch_async(queue, ^{
            NSLog(@"——--%@", [NSThread currentThread]);
            [self read];
        });
        dispatch_async(queue, ^{
            NSLog(@"——--%@", [NSThread currentThread]);
            [self write];
        });
    }
}

- (void)write {
    pthread_rwlock_wrlock(&_rwlock);
    sleep(1);
    NSLog(@"%s", __func__);
    pthread_rwlock_unlock(&_rwlock);
}

- (void)read {
    pthread_rwlock_rdlock(&_rwlock);
    sleep(1);
    NSLog(@"%s", __func__);
    pthread_rwlock_unlock(&_rwlock);
}

- (void)dealloc {
    pthread_rwlock_destroy(&_rwlock);
}

@end
```
最后测试结果如下

![](https://github.com/loveway/Knowledge/blob/master/image/pthread_rwlock.png?raw=true)

我们可以看到，只会出现同时读的情况，不会出现同时写的情况。
