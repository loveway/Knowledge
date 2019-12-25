iOS 的启动一般分为两大类：冷启动、热启动。
##### 热启动
按下 Home 键的时候，iOS APP 还存存在一段时间，这时点击 APP 马上就能恢复到原状态，这种启动我们称为热启动。App 最近结束后再启动，有部分在内存但没有进程存在。
###### 优化方案：
*  数据优化，将耗时操作做异步处理。
* 检查 NSUserDefaults 的存储，NSUserDefaults 实际上是在 Library 文件夹下会生产一个 plist 文件,加载的时候是整个 plist 配置文件全部 load 到内存中，所以非常频繁的存取大量数据也是有可能导致 APP 启动卡顿的。

###### 关于 NSUserDefaults
当系统调用 `[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@""]` 后系统会为用户在沙盒下的 `Libray/Preferences` 目录下创建`plist` 文件，文件名为当前应用的 `Bundle Identifier` 即 `[[NSBundle mainBundle] bundleIdentifier]` 用户可以通过 `NSUserDefaults` 接口的参数获取到该文件夹下的数据.

![NSUserDefaults-path](../image/NSUserDefaults-path)


关于沙盒和数据存储可以参考：
> [Data Persistence and Sandboxing on iOS](https://code.tutsplus.com/tutorials/data-persistence-and-sandboxing-on-ios--mobile-14078)
> 
> [iOS-NSUserDefaults详解](https://juejin.im/post/5ce756aef265da1b6d3ffee6)