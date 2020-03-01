# iOS 中的 KVO

## 一、KVO 的定义
KVO，也就是 Key-Value Observing，字面意思也就是键-值观察。在苹果的官方文档里面，对于 KVO 的介绍，我们可以看到下面这段话
```objc
Automatic key-value observing is implemented using a technique called isa-swizzling.

The isa pointer, as the name suggests, points to the object's class which maintains a dispatch table. This dispatch table essentially contains pointers to the methods the class implements, among other data.

When an observer is registered for an attribute of an object the isa pointer of the observed object is modified, pointing to an intermediate class rather than at the true class. As a result the value of the isa pointer does not necessarily reflect the actual class of the instance.

You should never rely on the isa pointer to determine class membership. Instead, you should use the class method to determine the class of an object instance.
``` 
我们可以看到 KVO 的实现使用 isa-swizzling 这个技术实现的，那么说明底层的实现是使用 runtime，后面我们在分析原理的时候会详细讲解这一部分。

## 二、KVO 的使用

### 1、基本使用
对于 KVO 的基本使用，一本如下
```objc
@interface Person : NSObject

@property (nonatomic, copy) NSString *name;

@end

...

- (void)viewDidLoad {
    
    _p = [[Person alloc] init];
    
    [_p addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@", change);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    _p.name = @"mm";
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"name"];
}
```

如上，我们有一个 Person 类，里面有一个 name 属性，我们在 VC 里面创建 Person 对象并且添加观察，然后在 `- (void)dealloc` 的时候再移除这个观察，点击屏幕改变 name，打印如下
```objc
2020-03-01 18:14:14.951348+0800 OC_test[5259:331033] {
    kind = 1;
    new = mm;
}
```

可以看到我们观察到了 name 属性的变化，需要注意的是我们在 dealloc 的时候需要移除这个观察，有几个就移除几个，如果我有一个观察，在 dealloc 时候移除两次，那么就会造成崩溃。

如上面例子中的 self 对 p 这个对象是强引用（strong），那么给 p 添加观察者 self，p 对 self 就不是强引用了（强引用了不就造成循环引用了嘛，苹果这么聪明肯定不会这么设计的），所以在 self 消失的时候（dealloc）我们需要将自己从 p 的观察者中移除掉。否则就会造成 p 继续向 self 的 `observeValueForKeyPath: ofObject: change:context:` 方法发送消息，而 self 已经释放了，造成 crash。

对于 `addObserver: forKeyPath:options: context:` 这个方法中的 `options` 这个选项我们可以看到四个枚举值，设置不同的 options 监听到的结果都不同，具体如下
```objc
typedef NS_OPTIONS(NSUInteger, NSKeyValueObservingOptions) {
    //接受新值，收到监听后 change 里面会有一个 new
    NSKeyValueObservingOptionNew
    //接收旧值，收到监听后 change 里面会有一个 old
    NSKeyValueObservingOptionOld
    //在添加监听的时候（也就是调用 `addObserver: forKeyPath:options: context:` 这个方法时会接收到一次回调），在值改变时也会接收到回调
    NSKeyValueObservingOptionInitial 
    //在值改变之前和之后都会收到回调，也就是改变值之后会收到两次回调
    NSKeyValueObservingOptionPrior 
};
```

### 2、触发方式


Reference：
> [Key-Value Observing Implementation Details](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOImplementation.html)