# setNeedsLayout、layoutIfNeeded、layoutSubviews
我们经常会看到这几个方法，但是可能并没有深入了解这几个到底是干啥的，有啥区别和联系？现在我们就从官方文档入手，探究这几个方法的作用。
## 1、setNeedsLayout
当你需要改变布局时，需要在主线程调用这个方法，这个方法会立刻执行并返回，但是不会立即更新视图，二是会去做一个标记，等到 Update Cycle（是当应用完成了你的所有事件处理代码后控制流回到主 RunLoop 时的那个时间点）的时候再去更新（这个时间非常短，我们感受不到）。这样做其实是性能最好的，比如再一次 runloop 中需要更新多次视图，如果我们调用 `setNeedsLayout()` 方法，则会去做一个标记，这样等到 Update Cycle 的时候可以一次性处理这些标记，而不用每调用一次就立马去处理
## 2、layoutIfNeeded
这个方法调用后会立即更新视图，并不会等到 Update Cycle，可想而知，频繁调用此方法会相对来说比较耗费性能，一般用在更新约束后视图做动画用
```objc
[self.view layoutIfNeeded];
if (_heightConstraint.constant == 100) {
    _heightConstraint.constant = 200;
} else {
    _heightConstraint.constant = 100;
}
[UIView animateWithDuration:3 animations:^{
// 不调用此方法或者调用 setNeedsLayout 则动画不会发生
    [self.view layoutIfNeeded];
}];
```
## 3、layoutSubviews
这个方法在 `iOS 5.1` 之前并没有什么作用，在 `iOS 5.1` 之后是用来布局子视图的。如果子视图想获得更加精确地布局可以重写这个方法，但是呢，不建议直接调用，例如出现 `[view layoutSubviews]` 这种情况。如果你想强制更新布局，可以调用 `setNeedsLayout()` 这个方法，这个方法会在下一次视图更新之前调用（也就是主  runloop 最后的 Update Cycle，此方法并不会立即更新视图）。如果你想立即更新视图，直接调用 `layoutIfNeeded（）` 即可，这个方法调用以后就会立即更新视图。

以上就是官方文档所给出的解释，至于更多的细节我发现已经有人说过并且说得很好，这里我就不赘述了，直接引用，强烈推荐看完以下几篇文章
* [iOS 布局理解](https://monsoir.github.io/Notes/iOS/ios-layout-understanding.html)
* [揭秘 iOS 布局](https://juejin.cn/post/6844903567610871816)
* [Demystifying iOS Layout](https://tech.gc.com/demystifying-ios-layout/)
* [How do I animate constraint changes?](https://stackoverflow.com/questions/12622424/how-do-i-animate-constraint-changes/12664093#12664093)
* [What is the relationship between UIView's setNeedsLayout, layoutIfNeeded and layoutSubviews?](https://stackoverflow.com/questions/2807137/what-is-the-relationship-between-uiviews-setneedslayout-layoutifneeded-and-lay)

> Reference
> 1. [setNeedsLayout()](https://developer.apple.com/documentation/uikit/uiview/1622601-setneedslayout)
> 2. [layoutSubviews()](https://developer.apple.com/documentation/uikit/uiview/1622482-layoutsubviews)
> 3. [layoutIfNeeded()](https://developer.apple.com/documentation/uikit/uiview/1622507-layoutIfNeeded())