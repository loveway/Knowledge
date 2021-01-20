# iOS 实现删除链表中的倒数第 k 个节点
之前写算法都是用 Java 实现，现在尝试用 Objective-C 来实现以下这个算法，首先定义链表节点如下
```objc
#import <Foundation/Foundation.h>


@interface ListNode : NSObject

@property (nonatomic, assign) int value;
@property (nonatomic, strong) ListNode *next;
- (instancetype)initWithValue:(int)value next:(ListNode *)next;

@end

...

#import "ListNode.h"

@implementation ListNode

- (instancetype)initWithValue:(int)value next:(ListNode *)next {
    if (self == [super init]) {
        self.value = value;
        self.next = next;
    }
    return self;
}

// 重写打印信息
- (NSString *)description {
    [super description];
    NSString *des = @"";
    ListNode *tmpNode = self;
    while (tmpNode != nil) {
        des = [des stringByAppendingString:[NSString stringWithFormat:@"%@%d", des.length == 0 ? @"" : @"->", tmpNode.value]];
        tmpNode = tmpNode.next;
    }
    return des;
}

@end
```
可以看到定义的 .h 和 .m 文件还是相对简单的，然后我们来实现具体的算法

```objc
- (void)viewDidLoad {
    [super viewDidLoad];
    
    ListNode *l5 = [[ListNode alloc] initWithValue:5 next:nil];
    ListNode *l4 = [[ListNode alloc] initWithValue:4 next:l5];
    ListNode *l3 = [[ListNode alloc] initWithValue:3 next:l4];
    ListNode *l2 = [[ListNode alloc] initWithValue:2 next:l3];
    ListNode *l1 = [[ListNode alloc] initWithValue:1 next:l2];
    ListNode *root = [[ListNode alloc] initWithValue:0 next:l1];
    // 删除倒数第二个，也就是 l4 这个节点
    [self deleteNode:root index:2];

}

- (void)deleteNode:(ListNode *)root index:(int)index {
    if (root == nil || index <= 0) {
        return;
    }
    ListNode *slow = root;
    ListNode *fast = root;
    while (index > 0) {
        fast = fast.next;
        if (fast == nil) {
            NSLog(@"index 超出链表长度");
            return;
        }
        index--;
    }
    while (fast.next != nil) {
        slow = slow.next;
        fast = fast.next;
    }
    slow.next = slow.next.next;
    NSLog(@"%@", root);
}
```

打印结果

```objc
2021-01-20 14:46:44.605070+0800 MM_test[22799:202914] 0->1->2->3->5
```
