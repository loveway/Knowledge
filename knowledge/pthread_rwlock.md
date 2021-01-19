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

![](https://github.com/loveway/Knowledge/blob/master/image/pthread_rwlock_1.png?raw=true)

我们可以看到，只会出现同时读的情况，不会出现同时写的情况。

### 思考：如果对一个对象的属性进行上述操作，该如何写它的 set、get 方法

#### 1、使用读写锁 pthread_rwlock
```objc
#import "MMPerson.h"
#import <pthread/pthread.h>

@interface MMPerson ()

@property (nonatomic, assign) pthread_rwlock_t rwlock;

@end

static NSString *_name;
@implementation MMPerson

- (instancetype)init {
    if (self = [super init]) {
        pthread_rwlock_init(&_rwlock, NULL);
    }
    return self;
}

- (void)setName:(NSString *)name {
    pthread_rwlock_wrlock(&_rwlock);
    sleep(1);
    _name = [name copy];
    NSLog(@"write name");
    pthread_rwlock_unlock(&_rwlock);
}

- (NSString *)name {
    NSString *tmpName;
    pthread_rwlock_rdlock(&_rwlock);
    sleep(1);
    tmpName = _name;
    NSLog(@"read name");
    pthread_rwlock_unlock(&_rwlock);
    return tmpName;
}

- (void)dealloc {
    pthread_rwlock_destroy(&_rwlock);
}
```
验证代码如下
```objc
dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
for (int i = 0; i < 5; i++) {
    dispatch_async(queue, ^{
        p.name = @"122";
    });
    dispatch_async(queue, ^{
        p.name = @"122";
    });
    dispatch_async(queue, ^{
        NSString *tmp = p.name;
    });
    dispatch_async(queue, ^{
        NSString *tmp = p.name;
    });
}
```
验证结果如下

![](https://github.com/loveway/Knowledge/blob/master/image/pthread_rwlock_2.png?raw=true)



#### 2、使用栅栏函数 dispatch_barrier_async
实现同样的效果，我们也可以使用 dispatch_barrier_async
```objc
#import "MMPerson.h"

@interface MMPerson ()

@property (nonatomic, strong) dispatch_queue_t queue;

@end

static NSString *_name;
@implementation MMPerson

- (instancetype)init {
    if (self = [super init]) {
        // 使用栅栏函数时候这个 queue 必须是自己手动创建的，不能使系统的全局队列或者主队列（能拦住全局队列那岂不是太牛了）
        _queue = dispatch_queue_create("mm_queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)setName:(NSString *)name {
    dispatch_barrier_async(_queue, ^{
        sleep(1);
        _name = [name copy];
        NSLog(@"write name");
    });
}

- (NSString *)name {
    __block NSString *tmpName;
    dispatch_sync(_queue, ^{
        sleep(1);
        tmpName = _name;
    });
    NSLog(@"read name");
    return tmpName;
}
@end
```
简单定义一个 MMPerson 类，然后対它的 name 属性做读写操作，测试代码如下
```objc
MMPerson *p = [[MMPerson alloc] init];
dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
for (int i = 0; i < 10; i++) {
    dispatch_async(queue, ^{
        p.name = @"122";
    });
    dispatch_async(queue, ^{
        NSString *tmp = p.name;
    });
}
```
测试结果如下

![](https://github.com/loveway/Knowledge/blob/master/image/pthread_rwlock_3.png?raw=true)


我们可以看到，达到了多读单写、读写互斥的目的。
