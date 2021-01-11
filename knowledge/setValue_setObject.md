# iOS 中的 `setNilValueForKey:`、`setValue:forKey:` 和 `setObject:forKey:`

### 1、`setNilValueForKey:`
关于这个方法的定义
```objc
/* Given that an invocation of -setValue:forKey:would be unable 
to set the keyed value because the type 
of the parameter of the corresponding accessor 
method is an NSNumber scalar type or NSValue structure type but the value is nil, 
set the keyed value using some other mechanism. 
The default implementation of this method raises an 
NSInvalidArgumentException. You can override 
it to map nil values to something meaningful 
in the context of your application.
*/
- (void)setNilValueForKey:(NSString *)key;
```
意思就是当我们给基本数据类型的变量设置 `nil` 的时候会被调用，并会抛出一个 `NSInvalidArgumentException` 异常。经过测试，
```objc
@interface MMPerson : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int age;
@property (nonatomic, assign) float height;
@end

@implementation MMPerson
- (void)setNilValueForKey:(NSString *)key {
    NSLog(@"%s%@", __func__, key);
}
@end
...

MMPerson *p = [[MMPerson alloc] init];
[p setValue:nil forKey:@"age"];
[p setValue:nil forKey:@"name"];
[p setValue:nil forKey:@"height"];
```
MMPerson 类里面有 age、height 和 name 属性，分别是是 int、float 和 NSString 类型，，我们运行会发现输出一下结果
```objc
2021-01-11 16:35:20.091507+0800 OC_test[5661:66398] -[MMPerson setNilValueForKey:]age
2021-01-11 16:35:20.091935+0800 OC_test[5661:66398] -[MMPerson setNilValueForKey:]height
```
只有 age 和 height 设置的时候调用了 `setNilValueForKey:` 这个方法，我们如果想处理的话也可以重写，使用 0 来代替 nil
```objc
- (void)setNilValueForKey:(NSString *)key {
    [self setValue:@0 forKey:key];
}
```
### 2、 `setValue:forKey:` 和 `setObject:forKey:`
我们一般来说区别这两个方法主要是针对 NSMutableDictionary.
首先 `setValue:forKey:` 这个方法是定义在 NSObject(NSKeyValueCoding) 这个分类中，也就是说所有 NSObject 的子类都可以调用这个方法。但是 NSMutableDictionary 自己也新加了一个类别，重写了这个方法

```objc
@interface NSMutableDictionary<KeyType, ObjectType>(NSKeyValueCoding)

/* Send -setObject:forKey: to the receiver, unless the value is nil, in which case send -removeObjectForKey:.
*/
- (void)setValue:(nullable ObjectType)value forKey:(NSString *)key;

@end
```
我们可以很清晰的看到，对于 NSMutableDictionary 如果我们调用了 `setValue:forKey:` 这个方法，有两种情况
* 1. 传值为 nil
  会调用 `-removeObjectForKey:` 这个方法，也就是移除这个 key 以及对应的 value
* 2. 传值不为 nil
  会调用 `-setObject:forKey:` 这个方法

我们再来看一下 `-setObject:forKey:` 这个方法
```objc
@interface NSMutableDictionary<KeyType, ObjectType> : NSDictionary<KeyType, ObjectType>

- (void)removeObjectForKey:(KeyType)aKey;
- (void)setObject:(ObjectType)anObject forKey:(KeyType <NSCopying>)aKey;

@end
```
我们可以看到它是 NSMutableDictionary 这个类自带的一个方法，有一个细节就是，`- (void)setObject:(ObjectType)anObject forKey:(KeyType <NSCopying>)aKey` 这个方法中的 key 可以是实现 NSCopying 协议的任意类型，比如说我们这样设置
```objc
NSMutableDictionary *dic = @{}.mutableCopy;
[dic setObject:@"mm" forKey:@2];
NSLog(@"%@--",dic[@2]);// 输出 mm--
```
也是完全没有问题的，但是 `- (void)setValue:(nullable ObjectType)value forKey:(NSString *)key` 这个方法就明确指定了 key 的类型必须是 NSString 类型。

还有一点需要注意的就是 `-setObject:forKey:` 这个方法 value 设置为 nil 是不可以的，会导致 crash，但是 `setValue:forKey:` 这个方法 value 设置为 nil 就可以，因为他会调用 `-removeObjectForKey:` 这个方法，上面也已经说过了。

综上，我们可以知道我们在使用 NSMutableDictionary 设置值的时候，最好使用`setValue:forKey:` 这个方法，因为已经容错 nil 这种情况。但是你如果非要用  `-setObject:forKey:` 这个方法，最好在分类中做好容错处理（当 value 为 nil 时）。