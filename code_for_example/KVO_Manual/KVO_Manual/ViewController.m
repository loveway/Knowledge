//
//  ViewController.m
//  KVO_Manual
//
//  Created by HenryCheng on 2020/3/3.
//  Copyright © 2020 igancao. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import "NSObject+MMKVO.h"

@interface ViewController ()

@property (nonatomic, strong) Person *p;


@end

@implementation ViewController


- (void)viewDidLoad {
    
    _p = [[Person alloc] init];
    [_p mm_addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@", change);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {

    _p.name = @"mm";
}

- (void)dealloc {
    //使用自定义 KVO 这里不移除观察者也没关系，因为里面有个 if (observer) 判断，如果 observer 消失将不会发消息
    [self removeObserver:self forKeyPath:@"name"];
}

@end
