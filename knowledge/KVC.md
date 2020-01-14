# iOS 中的 KVC

## 基本用法
KVC 全称是 Key Value Coding，定义在 `NSKeyValueCoding.h` 文件中，是一个非正式协议。KVC 提供了一种间接访问其属性方法或成员变量的机制，可以通过字符串来访问对应的属性方法或成员变量。

KVC 和 属性访问器的对比如下：

1. KVC 是通过在运行时动态的访问和修改对象的属性而访问器是在编译时确定，单就这一点增加了访问属性的灵活性，但是用访问器访问属性的时候编译器会做预编译处理，访问不存在的属性编译器会报错，使用 KVC 方式的时候如果有错误只能在运行的时候才能发现。
2. 相比访问器 KVC 效率会低一点。
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
上面我们设置 `name`、`_name` 都可以改变 name 属性的原因在于 KVC 给一个对象赋值时，方法调用的顺序如下：

## 搜索模式
###  1. 基础的 getter 的搜索模式（`(id)valueForKey:(NSString *)key`）
1. 首先查找 getter 方法，如 `get<Key>`, `<key>`, `is<Key>`, `_<key>` 的拼接方案。按照这个顺序，如果发现符合的方法，就调用对应的方法并拿着结果跳转到第五步，否则，就继续到下一步。
2. 如果没有找到简单的 getter 方法，则搜索其匹配模式的方法 `countOf<Key>`、`objectIn<Key>AtIndex:`、`<key>AtIndexes:`
   如果找到其中的第一个和其他两个中的一个，则创建一个集合代理对象，该对象响应所有 NSArray 的方法并返回该对象。否则，继续到第三步。
   代理对象随后将 NSArray 接收到的 `countOf<Key>`、`objectIn<Key>AtIndex:`、       `<key>AtIndexes:`的消息给符合 KVC 规则的调用方。当代理对象和KVC调用方通过上面方法一起工作时，就会允许其行为类似于NSArray一样
3. 如果没有找到 NSArray 简单存取方法，或者 NSArray 存取方法组。则查找有没有 `countOf<Key>`、`enumeratorOf<Key>`、`memberOf<Key>:` 命名的方法。
如果找到三个方法，则创建一个集合代理对象，该对象响应所有 NSSet 方法并返回。否则，继续执行第四步。
此代理对象随后转换 `countOf<Key>`、`enumeratorOf<Key>`、`memberOf<Key>:` 方法调用到创建它的对象上。实际上，这个代理对象和 NSSet 一起工作，使得其表象上看起来是NSSet 。
4. 如果没有发现简单 getter 方法，或集合存取方法组，以及接收类方法`accessInstanceVariablesDirectly` 是返回 YES 的。搜索一个名为 `_<key>`、`_is<Key>`、`<key>`、`is<Key>` 的实例，根据他们的顺序。如果发现对应的实例，则立刻获得实例可用的值并跳转到第五步，否则，跳转到第六步。
5. 如果取回的是一个对象指针，则直接返回这个结果。如果取回的是一个基础数据类型，但是这个基础数据类型是被 NSNumber 支持的，则存储为 NSNumber 并返回。如果取回的是一个不支持 NSNumber 的基础数据类型，则通过 NSValue 进行存储并返回。
6. 如果所有情况都失败，则调用 `valueForUndefinedKey:` 方法并抛出异常，这是默认行为。但是子类可以重写此方法。

### 2. 基础的 setter 的搜索模式（`(void)setValue:(id)value forKey:(NSString *)key`）
1. 查找 `set<Key>:` 或 `_set<Key>` 命名的 setter，按照这个顺序，如果找到的话，调用这个方法并将值传进去(根据需要进行对象转换)。
2. 如果没有发现一个简单的 setter，但是 `accessInstanceVariablesDirectly` 类属性返回 YES，则查找一个命名规则为 `_<key>`、`_is<Key>`、`<key>`、`is<Key>` 的实例变量。根据这个顺序，如果发现则将 value 赋值给实例变量。
3. 如果没有发现 setter 或实例变量，则调用 `setValue:forUndefinedKey:` 方法，并默认提出一个异常，但是一个 NSObject 的子类可以提出合适的行为。

还有一些其他的搜索模式，具体可以看官方文档 [Accessor Search Patterns](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueCoding/SearchImplementation.html#//apple_ref/doc/uid/20000955-CJBBBFFA) 。

## 其他的一些用法
### 1. keyPath 用法

接着上面定义的 Person 和 Man

```objc
Person *p = [Person new];
Man *man = [Man new];
    
[man setValue:@180.0 forKey:@"height"];
[p setValue:man forKey:@"man"];
NSLog(@"man height is %@", [p valueForKeyPath:@"man.height"]);
[p setValue:@175.0 forKeyPath:@"man.height"];
NSLog(@"man height is %@", [p valueForKeyPath:@"man.height"]);
```

输出

```objc
2020-01-14 13:47:33.029895+0800 OC_test[72498:747607] man height is 180
2020-01-14 13:47:33.030223+0800 OC_test[72498:747607] man height is 175
```

### 2. 异常处理

如上所说，如果我们到最后都没找到对应的 key，会调用 `setValue:forUndefinedKey: ` 和 `valueForUndefinedKey:` 方法，我们可以处理相应的异常

```objc
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    if ([key isEqualToString:@"mm"]) {
        NSLog(@"catch set undefined key");
    }
}

- (id)valueForUndefinedKey:(NSString *)key {
    NSLog(@"catch get undefined key");
    return @"undefined key";
}

...

Person *p = [Person new];
[p setValue:@"mm" forKey:@"mm"];
[p valueForUndefinedKey:@"mm"];
```

输出

```objc
2020-01-14 14:17:58.348130+0800 OC_test[72817:768654] catch set undefined key
2020-01-14 14:17:58.348384+0800 OC_test[72817:768654] catch get undefined key
```

如果是设置了 nil，会调用 `setNilValueForKey:` 方法，可以如下处理

```objc
- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:@"uu"]) {
        [self setValue:@"uu" forUndefinedKey:@"uu"];
    }
}
```

### 3. 字典-模型

将字典转化为 model，可用 `setValuesForKeysWithDictionary:` 方法
```objc
NSDictionary *dic = @{
    
    @"name": @"mm",
    @"boy": @YES,
    @"isTest": @NO
};
    
Person *p = [Person new];
[p setValuesForKeysWithDictionary:dic];
NSLog(@"%@", p);
```

输出

```objc
2020-01-14 14:49:46.675234+0800 OC_test[73053:787053] name: mm, boy: 1 age: 0, readOnly: (null), isTest: 0
```

model 转字典，调用 `dictionaryWithValuesForKeys:` 方法

```objc  
Person *p = [Person new];
p.name = @"loveway";
p.boy = YES;
p.isTest = YES;
    
NSDictionary *dic = [p dictionaryWithValuesForKeys:@[@"name", @"boy", @"isTest"]];
NSLog(@"%@", dic);
```

输出

```objc
2020-01-14 14:54:45.445526+0800 OC_test[73098:790878] {
    boy = 1;
    isTest = 1;
    name = loveway;
}
```

### 4. 集合操作

相比于普通对象NSArray 以及 NSSet 在使用上我们需自己实现一遍下面的方法：

```objc
//必须实现，对应于NSArray的基本方法count: 
-countOf<Key>
//这两个必须实现一个，对应于 NSArray 的方法 objectAtIndex: 和 objectsAtIndexes:  
-objectIn<Key>AtIndex:  
-<Key>AtIndexes:  
 
//两个必须实现一个，类似 NSMutableArray 的方法 insertObject:atIndex: 和 insertObjects:atIndexes: 
-insertObject:in<Key>AtIndex:  
-insert<Key>:atIndexes:  

//两个必须实现一个，类似于 NSMutableArray 的方法 removeObjectAtIndex: 和 removeObjectsAtIndexes:
-removeObjectFrom<Key>AtIndex:  
-remove<Key>AtIndexes:
```

KVC 对于数组而言最大的功能还是获取集合类的 count，max，min，avg，sum 这是一个很好用的功能

```objc
NSArray *a = @[@4, @84, @2];
NSLog(@"max = %@", [a valueForKeyPath:@"@max.self"]);
```

输出

```objc
2020-01-14 15:06:18.069478+0800 OC_test[73206:798380] max = 84
```

如果是对象

```objc
Person *p1 = [Person new];
p1.name = @"a";
Person *p2 = [Person new];
p2.name = @"b";
Person *p3 = [Person new];
p3.name = @"c";
    
NSArray *a = @[p1, p2, p3];
NSLog(@"max = %@", [a valueForKeyPath:@"@max.name"]);
```

输出

```objc
2020-01-14 15:08:35.220413+0800 OC_test[73235:800521] max = c
```

当我们调用 `[a valueForKeyPath:@"@max.amount"]` 的时候，它会在数组 a 的每个元素中调用 `-valueForKey:@"amount"` 然后返回最大的那个。

### 5. 键值验证 (KVV)

KVV(key-value-validate) 也是 KVC API 的一部分。这是一个用来验证属性值的 API，只是它光靠自己很难提供逻辑和功能。

如果我们写能够验证值的 model 类的话，我们就应该实现 KVV 的 API 来保证一致性。用 KVV 验证 model 类的值是 Cocoa 的惯例。

**KVC 不会做任何的验证，也不会调用任何 KVV 的方法。那是你的控制器需要做的事情。通过 KVV 实现你自己的验证方法会保证它们的一致性。**

```objc
//class Person
- (BOOL)validateValue:(inout id  _Nullable __autoreleasing *)ioValue forKey:(NSString *)inKey error:(out NSError *__autoreleasing  _Nullable *)outError {
    NSString *name = *ioValue;
    if ([name isEqualToString:@"mm"]) {
        NSLog(@"This is me !");
        return YES;
    }
    return NO;
}

...
//class ViewController
Person *p = [Person new];
NSString *value = @"mm";
NSString *key = @"name";
NSError *error;
NSLog(@"mm validate result is : %d", (BOOL)[p validateValue:&value forKey:key error:&error]);
    
NSString *value2 = @"uu";
NSLog(@"uu validate result is : %d", (BOOL)[p validateValue:&value2 forKey:key error:&error]);
```

输出

```objc
2020-01-14 15:21:05.350557+0800 OC_test[73391:813196] This is me !
2020-01-14 15:21:05.350825+0800 OC_test[73391:813196] mm validate result is : 1
2020-01-14 15:21:05.350962+0800 OC_test[73391:813196] uu validate result is : 0
```


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