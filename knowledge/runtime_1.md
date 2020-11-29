# 深入了解 iOS 中的 runtime（一）isa、objc_object、objc_class 

![](https://github.com/loveway/Knowledge/blob/master/image/runtime_isa.png?raw=true)
## isa
拿实例对象举例，我们都知道在 Objective-C 中，对象其实是一个结构体，在 64 位之前，对象的定义如下（以下源码分析基于 [objc4-781](https://opensource.apple.com//source/objc4/) ）
```c
/// An opaque type that represents an Objective-C class.
typedef struct objc_class *Class;

/// Represents an instance of a class.
struct objc_object {
    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;
};
```
可以看出是一个 Class 类型，由于是实例对象，结合 runtime 图示可以看出他的 isa 是指向类对象的（，从定义看，其实 isa 也就是一个指向 objc_class 类型的指针），而从 arm64 架构开始，苹果对 isa 做了优化，`objc_object` 结构体的定义如下
```c
struct objc_object {
private:
    isa_t isa;

public:

    // ISA() assumes this is NOT a tagged pointer object
    Class ISA();

    // rawISA() assumes this is NOT a tagged pointer object or a non pointer ISA
    Class rawISA();

    // getIsa() allows this to be a tagged pointer object
    Class getIsa();
    
    uintptr_t isaBits() const;
    
    ...
```
可以看出 isa 已经不是 Class 类型了，而是变成了 isa_t 这个类型，继续追溯看看 isa_t 这个类型
```c
union isa_t {
    isa_t() { }
    isa_t(uintptr_t value) : bits(value) { }

    Class cls;
    uintptr_t bits;
#if defined(ISA_BITFIELD)
    struct {
        ISA_BITFIELD;  // defined in isa.h
    };
#endif
};
```
可以看到 isa_t 是一个 `union` 共用体这么一个结构，其实是苹果把 isa 优化成了 union ，并且还使用了位域这种技术来存储更多的信息。
进入 `isa.h` 可以看到 `ISA_MASK`（掩码） 定义如下，
```c
#if SUPPORT_PACKED_ISA
// 真机 64 位
# if __arm64__
#   define ISA_MASK        0x0000000ffffffff8ULL
// 模拟器 64 位
# elif __x86_64__
#   define ISA_MASK        0x00007ffffffffff8ULL
# else
#   error unknown architecture for packed isa
# endif
```
在 64 位以后的 isa 取值
```c
objc_object::ISA() 
inline Class
objc_object::ISA()
{
    return (Class)(isa.bits & ISA_MASK);
}
```
所以其实在 `__arm64__` 和 `__x86_64__` 中，isa 并不是直接可以拿到各种信息的，而是通过 isa 中的 bits 对 ISA_MASK 进行位运算以后才可以获取（isa.bits & ISA_MASK），取到的 64 位结果信息如下，以 `__arm64__` 为例
```c
/**
 nonpointer 0: 代表普通指针，存储着 Class、Meta-Class 对象的内存地址
            1：代表优化过的，使用位域存储着更多的信息
 has_assoc  是否设置过（就算设置了又清空了这个值还是1）关联对象，如果没有释放时会更快
 has_cxx_dtor 是否有 c++ 的析构函数（.cxx_destruct），如果没有释放会更快
 shiftcls 存储着 Class、Meta-Class 对象的内存地址信息
 magic 用于调试时分辨对象是否未初始化
 weakly_referenced 是否有过（就算设置了又清空了这个值还是1）弱引用指向，如果没有释放时会更快
 deallocating 是否正在释放
 has_sidetable_rc 引用计数是否过大无法存在 isa 中，如果为 1 则引用计数存在一个叫 sideTable 的类属性中
 extra_rc 里面存储值时引用计数减 1（如果这个对象引用计数是 2，则 has_sidetable_rc = 1）
  
 */
#   define ISA_BITFIELD                                                      \
      uintptr_t nonpointer        : 1;                                       \
      uintptr_t has_assoc         : 1;                                       \
      uintptr_t has_cxx_dtor      : 1;                                       \
      uintptr_t shiftcls          : 33; /*MACH_VM_MAX_ADDRESS 0x1000000000*/ \
      uintptr_t magic             : 6;                                       \
      uintptr_t weakly_referenced : 1;                                       \
      uintptr_t deallocating      : 1;                                       \
      uintptr_t has_sidetable_rc  : 1;                                       \
      uintptr_t extra_rc          : 19
#   define RC_ONE   (1ULL<<45)
```
以上就是 isa 的所有信息，可以看出的是 isa 优化以后存储的信息更多了，不仅仅有类对象（元类对象）地址，还有 has_assoc、has_cxx_dtor 等更多的信息。

## objc_object
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

所以说到现在，一个 NSObject 对象在内存中占多少个字节相信你已经明白了。

Reference:
> [iOS KVC KVO 总结](http://coderlin.coding.me/2019/06/21/iOS-KVC-KVO/)
> 
