//
//  SLTableViewController.m
//  DarkMode
//
//  Created by wsl on 2020/6/9.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLTableViewController.h"

@interface SLTableViewController ()<UIScrollViewDelegate>
{
    UITableView *tableView;
}

@property (nonatomic, strong) UIScrollView *scrollView;
///复用池
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSHashTable<UIView *> *> *reusablePool;
/// 每一行的坐标位置
@property (nonatomic, strong) NSMutableArray <NSValue *>*frameArray;

///记录最后一次的偏移量，用来判断滑动方向
@property (nonatomic, assign) CGFloat lastContentOffsetY;
///上边即将展示的索引
@property (nonatomic, assign) NSInteger willDisplayIndexUp;
///下边即将展示的索引
@property (nonatomic, assign) NSInteger willDisplayIndexDown;

@end

@implementation SLTableViewController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.scrollView];
    [self reloadData];
}

#pragma mark - Data

#pragma mark - Getter
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _scrollView.delegate = self;
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
    }
    return _scrollView;
}
- (NSMutableDictionary *)reusablePool {
    if (!_reusablePool) {
        _reusablePool = [NSMutableDictionary dictionary];
    }
    return _reusablePool;;
}
- (NSMutableArray *)frameArray {
    if (!_frameArray) {
        _frameArray = [NSMutableArray array];
    }
    return _frameArray;
}

#pragma mark - Setter
- (void)setWillDisplayIndexUp:(NSInteger)willDisplayIndexUp{
    _willDisplayIndexUp = willDisplayIndexUp;
    _willDisplayIndexUp >= 0 ? _willDisplayIndexUp : -1;
}
- (void)setWillDisplayIndexDown:(NSInteger)willDisplayIndexDown {
    NSInteger count = [self numberOfRowsInScrollView:self.scrollView];
    _willDisplayIndexDown = willDisplayIndexDown;
    _willDisplayIndexDown < count ? _willDisplayIndexDown : count;
}


#pragma mark - Help Methods
///刷新数据
- (void)reloadData {
    //清空布局信息
    [self.frameArray removeAllObjects];
    self.willDisplayIndexUp = -1;
    self.willDisplayIndexDown = 0;
    
    //数据源个数
    NSInteger count = [self numberOfRowsInScrollView:self.scrollView];
    CGFloat y = 0;
    //获取每一行的布局信息
    for (int i = 0; i < count; i++) {
        CGFloat cellHeight = [self scrollView:self.scrollView heightForRowAtIndex:i];
        CGRect rect = CGRectMake(0, y, self.scrollView.sl_width, cellHeight);
        [self.frameArray addObject:[NSValue valueWithCGRect:rect]];
        
        if (rect.origin.y + rect.size.height < self.scrollView.contentOffset.y) {
            self.willDisplayIndexUp = i;
        }
        
        //按需加载 只加载坐标位置是在当前窗口显示的视图
        if (rect.origin.y + rect.size.height >= self.scrollView.contentOffset.y && rect.origin.y <= self.scrollView.contentOffset.y + self.scrollView.sl_height) {
            UIView *view = [self scrollView:self.scrollView cellForRowAtIndex:i];
            view.frame = rect;
            [self.scrollView addSubview:view];
        }
        
        if (rect.origin.y > self.scrollView.contentOffset.y + self.scrollView.sl_height && self.willDisplayIndexDown == 0) {
            self.willDisplayIndexDown = i;
        }
        
        //下一行的起始纵坐标
        y += cellHeight;
        
        //最后 确定了内容大小
        if (i == count - 1) {
            self.scrollView.contentSize = CGSizeMake(self.scrollView.sl_width, y);
        }
    }
    
}
//当前可见的cell
- (NSArray *)visibleCells {
    return self.scrollView.subviews;
}
//当前可见cell的索引 其实绘制cell的时候就可以先保存可见的索引，不用每次遍历查询
- (NSArray *)indexForVisibleRows {
    NSMutableArray *indexs = [NSMutableArray array];
    for (int i = 0; i < self.frameArray.count; i++) {
        CGRect rect = [self.frameArray[i] CGRectValue];
        if (rect.origin.y + rect.size.height >= self.scrollView.contentOffset.y && rect.origin.y <= self.scrollView.contentOffset.y + self.scrollView.sl_height) {
            [indexs addObject:@(i)];
        }
    }
    return indexs;
}
//即将显示cell  YES上  NO下
- (void)willDisplayCellWithDirection:(BOOL)up {
    if(up) {
        if (_willDisplayIndexUp < 0) return;
        NSLog(@"上");
        CGRect rect = [self.frameArray[self.willDisplayIndexUp] CGRectValue];
        //按需加载 只加载坐标位置是在当前窗口显示的视图
        if (rect.origin.y + rect.size.height >= self.scrollView.contentOffset.y && rect.origin.y <= self.scrollView.contentOffset.y + self.scrollView.sl_height) {
            UIView *view = [self scrollView:self.scrollView cellForRowAtIndex:self.willDisplayIndexUp];
            view.frame = rect;
            [self.scrollView addSubview:view];
            self.willDisplayIndexUp -=1;
        }
    }else {
        NSInteger count = [self numberOfRowsInScrollView:self.scrollView];
        if (_willDisplayIndexDown == count) return;
        NSLog(@"下");
        CGRect rect = [self.frameArray[self.willDisplayIndexDown] CGRectValue];
        //按需加载 只加载坐标位置是在当前窗口显示的视图
        if (rect.origin.y + rect.size.height >= self.scrollView.contentOffset.y && rect.origin.y <= self.scrollView.contentOffset.y + self.scrollView.sl_height) {
            UIView *view = [self scrollView:self.scrollView cellForRowAtIndex:self.willDisplayIndexDown];
            view.frame = rect;
            [self.scrollView addSubview:view];
            self.willDisplayIndexDown +=1;
        }
    }
}

///根据cellID去复用池reusablePool取可重用的view，如果没有，返回nil
- (UIView *)dequeueReusableCellWithIdentifier:(nonnull NSString *)cellID {
    
    
    
    return nil;
}
///注册样式
- (void)registerClass:(Class)class forCellReuseIdentifier:(NSString *)cellID {
    self.reusablePool[cellID] = [NSHashTable weakObjectsHashTable];
}
///行数
- (NSInteger)numberOfRowsInScrollView:(UIScrollView *)scrollView {
    return 30;
}
///行高
- (CGFloat)scrollView:(UIScrollView *)scrollView heightForRowAtIndex:(NSInteger)index {
    return 100;
}
///行内容
- (UIView *)scrollView:(UIScrollView *)scrollView cellForRowAtIndex:(NSInteger)index{
    UILabel *label = [UILabel new];
    label.backgroundColor = SL_UIColorFromRandomColor;
    label.text = [NSString stringWithFormat:@"第 %ld 个",(long)index];
    return label;
}
///点击行
- (void)scrollView:(UIScrollView *)scrollView didSelectRowAtIndex:(NSInteger)index {
    
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(scrollView.contentOffset.y > self.lastContentOffsetY) {
        [self willDisplayCellWithDirection:NO];
    }else {
        [self willDisplayCellWithDirection:YES];
    }
    self.lastContentOffsetY = scrollView.contentOffset.y;
}

@end
