# iOS 事件机制
iOS 常见的事件分为以下几类
* **Touch Events （触摸事件）**
* **Motion Events (运动事件，比如重力感应和摇一摇等）**
* **Remote Events （远程事件，比如用耳机上得按键来控制手机）**

这里我们主要来说一说 **Touch Events**，一说到事件的传递我们肯定就会说到响应链，无论哪种事件的传递都与响应链息息相关。下面我们来围绕几个问题一步步了解事件的传递机制
## 一、响应链是怎么构造的
我们常见的 UIView、UIViewController 以及 UIApplication 都是继承与 UIResponder 的，UIResponder 类如下
```objc
UIKIT_EXTERN API_AVAILABLE(ios(2.0)) @interface UIResponder : NSObject <UIResponderStandardEditActions>

@property(nonatomic, readonly, nullable) UIResponder *nextResponder;

@property(nonatomic, readonly) BOOL canBecomeFirstResponder;    // default is NO
- (BOOL)becomeFirstResponder;

@property(nonatomic, readonly) BOOL canResignFirstResponder;    // default is YES
- (BOOL)resignFirstResponder;

@property(nonatomic, readonly) BOOL isFirstResponder;

// Generally, all responders which do custom touch handling should override all four of these methods.
// Your responder will receive either touchesEnded:withEvent: or touchesCancelled:withEvent: for each
// touch it is handling (those touches it received in touchesBegan:withEvent:).
// *** You must handle cancelled touches to ensure correct behavior in your application.  Failure to
// do so is very likely to lead to incorrect behavior or crashes.
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesEstimatedPropertiesUpdated:(NSSet<UITouch *> *)touches API_AVAILABLE(ios(9.1));

```

我们可以看到有一个 `nextResponder` 这个属性，那就说明继承与 UIResponder 的 UIView、UIViewController 以及 UIApplication 都会有这个属性。UIResponder 是所有响应类的基类，响应链的构建和 UIResponder 是密不可分的。

实际上我们 APP 的视图的构建是树状层次结构构建起来的，每一个视图（view）都会有它的父视图（superView），当一个 view 被添加到它的 superView 上面的时候，这个 view 的 nextResponder 就会指向它的 superView，当一个 viewController 被创建的时候，它的视图（self.view）的 nextResponder 会指向这个 viewController，viewController 的 nextResponder 会指向它视图（self.view）的父视图 (UIWindow)，最后指向 UIApplication。



Reference:
> [深入浅出iOS事件机制](https://zhoon.github.io/ios/2015/04/12/ios-event.html)
> 
>  [Event handling for iOS](https://stackoverflow.com/questions/4961386/event-handling-for-ios-how-hittestwithevent-and-pointinsidewithevent-are-r)
> 
> [Hit-Testing in iOS](http://smnh.me/hit-testing-in-ios)