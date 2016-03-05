//
//  HomeViewController.m
//  66RentCar
//
//  Created by dyage on 15/12/22.
//  Copyright (c) 2015年 sole. All rights reserved.
//

#import "HomeViewController.h"
#import "AppDelegate.h"
#import "YCXMenu.h"
#import "LeftHomeController.h"
#import "ScanBarCodeViewController.h"
#import "RecentOrdersViewController.h"
#import "CourierCollectionViewController.h"
#import "SearchExpressViewController.h"
#import "LoginHomeViewController.h"
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>
#import <BaiduMapAPI_Location/BMKLocationService.h>
#import <BaiduMapAPI_Search/BMKSearchBase.h>
#import <QuartzCore/QuartzCore.h>
#import "UIView+Extend.h"


@interface HomeViewController () <UINavigationBarDelegate,UIActionSheetDelegate,BMKLocationServiceDelegate,BMKMapViewDelegate,BMKGeoCodeSearchDelegate>

@property (nonatomic,strong) NSMutableArray *items;

@property (nonatomic,strong) UIWindow *leftWindow;

@property (nonatomic,strong) UIView *leftView;

@property (nonatomic,strong) BMKLocationService *locationService;

@property (nonatomic,strong) BMKSearchBase *BDSearchBase;

@property (nonatomic,strong) CLLocation *currentLocation;

@property (nonatomic,strong) UIView *chooseExpressMaskView;

@property (nonatomic,strong) UIButton *choooseExpressTypeButton;

@property (nonatomic,strong) NSMutableArray *expressInfoArray;

@property (nonatomic,strong) BMKGeoCodeSearch *geoSearch;

@property (nonatomic,strong)BMKUserLocation *userLocationDetail;

@property (nonatomic,strong) BMKMapView *BDMapView;

@property (nonatomic,strong) UIButton *expressMoreButton;
@end


@implementation HomeViewController

#pragma mark getter/setter

-(NSMutableArray *)items {
    if(!_items) {
        _items = [NSMutableArray array];
        _items = [@[
                    [YCXMenuItem menuItem:@" 扫一扫"
                                    image:[UIImage imageNamed:@"home_iconfont-saoyisao"]
                                      tag:100
                                 userInfo:@{@"title":@"Menu"}],
                    [YCXMenuItem menuItem:@" 最近订单"
                                    image:[UIImage imageNamed:@"home_iconfont-dingdan"]
                                      tag:101
                                 userInfo:@{@"title":@"Menu"}],
                    [YCXMenuItem menuItem:@" 收藏快递员"
                                    image:[UIImage imageNamed:@"home_iconfont-shoucang"]
                                      tag:102
                                 userInfo:@{@"title":@"Menu"}]
                    
                    ] mutableCopy];
    }
    return _items;
}

/**
 *  地图设置
 *
 *  @return 返回基础地图类
 */

/**
 *  快递名字数组
 *
 *  @return 返回数组内容
 */
-(NSMutableArray *)expressInfoArray {
    if (!_expressInfoArray) {
        _expressInfoArray = [NSMutableArray array];
        _expressInfoArray = [@[
                               @"顺丰",
                               @"韵达",
                               @"申通",
                               @"EMS",
                               @"中通",
                               @"德邦",
                               
                               ] mutableCopy];
    }
    return _expressInfoArray;
}

-(BMKGeoCodeSearch *)geoSearch {
    if (!_geoSearch) {
        _geoSearch = [[BMKGeoCodeSearch alloc]init];
    }
    return _geoSearch;
}
-(UIView *)chooseExpressMaskView {
    if (!_chooseExpressMaskView) {
        _chooseExpressMaskView = [[UIView alloc]initWithFrame:CGRectMake(0, SCRE_HEIGHT - 90, SCRE_WIDTH * 2, 40)];
        _chooseExpressMaskView.backgroundColor = [UIColor whiteColor];
    }
    return _chooseExpressMaskView;
}

-(BMKUserLocation *)userLocationDetail {
    if (!_userLocationDetail) {
        _userLocationDetail = [[BMKUserLocation alloc]init];
    }
    return _userLocationDetail;
}

- (BMKMapView *)BDMapView
{
    if (!_BDMapView) {
        _BDMapView = [[BMKMapView alloc] initWithFrame:self.view.bounds];
        _BDMapView.zoomLevel = 19;
        _BDMapView.showMapScaleBar = YES;
        [self.view addSubview:_BDMapView];
    }
    return _BDMapView;
}

#pragma mark -系统加载项
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initNavigationBar];
    self.locationService = [[BMKLocationService alloc]init];
    _locationService.delegate = self;
    [_locationService startUserLocationService];
    
    self.BDMapView.userTrackingMode = BMKUserTrackingModeFollowWithHeading;
    _BDMapView.showsUserLocation = YES;
    _BDMapView.delegate = self;
    
    
    [self.view addSubview:self.chooseExpressMaskView];
    [self initBottomView];
    [self initChoooseExpressTypeButton];
    [self reGeoAction];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.BDMapView.delegate = self;
    self.geoSearch.delegate = self;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.BDMapView.delegate = nil;
    self.geoSearch.delegate = nil;
    NSLog(@"___________%s",__func__);

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if (viewController == self) {
        self.navigationController.navigationBar.alpha = 0.300;
    }else{
        self.navigationController.navigationBar.alpha =1;
    }
}
#pragma mark 初始化- init
/**
 *  初始化navigationBar
 */
//初始化NAVIGATION BAR
-(void)initNavigationBar {
    self.title = @"曹操快递";
    UIButton *personalCenter = [[UIButton alloc]initWithFrame:CGRectMake(20, 0, 30, 40)];
    [personalCenter setImage:[UIImage imageNamed:@"home_navigation_left"] forState:UIControlStateNormal];
    [personalCenter addTarget:self action:@selector(pushPerCenter) forControlEvents:UIControlEventTouchDown];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:personalCenter];
    
    UIButton *rightItemButton = [[UIButton alloc]initWithFrame:CGRectMake(20, 0, 20, 40)];
    [rightItemButton setImage:[UIImage imageNamed:@"home_navigation_right"] forState:UIControlStateNormal];
    rightItemButton.titleLabel.textAlignment = NSTextAlignmentRight;
    [rightItemButton addTarget:self action:@selector(rightBarButtonItemAction) forControlEvents:UIControlEventTouchDown];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:rightItemButton];
}

//初始化底部Button
- (void)initBottomView {
    UIView *bottomView = [[UIView alloc]initWithFrame:CGRectMake(0, SCRE_HEIGHT - 50, SCRE_WIDTH, 50)];
    [self.view addSubview:bottomView];
    //画线
    UIBezierPath *straightLineBe = [UIBezierPath bezierPath];
    [straightLineBe moveToPoint:CGPointMake(0, 0)];
    [straightLineBe addLineToPoint:CGPointMake(SCRE_WIDTH, 0)];
    
    CAShapeLayer *shaperLayer = [[CAShapeLayer alloc]init];
    shaperLayer.strokeColor = [[UIColor blackColor]CGColor];
    shaperLayer.lineWidth = 0.2f;
    shaperLayer.path = straightLineBe.CGPath;
    [bottomView.layer addSublayer:shaperLayer];
    
    
    UIButton *callCourierButton = [[UIButton alloc]initWithFrame:CGRectMake(20, 5, SCRE_WIDTH - 40, 40)];
    [callCourierButton setTitle:@"呼叫快递" forState:UIControlStateNormal];
    [callCourierButton setBackgroundColor:[UIColor colorWithRed:253.0/255.0 green:139.0/255.0 blue:23.0/255 alpha:1]];
    callCourierButton.layer.cornerRadius = 5.0;
    callCourierButton.layer.masksToBounds = YES;
    [callCourierButton setTintColor:[UIColor whiteColor]];
    [callCourierButton addTarget:self action:@selector(callCourierAction) forControlEvents:UIControlEventTouchDown];
    bottomView.backgroundColor = [UIColor whiteColor];
    [bottomView addSubview:callCourierButton];
    
}
//初始化底部快递按钮
- (void)initChoooseExpressTypeButton {
    
    for (int i = 0; i < 5; i++) {
        self.choooseExpressTypeButton = [[UIButton alloc]init];
        _choooseExpressTypeButton.frame = CGRectMake( 15 * (i + 1) + i * (SCRE_WIDTH - 120)/5, 10, (SCRE_WIDTH - 120)/5, 20);
        _choooseExpressTypeButton.backgroundColor = [UIColor whiteColor];
        _choooseExpressTypeButton.layer.cornerRadius = 5;
        _choooseExpressTypeButton.layer.masksToBounds = YES;
        _choooseExpressTypeButton.layer.borderWidth = 0.5;
        _choooseExpressTypeButton.layer.borderColor = [[UIColor colorWithWhite:0.3 alpha:0.8]CGColor];
        _choooseExpressTypeButton.tag = 10 + i;
        _choooseExpressTypeButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_choooseExpressTypeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

        [_choooseExpressTypeButton setTitle:self.expressInfoArray[i] forState:UIControlStateNormal];
        [_choooseExpressTypeButton addTarget:self action:@selector(chooseExpressAction:) forControlEvents:UIControlEventTouchDown];
        _chooseExpressMaskView.backgroundColor = [UIColor greenColor];
        [_chooseExpressMaskView addSubview:_choooseExpressTypeButton];
    }
    self.expressMoreButton = [[UIButton alloc]initWithFrame:CGRectMake(SCRE_WIDTH - 30, 10, 20, 20)];
    _expressMoreButton.backgroundColor = [UIColor redColor];
    [_expressMoreButton addTarget:self action:@selector(expressMoreAction) forControlEvents:UIControlEventTouchDown];
    [_chooseExpressMaskView addSubview:_expressMoreButton];
    
    for (int i = 0; i < 5; i++) {
       
        _choooseExpressTypeButton.frame = CGRectMake( 15 * (i + 1) + i * (SCRE_WIDTH - 120)/5 + SCRE_WIDTH, 10, (SCRE_WIDTH - 120)/5, 20);
        _choooseExpressTypeButton.backgroundColor = [UIColor whiteColor];
        _choooseExpressTypeButton.layer.cornerRadius = 5;
        _choooseExpressTypeButton.layer.masksToBounds = YES;
        _choooseExpressTypeButton.layer.borderWidth = 0.5;
        _choooseExpressTypeButton.layer.borderColor = [[UIColor colorWithWhite:0.3 alpha:0.8]CGColor];
        _choooseExpressTypeButton.tag = 20 + i;
        _choooseExpressTypeButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_choooseExpressTypeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        [_choooseExpressTypeButton setTitle:self.expressInfoArray[i] forState:UIControlStateNormal];
        [_choooseExpressTypeButton addTarget:self action:@selector(chooseExpressAction:) forControlEvents:UIControlEventTouchDown];
        _chooseExpressMaskView.backgroundColor = [UIColor greenColor];
        [_chooseExpressMaskView addSubview:_choooseExpressTypeButton];
    }

    
}

#pragma mark function自定义方法
//发起搜索请求
- (void)reGeoAction {
    if (_currentLocation)
    {
        BMKReverseGeoCodeOption *geoRequest = [[BMKReverseGeoCodeOption alloc] init];
        geoRequest.reverseGeoPoint = _currentLocation.coordinate;
        [self.geoSearch reverseGeoCode:geoRequest];
    }
}


#pragma mark --action
//左按钮navigationitem点击
-(void)rightBarButtonItemAction {
    [YCXMenu setTintColor:[UIColor whiteColor]];
    if ([YCXMenu isShow]){
        [YCXMenu dismissMenu];
    } else {
        [YCXMenu showMenuInView:self.view fromRect:CGRectMake(self.view.frame.size.width - 50, 64, 50, 0) menuItems:self.items selected:^(NSInteger index, YCXMenuItem *item) {
            if (item.tag == 100) {
                
                [self.navigationController pushViewController:[[SearchExpressViewController alloc]init] animated:YES];
            } else if(item.tag == 101) {
                [self.navigationController pushViewController:[[RecentOrdersViewController alloc]init] animated:YES];
            } else if (item.tag == 102) {
                [self.navigationController pushViewController:[[CourierCollectionViewController alloc]init] animated:YES];
            }
        }];
    }
}

//左抽屉动画
-(void)pushPerCenter {
    
//    LoginHomeViewController *loginHome = [[LoginHomeViewController alloc]init];
//    
//    [self.navigationController pushViewController:loginHome animated:YES];
    
    self.leftWindow = [[UIWindow alloc]initWithFrame:CGRectMake(-SCRE_WIDTH, 0, SCRE_WIDTH * 4/5, SCRE_HEIGHT)];
    
    _leftWindow.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    LeftHomeController *leftVC = [[LeftHomeController alloc]init];
    _leftWindow.rootViewController = leftVC;
    
    [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.3 initialSpringVelocity:0.6 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _leftWindow.frame = CGRectMake(0, 0, SCRE_WIDTH, SCRE_HEIGHT);
    } completion:nil];
    
    
    [_leftWindow makeKeyAndVisible];
    
}

//呼叫快递action
- (void)callCourierAction {
    
}

//chooseExpressAction 查询附近的快递点。并在地图上显示
- (void)chooseExpressAction:(UIButton *)sender {
    NSLog(@"%ld",(long)sender.tag);
    
}

//更多快递
- (void)expressMoreAction {
    [UIView animateWithDuration:0.7 animations:^{
        _chooseExpressMaskView.x -= SCRE_WIDTH;
    }];
}

#pragma mark BMKLocationServiceDelegate

- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation
{
    if (self.userLocationDetail.subtitle) {
        userLocation.title = _userLocationDetail.title;
        userLocation.subtitle = _userLocationDetail.subtitle;
    }
    [_BDMapView updateLocationData:userLocation];
    
}
//处理位置坐标更新
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    
    _BDMapView.centerCoordinate = userLocation.location.coordinate;
    _currentLocation = userLocation.location;
    if (self.userLocationDetail.subtitle) {
        userLocation.title = _userLocationDetail.title;
        userLocation.subtitle = _userLocationDetail.subtitle;
        [_BDMapView updateLocationData:userLocation];
    }
    NSLog(@"++++++++++%@",self.userLocationDetail.subtitle );
    
}

#pragma mark  BMKMapViewDelegate
-(BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation {
    if ([annotation isKindOfClass:[BMKPointAnnotation class]])
    {
        static NSString *pointReuseIndentifier = @"pointReuseIndentifier";
        BMKAnnotationView *annotationView = (BMKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndentifier];
        if (annotationView == nil)
        {
            annotationView = [[BMKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndentifier];
        }
        annotationView.image = [UIImage imageNamed:@"restaurant"];
        // 设置中心点偏移，使得标注底部中间点成为经纬度对应点
        annotationView.centerOffset = CGPointMake(0, -18);
        annotationView.canShowCallout= NO;       //设置气泡可以弹出，默认为NO
        annotationView.draggable = YES;        //设置标注可以拖动，默认为NO
        return annotationView;
    }
    return nil;
}

#warning @"wait slove with this"
-(void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view {
    
    
//    if([view.annotation isKindOfClass:[BMKUserLocation class]]) {
        [self reGeoAction];
//    }
    
}



- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (result) {
        NSLog(@"%@ - %@", result.address, result.addressDetail.streetNumber);
        self.userLocationDetail.title = result.addressDetail.city;
        self.userLocationDetail.subtitle = result.address;
    }else{
    
    }
    NSLog(@"%@",self.userLocationDetail.subtitle);
}


@end