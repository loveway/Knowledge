# 关于 iOS 的启动
iOS 的启动一般分为两大类：冷启动、热启动。
## 热启动
按下 Home 键的时候，iOS APP 还存存在一段时间，这时点击 APP 马上就能恢复到原状态，这种启动我们称为热启动。App 最近结束后再启动，有部分在内存但没有进程存在。
##### 优化方案：
*  数据优化，将耗时操作做异步处理。
* 检查 NSUserDefaults 的存储，NSUserDefaults 实际上是在 Library 文件夹下会生产一个 plist 文件,加载的时候是整个 plist 配置文件全部 load 到内存中，所以非常频繁的存取大量数据也是有可能导致 APP 启动卡顿的。

##### 关于 NSUserDefaults
当系统调用 `[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@""]` 后系统会为用户在沙盒下的 `Libray/Preferences` 目录下创建`plist` 文件，文件名为当前应用的 `Bundle Identifier` 即 `[[NSBundle mainBundle] bundleIdentifier]` 用户可以通过 `NSUserDefaults` 接口的参数获取到该文件夹下的数据.
![](https://github.com/loveway/iOS-Knowledge/blob/master/image/NSUserDefaults-path.png?raw=true)

* NSUserDefaults 是线程安全的
* NSUserDefaults 其实是一个 plist 文件，即使只是修改一个 key 都会 load 整个文件，不适合存储大量数据

关于沙盒和数据存储可以参考：
> [NSUserDefaults](https://developer.apple.com/documentation/foundation/nsuserdefaults)
> 
> [Data Persistence and Sandboxing on iOS](https://code.tutsplus.com/tutorials/data-persistence-and-sandboxing-on-ios--mobile-14078)
> 
> [iOS-NSUserDefaults详解](https://juejin.im/post/5ce756aef265da1b6d3ffee6)

## 冷启动
从用户点击 App 图标开始到 `appDelegate didFinishLaunching` 方法执行完成为止。重新启动后，不在内存里也没有进程存在。
##### 冷启动的过程
从 `exec()` 函数开始

 序号 | 步骤 |  说明 | 
|:-------:|:-------:|:-------:|
| 1 |把 App 对应的可执行文件（Mach-o）加载到内存 | |
| 2 |把 Dyld (the dynamic link editor 动态链接器) 加载到内存 | |
| 3 |Dyld 进行动态链接 | 1. Dyld 从主执行文件的 header 获取到需要加载的所依赖动态库列表<br>2. 然后它需要找到每个 dylib，而应用所依赖的 dylib 文件可能会再依赖其他 dylib，所以所需要加载的是动态库列表一个递归依赖的集合 |
| 4 | Rebase | Rebase 在 Image 内部调整指针的指向。在过去，会把动态库加载到指定地址，所有指针和数据对于代码都是对的，而现在地址空间布局是随机化，所以需要在原来的地址根据随机的偏移量做一下修正 |
| 5 | Bind | Bind 是把指针正确地指向 Image 外部的内容。这些指向外部的指针被符号(symbol)名称绑定，dyld 需要去符号表里查找，找到 symbol 对应的实现 |
| 6 | Objc setup |	1. 注册Objc类 (class registration)<br>2. 把category的定义插入方法列表 (category registration)<br>3.保证每一个selector唯一 (selector uniquing) |
| 7 | Initializers | 1. Objc的 +load() 函数<br>2. C++ 的构造函数属性函数<br>3. 非基本类型的C++静态全局变量的创建(通常是类或结构体) |
| 8 | 执行 `main()` 函数 | |
| 9 | `application:willFinishLaunchingWithOptions` | |
| 10 | `application:didFinishLaunchingWithOptions:` | |
| 11 | 首页的构建和渲染 | |   


##### 可以优化的点：
###### main() 函数之前
1. 动态库加载越多，启动越慢
2. ObjC类，方法越多，启动越慢（去除无用的类以及无用的方法，进行代码瘦身）
3. ObjC的 +load 越多，启动越慢（过多 +load 方法则会拖慢启动速度，可以分析需求把一些不必要的 +load 方法放在冷启动之后进行）
4. C 的 constructor 函数越多，启动越慢
5. C++ 静态对象越多，启动越慢
###### main() 函数之后
在 main() 之后主要工作是各种启动项的执行，资源的加载，如图片 I/O、图片解码、archive 文档等，这些操作中可能会隐含着一些耗时操作。
1. 发现隐晦的耗时操作进行优化
2. 推迟&减少 I/O 操作（减少动画图片组的数量，替换大图资源等。因为相比于内存操作，硬盘 I/O 是非常耗时的操作）
3. 推迟执行的一些任务（如一些资源的 I/O，一些布局逻辑，对象的创建时机等）
4. 优化串行操作（在冷启动过程中，有很多操作是串行执行的，若干个任务串行执行，时间必然比较长。如果能变串行为并行，那么冷启动时间就能够大大缩短）
            
Reference：
> [美团外卖iOS App冷启动治理](https://tech.meituan.com/2018/12/06/waimai-ios-optimizing-startup.html)
> 
> [如何对-iOS-启动阶段耗时进行分析](https://github.com/ming1016/study/wiki/%E5%A6%82%E4%BD%95%E5%AF%B9-iOS-%E5%90%AF%E5%8A%A8%E9%98%B6%E6%AE%B5%E8%80%97%E6%97%B6%E8%BF%9B%E8%A1%8C%E5%88%86%E6%9E%90)
> 
> [Optimizing App Startup Time](https://asciiwwdc.com/2016/sessions/406)
