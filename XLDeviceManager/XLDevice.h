//
//  XLDevice.h
//  XLDevice
//
//  Created by 陈学明 on 2018/1/16.
//  Copyright © 2018年 sinaAging. All rights reserved.
//

#import <Foundation/Foundation.h>
/** 系统相关外部接口*/
@protocol XLDeviceDelegate <NSObject>
///**IP地址 0.0.0.0*/
@property (nonatomic, readonly) NSString *IP;
///**mac地址*/
@property (nonatomic, readonly) NSString *Mac;
///**iphone的名字 XXX的iPhone*/
@property (nonatomic, readonly) NSString *name;
///**广告标识 */
@property (nonatomic, readonly) NSString *idfa;
///**idfv */
@property (nonatomic, readonly) NSString *idfv;
///**渠道 AppStore*/
@property (nonatomic, readonly) NSString *channel;
///**系统名称 iOS*/
@property (nonatomic, readonly) NSString *phoneOs;
///**设备id*/
@property (nonatomic, readonly) NSString *deviceId;
///**设备商品名 iPhon 6s*/
@property (nonatomic, readonly) NSString *iphoneType;
///**app版本 1.0.0*/
@property (nonatomic, readonly) NSString *appVersion;
///**系统版本 11.2.0*/
@property (nonatomic, readonly) NSString *systemVersion;
///**单利对象*/
+ (instancetype)shareDevice;
@end
//系统相关 XLDeveice.framework
@interface XLDevice : NSObject <XLDeviceDelegate>
@end
