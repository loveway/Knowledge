# iOS 中的内省方法：isMemberOfClass 与 isKindOfClass 
## 1、iOS 中的内省方法
OC 作为一门面向对象的强大语言，具有内省 [Introspection](https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/Introspection/Introspection.html) 这样一个强大的特性，也是运行时获取其类型的能力，一些常用的内省方法如下
```objc
+ (Class)superclass; // 获取类继承链上的父类
- (Class)superclass; // 获取实例的类继承链上的父类

+ (BOOL)isMemberOfClass:(Class)cls; // 判断类的元类是否是给定类
- (BOOL)isMemberOfClass:(Class)cls; // 判断实例的类是否是给定类
+ (BOOL)isKindOfClass:(Class)cls; // 判断类的元类是否在给定类继承链上
- (BOOL)isKindOfClass:(Class)cls; // 判断实例的类是否在给定类继承链上

+ (BOOL)respondsToSelector:(SEL)sel; // 类的元类中是否能查找到指定类方法
- (BOOL)respondsToSelector:(SEL)sel; // 实例的类中是否能查找到指定实例方法
+ (BOOL)instancesRespondToSelector:(SEL)sel; // 类中是否能查找到指定实例方法

+ (BOOL)conformsToProtocol:(Protocol *)protocol; // 类是否遵循指定协议并实现协议的@required方法
- (BOOL)conformsToProtocol:(Protocol *)protocol; // 实例的类是否遵循指定协议并实现协议的@required方法
```
我们常用的就是 isMemberOfClass 和 isKindOfClass，经常容易搞混，但是当我们研究明白其本质后，就会发现很简单，在此之前我们先贴上一张经典的 runtime 的图
## 2、isMemberOfClass
isMemberOfClass 有实例方法（-）和类方法（+）两种，基于 runtime 源码 `objc-781`，在 `NSObject.mm` 中我们会发现这两个方法的实现是开源的，其实现如下
```objc
/**
 类对象调用，相当于判断 cls 是不是传进来类对象的元类（ 因为 self->ISA() 指向他的元类 ）
 */
+ (BOOL)isMemberOfClass:(Class)cls {
    return self->ISA() == cls;
}

/**
 判断传入的对象的 class 是否是 cls ，如果 Person : NSObject , 有个 Person *p
 [p isMemberOfClass: [Person class]] 为 YES
 [p isMemberOfClass: [NSObject class]] 为 NO
 因为实质是比较 class， 就是判断 self 是不是 cls 这种类型
 */
- (BOOL)isMemberOfClass:(Class)cls {
    return [self class] == cls;
}
```
可以看到 `+ (BOOL)isMemberOfClass:(Class)cls` 的实质是判断传入得类对象的 **元类** 是不是 cls 类，而 `- (BOOL)isMemberOfClass:(Class)cls` 的实质是判断传入的实例对象的 **类** 是不是 cls 类，两者的区别是一个是判断元类，一个是判断类，抓住其本质我们看看下面问题
```OBJC
BOOL objMember = [(id)[NSObject alloc] isMemberOfClass:[NSObject class]];
BOOL customMember = [(id)[MMPerson alloc] isMemberOfClass:[MMPerson class]];
BOOL objClassMember = [(id)[NSObject class] isMemberOfClass:[NSObject class]];
BOOL customClassMember = [(id)[MMPerson class] isMemberOfClass:[MMPerson class]];
```
其结果是
```objc
YES YES NO NO
```
我么来分析一下
* 1、objMember 的判断，是一个 `-` 方法，判断 **类** 的，所以我们发现传入的 [NSObject alloc] 对象的 class 就是 NSObject 类，所以为 YES
* 2、customMember 的判断，同样是一个 `-` 方法，[MMPerson alloc] 对象的 **类** 就是 MMPerson，所以也是 YES
* 3、objClassMember 的判断，是一个 `+`，方法，是判断 **元类** 的，根据 runtime 的 isa 指向图我们可以知道，[NSObject class] 这个类对象的 isa 指向其根元类，也就是 root-metaclass，所以其不是 [NSObject class] 类，为 NO
* 4、customClassMember 的判断，和上面一样，[MMPerson class] 这个类对象的 isa 也是指向  MMPerson 的 metaclass 的，并不是 [MMPerson class]，为 NO

## 3、isKindOfClass
isKindOfClass 同样有实例方法（-）和类方法（+）两种，其具体实现如下
```objc
/**
 相当于向上是不是元类，不是找 superclass 最后找到 NSObject
 */
+ (BOOL)isKindOfClass:(Class)cls {
    for (Class tcls = self->ISA(); tcls; tcls = tcls->superclass) {
        if (tcls == cls) return YES;
    }
    return NO;
}
/**
 先判断 [self class] 是否是 cls，如果不是继续往 superclass 查找，就是判断 self 是不是 cls 这种类型或者是他的子类
 */

- (BOOL)isKindOfClass:(Class)cls {
    for (Class tcls = [self class]; tcls; tcls = tcls->superclass) {
        if (tcls == cls) return YES;
    }
    return NO;
}
```
可以看到 `+ (BOOL)isKindOfClass:(Class)cls`，是从传入 **类对象的元类** 开始，循环沿着 **元类-父类** 那条线向上查找，`- (BOOL)isKindOfClass:(Class)cls` 则是从传入的 **实例对象的类** 开始，循环沿着类->父类这条线向上查找，结合 runtime 的 isa 图我们就很容易理解了，了解了其本质我们看下面几种情况
```objc
    BOOL objKind = [(id)[NSObject alloc] isKindOfClass:[NSObject class]];
    BOOL customKind = [(id)[MMPerson alloc] isKindOfClass:[MMPerson class]];
    BOOL objClassKind = [(id)[NSObject class] isKindOfClass:[NSObject class]];
    BOOL customClassMember = [(id)[MMPerson class] isMemberOfClass:[MMPerson class]];
```
其结果为
```OBJC
YES YES YES NO
```
具体分析：
* 1、objKind 的判断，是一个 `-` 方法的调用，沿着 **类-父类** 这条线，我们发现 [NSObject alloc] 对象的的类就是 NSObject，所以为 YES
* 2、customKind 的判断，是一个 `-` 方法的调用，沿着 **类-父类** 这条线，我们发现 [MMPerson alloc] 对象的的类就是 MMPerson，所以为 YES
* 3、objClassKind 的判断，是一个 `+` 方法的调用，沿着 **元类-父类** 这条线，我们发现 [NSObject class] 这个类对象的元类是根元类，所以第一次判断为 NO，继续向上查找我们发现 root-metaclass 的 superclass 刚好是 NSObject 类，所以找到，返回 YES
* 4、customClassMember 的判断，同样是一个 `+` 方法的调用，沿着 **元类-父类** 这条线，我们发现 [MMPerson class] 这个类对象的元类是其元类，然后一直向上查找也不会找到 MMPerson 这个类，所以为 NO

到这里，弄清楚了本质，相信 isMemberOfClass 与 isKindOfClass 再也不会混淆不清了。