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

实际上我们 APP 的视图的构建是树状层次结构构建起来的，每一个视图（view）都会有它的父视图（superView），当一个 view 被添加到它的 superView 上面的时候，这个 view 的 nextResponder 就会指向它的 superView，当一个 viewController 被创建的时候，它的视图（self.view）的 nextResponder 会指向这个 viewController，viewController 的 nextResponder 会指向它视图（self.view）的父视图 (UIWindow)，下面这张图可以看清整个流程。

![responder-chain](https://github.com/loveway/iOS-Knowledge/blob/master/image/responder-chain.png?raw=true)

传递过程需要注意以下几点:
1. 判断当前视图是否为控制器（viewController）的 view。如果是，事件就传递给控制器（viewController）；如果不是，事件就传递给它的父控件（superView）
2. 在视图层次结构的最顶层，如果也不能处理收到的事件，则将事件传递给 window 对象处理
3. 如果 window 对象也不处理，则将事件传递给 UIApplication 对象
4. 如果 UIApplication 对象也不处理，则将事件丢弃

## 二、如何找到具体的响应者

开头我们了解到 iOS 有三种 event 类型，事件传递中 UIWindow 会根据不同的 event，用不同的方式寻找 initial object，initial object 决定于当前的事件类型。比如 Touch Event，UIWindow 会首先试着把事件传递给事件发生的那个 view，就是下面要说的 Hit-Testing View。对于 Motion 和Remote Event，UIWindow 会把例如震动或者远程控制的事件传递给当前的 firstResponder。

上面我们了解到了响应链的相关知识，那么接下来就是响应者了，系统如何知道我们点击了屏幕的哪一个 view 呢？这里我们就要说一下 Hit-Test，Hit-Test 可以理解为是一个探测器，帮助我们找到相应的 view，这个过程就是 Hit-Test，找到的 view 我们称之为 Hit-Testing View。

在 UIView 中有如下两个方法：

```objc
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event; 
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;
```

每当手指接触屏幕，UIApplication 接收到手指的事件之后，就会去调用 UIWindow 的`hitTest:withEvent:` 方法，看看当前点击的点是不是在 window 内，如果是则继续依次调用 subView 的 `hitTest:withEvent:` 方法，直到找到最后需要的 view。调用结束并且 Hit-Testing View 确定之后，这个 view 和 view 上面依附的手势，都会和一个UITouch 的对象关联起来，这个 UITouch 会作为事件传递的参数之一，我们可以看到UITouch 头文件里面有一个 view 和 gestureRecognizers 的属性，就是 Hit-Testing View 和它的手势。

Hit-Test 是采用递归的方法从 view 层级的根节点开始遍历，如下

![hit-test-view-hierarchy](https://github.com/loveway/iOS-Knowledge/blob/master/image/hit-test-view-hierarchy.png?raw=true)


UIWindow 有一个 MainVIew，MainView 里面有三个 subView：view A、view B、view C，他们各自有两个 subView，他们层级关系是：view A 在最下面，view B 中间，view C 最上(也就是 addSubview 的顺序，越晚 add 进去越在上面)，其中 view A 和 view B 有一部分重叠。如果手指在 view B.1 和 view A.2 重叠的上面点击，按照上面说的递归方式，顺序如下图所示：

![hit-test-depth-first-traversal](https://github.com/loveway/iOS-Knowledge/blob/master/image/hit-test-depth-first-traversal.png?raw=true)

递归是向界面的根节点 UIWindow 发送 `hitTest:withEvent:` 消息开始的，从这个消息返回的是一个 UIView，也就是手指当前位置最前面的那个 Hit-Testing View。 当向  UIWindow 发送 `hitTest:withEvent:` 消息时，`hitTest:withEvent:` 里面所做的事，就是判断当前的点击位置是否在 window 里面，如果在则遍历 window 的 subview 然后依次对 subview 发送 `hitTest:withEvent:` 消息(注意这里给 subview 发送消息是根据当前 subview 的 index 顺序，index 越大就越先被访问)。如果当前的 point 没有在view 上面，那么这个 view 的 subview 也就不会被遍历了。

上图的流程就是
1. 向根视图 UIWindow 进行 Hit-Test，发现当前点击位置是在 UIWindow 上，继续遍历其子视图 MainView
2. 对 MainView 进行 Hit-Test，发现点击位置也在 MainView 上，继续遍历 MainView 的子视图
3. 遍历 View C，因为根据层级 View C 是最后加上去的，所以最优先遍历，此时发现点击位置不在 View C 上面，开始找到 View B（View B 比 View C 先加上去，所以按顺序后一步遍历）
4. 遍历 View B，同理先遍历 View B.2 ，发现点击位置不在 View B.2 上，找到 View B.1
5. 遍历 View B.1 ，发现点击位置在 View B.1 上，并且 View B.1 没有子视图，那么就确定 View B.1 是我们要找的 view，返回 View B.1

代码的逻辑大致如下
```objc
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {

    if (!self.isUserInteractionEnabled || self.hidden || self.alpha <= 0.01) {
        return nil;
    }
    if ([self pointInside:point withEvent:event]) {
        for (UIView *subView in [self.subviews reverseObjectEnumerator]) {
            CGPoint coverPoint = [subView convertPoint:point fromView:self];
            UIView *hitView = [subView hitTest:coverPoint withEvent:event];
            if (hitView) {
                return hitView;
            }
        }
        return self;
    }
    return nil;
}
```

逻辑图如下

![hit-test-flowchart](https://github.com/loveway/iOS-Knowledge/blob/master/image/hit-test-flowchart.png?raw=true)

## 三、Hit-Test 的应用

### 1、扩大视图的响应区域

我们经常会遇到产品要求扩大按钮点击范围的这种需求，在我们了解响应链之后，我们就可以通过重写 `hittest:withEvent` 方法来达到这个目的，代码如下

```objc
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {

    if (!self.isUserInteractionEnabled || self.hidden || self.alpha <= 0.01) {
        return nil;
    }
    //扩大响应区域
    CGRect touchRect = CGRectInset(self.bounds, -20, -20);
    if (CGRectContainsPoint(touchRect, point)) {
        for (UIView *subView in [self.subviews reverseObjectEnumerator]) {
            CGPoint coverPoint = [subView convertPoint:point fromView:self];
            UIView *hitView = [subView hitTest:coverPoint withEvent:event];
            if (hitView) {
                return hitView;
            }
        }
        return self;
    }
    return nil;
}
```

Tips:
> 关于 `CGRectInset` 和 `CGRectOffset` 的对比如下
>
>
>

### 2、将触摸事件传递到下面的视图

如果有 view A 和 view B，view B 有一部分覆盖 view A 上面，点击重叠区域那么肯定是 view B 响应，如果我们想让 view A 响应该如何做呢？这个时候我们可以通过重写 view B 的 `hittest:withEvent` 方法达到目的
```objc
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitTestView = [super hitTest:point withEvent:event];
    if (hitTestView == self) {
        hitTestView = nil;
    }
    return hitTestView;
}
```
### 3、将触摸事件传递给子视图

如图，蓝色的 scrollView 设置 pagingEnabled 使得 image 停止滚动后都会固定在居中的位置，如果在 scrollView 的左边或者右边活动，发现 scrollView 是无法滚动的，原因就是 Hit-Test 里面没有满足 pointInSide 这个条件，scrollView 的 bounds 只有蓝色的区域。这个时候重写 `hittest:withEvent`，然后返回 scrollView 即可解决问题。

```objc
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitTestView = [super hitTest:point withEvent:event];
    if (hitTestView) {
        hitTestView = self.scrollView;
    }
    return hitTestView;
}
```
Reference:
> [Responder object](https://developer.apple.com/library/archive/documentation/General/Conceptual/Devpedia-CocoaApp/Responder.html)
> 
>  [Event handling for iOS](https://stackoverflow.com/questions/4961386/event-handling-for-ios-how-hittestwithevent-and-pointinsidewithevent-are-r)
> 
> [Hit-Testing in iOS](http://smnh.me/hit-testing-in-ios)
> 
> [深入浅出iOS事件机制](https://zhoon.github.io/ios/2015/04/12/ios-event.html)
