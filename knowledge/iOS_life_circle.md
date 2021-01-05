# UIViewController 的生命周期

* 1. `initWithCoder:` 或 `initWithNibName:Bundle` 首先从归档文件中加载 UIViewController 对象，即使是纯代码，也会把 nil 作为参数传给后者
* 2. `awakeFromNib`
* 3. `loadView` 创建或者加载一个视图，赋值给 UIViewController 的 view，如果没有调用 `[super loadView]` 或者赋值 `self.view`，将会出现 `loadView` 和 `viewDidLoad` 的死循环
* 4. `viewDidLoad`
* 5. `viewWillAppear`
* 6. `viewWillLayoutSubviews`
* 7. `viewDidLayoutSubviews`
* 8. `viewDidAppear`
* 9. `viewWillDisappear`
* 10. `viewDidDisappear`
* 11. `dealloc`


```objc
2021-01-05 10:42:43.025083+0800 OC_test[83749:5636453] initWithCoder
2021-01-05 10:42:43.025755+0800 OC_test[83749:5636453] -[ViewController awakeFromNib]
2021-01-05 10:42:43.072384+0800 OC_test[83749:5636453] loadView
2021-01-05 10:42:43.075890+0800 OC_test[83749:5636453] viewDidLoad
2021-01-05 10:42:43.076562+0800 OC_test[83749:5636453] viewWillAppear
2021-01-05 10:42:43.081526+0800 OC_test[83749:5636453] viewWillLayoutSubviews
2021-01-05 10:42:43.081712+0800 OC_test[83749:5636453] viewDidLayoutSubviews
2021-01-05 10:42:43.204529+0800 OC_test[83749:5636453] viewDidAppear
```