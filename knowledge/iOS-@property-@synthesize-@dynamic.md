# iOS 中的 `@property`、`@synthesize`、`@dynamic`
## @property
iOS6 之后出来的关键词，@property 关键字的实质就是声明属性以后，编译器会自动生成 getter、setter 方法以及一个_xxx属性。如下声明一个 `name` 属性
```objc
@interface MMStudent : NSObject

@property (nonatomic, copy) NSString *name;

@end
```
我们可以这样使用
```objc
MMStudent *stu = [[MMStudent alloc] init];
stu.name = @"mm";
```
而且在 `MMStudent` 内部我们可以直接使用 `_name` 这个变量（虽然我们自己没有定义过，这都是编译器帮助我们生成的）
## @synthesize
在 iOS6 之前，你 @property 声明了一个属性后，你在 `.m` 文件必须要用 @synthesize  或者 @dynamic 来实现，iOS6 之后声明属性以后默认会有 @synthesize ，所以就省略了，如下
```objc
@implementation MMStudent
@synthesize name = _name;

- (void)setName:(NSString *)name {
    _name = name;
}

- (NSString *)name {
    return  _name;
}
@end
```
相当于
```objc
@synthesize name = _name;

- (void)setName:(NSString *)name {
    _name = name;
}

- (NSString *)name {
    return  _name;
}
```
这一部分就省略了，当你自己写出来setter、getter 方法，就会覆盖编译器帮你生成的，以你的为主。

## @dynamic
@dynamic 相当于告诉编译器不要生成 setter、getter 方法，我自己会实现，编译的时候不要给我警告，此时编译时候没有问题，但是到最后运行程序的时候如果你自己还是没有实现 setter、getter 方法会报错。@synthesize 和 @dynamic 是对立的，同一属性两者互斥
```objc
@implementation MMStudent
@dynamic name;
@end

...
MMStudent *stu = [[MMStudent alloc] init];
stu.name = @"mm";
```
如上述代码执行就会报错，找不到 setter 方法
```objc
** -[MMStudent setName:]: unrecognized selector sent to instance 0x10043e050  ***
```
