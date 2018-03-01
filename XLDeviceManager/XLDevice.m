//
//  XLDevice.m
//  XLDevice
//
//  Created by 陈学明 on 2018/1/16.
//  Copyright © 2018年 sinaAging. All rights reserved.
//

#import "XLDevice.h"
#import <UIKit/UIKit.h>
#import <AdSupport/AdSupport.h>

#import <sys/utsname.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

@interface XLDevice ()
@property (nonatomic, copy) NSString *iphoneType;
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, copy) NSString *idfa;
@property (nonatomic, copy) NSString *idfv;
@property (nonatomic, copy) NSString *IP;
@property (nonatomic, copy) NSString *Mac;
@property (nonatomic, copy) NSString *phoneOs;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSString *systemVersion;
@property (nonatomic, copy) NSString *name;
@end

@implementation XLDevice

static XLDevice *device = nil;
+ (instancetype)shareDevice {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        device = [[XLDevice alloc]init];
    });
    return device;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        UIDevice *device = [UIDevice currentDevice];
        self.appVersion = infoDict[@"CFBundleShortVersionString"];
        self.systemVersion = device.systemVersion;
        self.idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        self.idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        self.deviceId = device.identifierForVendor.UUIDString;
        self.name = device.name;
        self.iphoneType = [self iPhoneType];
        self.phoneOs = device.systemName;
        self.Mac = [self getMacAddress];
    }
    return self;
}
-(NSString *)IP {
    _IP = [self getIPAddress:YES];
    return _IP;
}
- (NSString *)iPhoneType {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"iPhoneType.plist" ofType:nil];
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:path];
    if (dic[platform]) {
        return dic[platform];
    } else {
        return @"";
    }
}
- (NSString *)Mac {
    if (!_Mac) {
        _Mac = [self getMacAddress];
    }
    return _Mac;
}
//获取设备当前网络IP地址
- (NSString *)getIPAddress:(BOOL)preferIPv4 {
    NSArray *searchArray = preferIPv4 ?
    @[ /*IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6,*/ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ /*IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4,*/ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}
//获取所有相关IP信息
- (NSDictionary *)getIPAddresses {
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}
//获取mac地址
- (NSString *)getMacAddress {
    int mib[6];
    size_t len;
    char *buf;
    unsigned char *ptr;
    struct if_msghdr *ifm;
    struct sockaddr_dl *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error/n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1/n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!/n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    
    NSString *outstring = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    return [outstring uppercaseString];
}
@end

