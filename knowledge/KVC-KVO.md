# iOS 中的 KVC、KVO
## KVC

KVC 全称是 Key Value Coding，定义在 `NSKeyValueCoding.h` 文件中，是一个非正式协议。KVC 提供了一种间接访问其属性方法或成员变量的机制，可以通过字符串来访问对应的属性方法或成员变量。

KVC 和 属性访问器的对比如下：

1. KVC是通过在运行时动态的访问和修改对象的属性而访问器是在编译时确定，单就这一点增加了访问属性的灵活性，但是用访问器访问属性的时候编译器会做预编译处理，访问不存在的属性编译器会报错，使用KVC方式的时候如果有错误只能在运行的时候才能发现。
2. 相比访问器KVC 效率会低一点。
3. KVC 可以访问对象的私有属性，修改只读属性。
4. KVC 在字典转模型，集合类操作方面有着普通访问器不能提供的功能。

具体例子看下面

```objc
#import "ViewController.h"

// class Man
@interface Man : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) CGFloat  height;
@end

@interface Man ()

@end
@implementation Man
@end

// class Person
@interface Person : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) BOOL boy;
@property (nonatomic, strong) Man *man;
@property (nonatomic, strong, readonly) NSString *readOnly;
@property (nonatomic, assign) BOOL isTest;

@end

@interface Person ()
@property (nonatomic, assign) int age;
@end
@implementation Person

- (NSString *)description {
    return [NSString stringWithFormat:@"name: %@, boy: %d age: %d, readOnly: %@, isTest: %d", self.name, self.boy, self.age, self.readOnly, self.isTest];
}

@end


@interface ViewController ()

@property (nonatomic, strong) Person *p;

@end


@implementation ViewController


- (void)viewDidLoad {
    
    Person *p = [Person new];
//    name、_name 都可以修改其 name 变量
    [p setValue:@"mm" forKey:@"name"];
    NSLog(@"%@", p);
    [p setValue:@"uu" forKey:@"_name"];
    NSLog(@"%@", p);
    
//    age、_age 都可以修改其私有变量 age
    [p setValue:@(17) forKey:@"age"];
    NSLog(@"%@", p);
    [p setValue:@(18) forKey:@"_age"];
    NSLog(@"%@", p);
    
//    readOnly、_readOnly 都可以修改其只读属性
    [p setValue:@"modify it to r and w 1" forKey:@"readOnly"];
    NSLog(@"%@", p);
    [p setValue:@"modify it to r and w 2" forKey:@"_readOnly"];
    NSLog(@"%@", p);
    
//    set @"test" 这个属性，我们发现改变了 isTest 这个属性
    [p setValue:@(YES) forKey:@"test"];
    NSLog(@"%@", p);
}

@end
```

输出

```objc
2020-01-09 17:21:17.070612+0800 OC_test[45253:1705348] name: mm, boy: 0 age: 0, readOnly: (null), isTest: 0
2020-01-09 17:21:17.071904+0800 OC_test[45253:1705348] name: uu, boy: 0 age: 0, readOnly: (null), isTest: 0
2020-01-09 17:21:17.073370+0800 OC_test[45253:1705348] name: uu, boy: 0 age: 17, readOnly: (null), isTest: 0
2020-01-09 17:21:17.074511+0800 OC_test[45253:1705348] name: uu, boy: 0 age: 18, readOnly: (null), isTest: 0
2020-01-09 17:21:17.074725+0800 OC_test[45253:1705348] name: uu, boy: 0 age: 18, readOnly: modify it to r and w 1, isTest: 0
2020-01-09 17:21:17.075126+0800 OC_test[45253:1705348] name: uu, boy: 0 age: 18, readOnly: modify it to r and w 2, isTest: 0
2020-01-09 17:21:17.075372+0800 OC_test[45253:1705348] name: uu, boy: 0 age: 18, readOnly: modify it to r and w 2, isTest: 1
```
上面我们设置 `name`、`_name` 都可以改变 name 属性的原因在于 KVC 给一个对象赋值时，方法1调用的顺序如下：


Reference:
> [iOS KVC KVO 总结](http://coderlin.coding.me/2019/06/21/iOS-KVC-KVO/)
> 
> [ObjC: KVC 和 KVO](https://objccn.io/issue-7-3/)
> 
> [Objective-C中的KVC和KVO](http://yulingtianxia.com/blog/2014/05/12/objective-czhong-de-kvche-kvo/)
> 
>  [KVO Compliance](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOCompliance.html#//apple_ref/doc/uid/20002178-BAJEAIEE)
> 
> [KVC/KVO原理详解及编程指南](https://blog.csdn.net/wzzvictory/article/details/9674431)
> 
> [Key-Value Observing Done Right](https://www.mikeash.com/pyblog/key-value-observing-done-right.html)
> 
> [Accessor Search Patterns](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueCoding/SearchImplementation.html#//apple_ref/doc/uid/20000955-CJBBBFFA)
> 
> [KVC原理剖析](https://www.jianshu.com/p/1d39bc610a5b)