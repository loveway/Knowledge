# iOS 中对象的本质

## 一、对象的本质是什么
窥探 iOS 对象的本质，在 `main.m` 中我们有如下代码
```objc
#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSObject *p = [[NSObject alloc] init];
    }
    return 0;
}
```
再将 `main.m` 重写成 c++ 代码
```bash
xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m -o main-arm64.cpp
```
打开生成的 `main.cpp` 文件可以看到
```c
typedef struct objc_object NSObject;

struct NSObject_IMPL {
	Class isa;
};
```
由上我们得知，iOS 中对象的本质其实是一个 objc_object 类型的结构体，里面存有一个 isa 指针
## 二、一个 NSObject 对象占用多少内存
我们来看下面这个例子
```objc
// 定义一个 MMPerson 类
@interface MMPerson : NSObject
@end

@implementation MMPerson
@end
```
然后再 `main.m` 中
```objc
#import <Foundation/Foundation.h>
#import "MMPerson.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        MMPerson *p = [[MMPerson alloc] init];
        // 获取 MMPerson 这个类实例对象的成员变量所占用内存的大小
        NSLog(@"class_getInstanceSize is %zu", class_getInstanceSize([MMPerson class]));
        // 获取 p 指针指向内存的大小
        NSLog(@"malloc_size is %zu", malloc_size((__bridge const void *)(p)));
    }
    return 0;
}
```
输出是

![print](https://github.com/loveway/Knowledge/blob/master/image/runtime_1_print.png?raw=true)

那么问题来了，为什么两者输出的是不一样呢，p 这个对象分配出来以后到底是多少呢？带着这个疑问我们看一下 runtime 的源码，我们在 `objc-runtime-new.mm` 这个文件中看到 `_objc_rootAllocWithZone` 这个方法
```c
id
_objc_rootAllocWithZone(Class cls, malloc_zone_t *zone __unused)
{
    // allocWithZone under __OBJC2__ ignores the zone parameter
    return _class_createInstanceFromZone(cls, 0, nil,
                                    OBJECT_CONSTRUCT_CALL_BADALLOC);
}

```
然后在进入 `_class_createInstanceFromZone` 这个方法里面有一段
```objc
_class_createInstanceFromZone(Class cls, size_t extraBytes, void *zone,
                              int construct_flags = OBJECT_CONSTRUCT_NONE,
                              bool cxxConstruct = true,
                              size_t *outAllocatedSize = nil)
{
    ...
    
    size_t size;

    size = cls->instanceSize(extraBytes);
    if (outAllocatedSize) *outAllocatedSize = size;

    id obj;
    if (zone) {
        obj = (id)malloc_zone_calloc((malloc_zone_t *)zone, 1, size);
    } else {
        obj = (id)calloc(1, size);
    }
```
可以看到最终分配内存和这个 `size` 是有关系的，而这个 `size` 是通过 `cls->instanceSize(extraBytes)` 得到的，再去追踪 `instanceSize` 这个方法，如下
```c
    size_t instanceSize(size_t extraBytes) const {
        if (fastpath(cache.hasFastInstanceSize(extraBytes))) {
            return cache.fastInstanceSize(extraBytes);
        }

        size_t size = alignedInstanceSize() + extraBytes;
        // CF requires all objects be at least 16 bytes.
        if (size < 16) size = 16;
        return size;
    }
```
可以看到里面有一句 `if (size < 16) size = 16` ，也就是说系统规定的分配出来的对象的最小值是 16（注释也写了 *CF requires all objects be at least 16 bytes*），
所以说 malloc_size 方法会输出 16，但是其实 MMPerson 对象只占用了 8 个字节（因为他的实例对象 p 里面只有一个成员变量 isa，占用 8 个字节），MMPerson 实例对象的的内存分配如下

![MMPerson 实例对象的内存分配](https://github.com/loveway/Knowledge/blob/master/image/runtime_malloc.png?raw=true)

所以总结来说
* 在 64 位系统下，系统分配了 16 字节给 NSObject 对象（通过 malloc_size 函数获得）
* 但是实际上，NSObject 对象只占用了 8 个字节（ 也就是默认的 isa 指针占用的大小，通过 class_getInstanceSize 方法获得）

### 思考：将 MMPerson 分别添加一个、两个、三个 int 类型的成员变量，`class_getInstanceSize` 和 `malloc_size` 分别输出多少？

针对上面问题我们分别将 MMPerson 类添加一、二、三个成员变量
```objc
@interface MMPerson : NSObject
{
    @public
    int _age;// 1
    int _number;// 2
    int _number2;// 3
}
@end
```
`main.m` 如下
```objc
#import <Foundation/Foundation.h>
#import "MMPerson.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        MMPerson *p = [[MMPerson alloc] init];
        // 获取 MMPerson 这个类实例对象的成员变量所占用内存的大小
        NSLog(@"class_getInstanceSize is %zu", class_getInstanceSize([MMPerson class]));
        // 获取 p 指针指向内存的大小
        NSLog(@"malloc_size is %zu", malloc_size((__bridge const void *)(p)));
    }
    return 0;
}
```
最后打印如下

| MMPerson 变量数量（以 int 为例） | class_getInstanceSize 输出 | malloc_size 输出 |
| :---: | :---: | :---: |
|1| 16 | 16 |
|2| 16 | 16 |
|3| 24| 32|

为了探索为什么会出现上诉结果，我们以 MMPerson 里面添加 `_age`、`_number` 两个成员变量为例，将 main.m 转成 c++ 文件来窥探下 MMPerson 内部结构，输入以下命令
```bash
xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m -o main-arm64.cpp
```
可以在 30000 多行的 c++ 代码中找到
```c
struct NSObject_IMPL {
	Class isa;
};

...
struct MMPerson_IMPL {
	struct NSObject_IMPL NSObject_IVARS;
	int _age;
	int _number;
};
```
也就相当于 MMPerson 的底层实现是
```C
struct MMPerson_IMPL {
	Class isa;
	int _age;
	int _number;
};
```
也就是 MMPerson 的实例对象的内存分配如下图

这样我们就理解了，原来底层 MMPerson 对象里面存放着 isa、_age、_number，isa 占用八个字节，两个 int 分别占用四个字节，所以当 MMPerson 中存在两个成员变量（int）时候，`class_getInstanceSize` 输出 16，`malloc_size` 输出 16，但是如果只有一个int 成员变量时候 `class_getInstanceSize` 应该输出 12 啊，三个 int 成员变量时候也应该输出 20 啊，为啥会输出 16 和 24 呢?

其实根本原因是因为 **内存对齐**！也就是说，MMPerson 对象的本质是一个结构体，结构体自身存在着内存对齐，以其中最大的成员为基准，以 MMPerson 添加一个 `_age` 成员变量为例，此时 isa 占用 8 个字节，`_age` 本来只需要占用 4 个字节，但是由于对齐为最大 8 的倍数， 所以 `class_getInstanceSize` 输出 16。而同样，iOS 系统分配也存在着内存对齐，原则是 16 的倍数，所以当添加三个成员变量的时候，`malloc_size` 输出是 32。

## 三、一个 OC 的实例对象中都有什么？
经过上面的分析，我们可以得出，OC 的对象底层其实就是一个结构体，里面存着 isa 和一些其他的成员变量。

