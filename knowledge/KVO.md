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

KVO 默认的是自动触发的，但是有时候我们改变了对象的一个值，并不想收到通知，那么该怎么办呢？我们可以在 `NSObject(NSKeyValueObservingCustomization)` 里面看到 `+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key` 这个方法，这个方法默认返回为 YES，也就是自动触发 KVO，我们可以在子类中重写这个方法，如下

```objc
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    return NO;
}
```

当我们在我们之前的 Person 类中重写了这个方法以后，重新运行项目点击屏幕，发现没有接收到值改变的信息，这是因为因为我们把触发模式改成了手动触发。如果 `automaticallyNotifiesObserversForKey` 设置为 NO，此刻仍然想收到通知，我们只有手动触发了，代码如下
```objc
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [_p willChangeValueForKey:@"name"];
    _p.name = @"mm";
    [_p didChangeValueForKey:@"name"];
}
```

这样我们点击屏幕就可以重新收到消息了。下面我们来思考一个问题，我们把 `_p.name = @"mm";` 这行代码去掉，点击屏幕还会不会触发 KVO？如下

```objc
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [_p willChangeValueForKey:@"name"];
//    _p.name = @"mm";
    [_p didChangeValueForKey:@"name"];
}
```

测试以后我们发现仍然会收到通知，这说明 KVO 的触发与属性有没有赋值没有关系，与 `willChangeValueForKey` 和 `didChangeValueForKey` 这两个方法的调用有关系。
不过我们手动触发的时候一般不直接全部返回 NO，我们一般自己过滤一下，如下

```objc
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    
    if ([key isEqualToString:@"name"]) {
        return NO;
    }
    return YES;
}
```

### 3、属性依赖

现在我们新建一个 Man 类，里面有 age、address 两个属性，然后在 Person 里面创建一个 man 属性，如下
```objc
@interface Person : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) Man *man;

@end

...

@interface Man : NSObject

@property (nonatomic, assign) NSInteger age;
@property (nonatomic, copy) NSString *address;

@end
```

我们重写 Person 的 `init` 方法

```objc
- (instancetype)init {
    if (self == [super init]) {
        _man = [[Man alloc] init];
    }
    return self;
}
```

如果我想观察 person 的 man 的 age 属性，如下

```objc
[_p addObserver:self forKeyPath:@"man.age" options:NSKeyValueObservingOptionNew context:nil];
```

如果我想同时观察 age 和 address 属性呢，那么我就这样

```objc
[_p addObserver:self forKeyPath:@"man.age" options:NSKeyValueObservingOptionNew context:nil];
[_p addObserver:self forKeyPath:@"man.address" options:NSKeyValueObservingOptionNew context:nil];
```

那么有的童鞋就有疑问了，如果同时观察多了属性，这样写是不是就很不优雅，有没有一种简洁优雅的写法可以同时观察多个属性，答案是有的，如下

```objc
+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPath = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"man"]) {
        keyPath = [NSSet setWithObjects:@"_man.age", @"_man.address", nil];
    }
    return keyPath;
}
```

或

```objc
+ (NSSet<NSString *> *)keyPathsForValuesAffectingMan {
    return [NSSet setWithObjects:@"_man.age", @"_man.address", nil];
}
```

只监听 man 属性就可以收到 age 和 address 的改变值，结果如下

上面这两种方式都可以实现只观察 man 属性，就可以监听到 age 和 address 的变化，这就是属性依赖，如果 Person 还有有 name 和 firstName、lastName 三个属性，想 name 改变就监听到 firstName、lastName 改变，可以如下

```objc
+ (NSSet<NSString *> *)keyPathsForValuesAffectingName {
    return [NSSet setWithObjects:@"firstName", @"lastName", nil];
}
```

或

```objc
+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPath = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"name"]) {
        keyPath = [keyPath setByAddingObjectsFromArray:@[@"firstName", @"lastName"]];
    }
    return keyPath;
}
```

## 三、KVO 的原理

为了探究 KVO 的原理,我们来做一个实验，我们在添加监听的时候打个断点，如下

![kvo-break-point](https://github.com/loveway/iOS-Knowledge/blob/master/image/kvo-break-point.png?raw=true)

此时我们去打印一下 _p 的 isa 指针，然后进行下一步，在打印 isa，会发现如下

![kvo-isa-change](https://github.com/loveway/iOS-Knowledge/blob/master/image/kvo-isa-change.png?raw=true)

我们发现在给 p 对象添加监听以后，其 isa 指针发生了变化，由原来指向的 Person 变成了 NSKVONotifying_Person，那么这个 NSKVONotifying_Person 又是个东西呢？为什么会发生这种变化？

**这是因为在给 p 对象添加监听以后，runtime 会动态的创建一个叫 NSKVONotifying_Person 的类，该类继承于 Person，此时将 _p 的 isa 指针改变指向 NSKVONotifying_Person，然后调用 NSKVONotifying_Person 中重写的 `setName:` 方法，`setName:` 方法调用 Foundation 框架的 `_NSSetObjectValueAndNotify` 方法，然后 `_NSSetObjectValueAndNotify` 方法内部的实现是依次调用 `willChangeValueForKey`、父类的 `setName:` 方法、`didChangeValueForKey` 方法，最后调用 `observeValueForKeyPath:ofObject:change:context:` 方法完成通知流程，这就是 KVO 的原理**,流程大致如下

```objc
#import "NSKVONotifying_Person.h"

...

//isa 指向 NSKVONotifying_Person，调用子类 NSKVONotifying_Person 的 setter 方法
- (void)setName:(NSString *)name {
    // setter 方法调用 Foundation 的 c 函数，设置的值不同调用的函数不同，比如还有 _NSSetBoolValueAndNotify、_NSSetFloatValueAndNotify 等（可以找到 Foundation 用 nm Foundation | grep ValueAndNotify 命令查看）
    _NSSetObjectValueAndNotify();
}

void _NSSetObjectValueAndNotify() {
    //依次调用
    [self willChangeValueForKey:@"name"];
    //这儿调用父类的 setter 方法
    [super setName:name];
    [self didChangeValueForKey:@"name"];
}

- (void)didChangeValueForKey:(NSString *)key {
    //通知观察者属性改变
    [observer observeValueForKeyPath:key ofObject:self change:nil context:nil];
}
```

通过打印消息，我们可以简单验证一下

![kvo-fundation-imp](https://github.com/loveway/iOS-Knowledge/blob/master/image/kvo-fundation-imp.png?raw=true)

需要注意的是如果我们创建了 NSKVONotifying_Person 这个子类，然后再去添加监听，会出现以下错误

```objc
2020-03-02 16:15:50.328074+0800 OC_test[16550:163923] [general] KVO failed to allocate class pair for name NSKVONotifying_Person, automatic key-value observing will not work for this class
```

说是 KVO 创建 NSKVONotifying_Person 失败，KVO 不会生效（记得之前都是crash，然后说已存在 NSKVONotifying_Person 这个类，估计现在改进了）。

## 四、如何手动实现 KVO






Reference：
> [Key-Value Observing Implementation Details](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOImplementation.html)
> 
> [class_addMethod](https://developer.apple.com/documentation/objectivec/1418901-class_addmethod?language=objc)
> 
> [Objective-C Runtime Programming Guide：Type Encodings
](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100)
>
> [iOS底层原理总结 - 探寻KVO本质](https://juejin.im/post/5adab70cf265da0b736d37a8)
