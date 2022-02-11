//
//  SMPing.h
//  SuperMasterVPN
//
//  Created by supermaster on 2021/8/9.
//

#import <Foundation/Foundation.h>
#import "SimplePing.h"

NS_ASSUME_NONNULL_BEGIN
enum SMPingStatus {
    start,
    failToSendPacket,
    receivePacket,
    receiveUnpectedPacket,
    timeout,
    error,
    finished
};

#ifdef DEBUG

#define NSLog(...) NSLog(__VA_ARGS__)

#else

#define NSLog(...)

#endif

@interface SMPingItem : NSObject
@property (nonatomic, strong) NSString *hostName;
@property (nonatomic, assign) double singleTime;
@property (nonatomic, assign) enum SMPingStatus status;
@end

@interface SMPing : NSObject <SimplePingDelegate>
@property (nonatomic, strong) NSString * _Nullable hostName;
@property (nonatomic, strong) SimplePing  * _Nullable pinger;
@property (nonatomic, strong) NSTimer * _Nullable sendTimer;
@property (nonatomic, strong) NSDate * _Nullable startDate;
@property (nonatomic, strong) dispatch_source_t _Nullable sendPacketTimer;
@property (nonatomic, assign) NSInteger queueCount;


@property (nonatomic, copy) void (^ _Nullable pingCallback)(SMPingItem *item);
@property (nonatomic, assign) NSInteger count;
+ (instancetype)shared;
+ (instancetype)startPingWithHost:(NSString * _Nullable )host count:(NSInteger)count pingCallback:(void(^ _Nullable)(SMPingItem *item))callback ;
@end

NS_ASSUME_NONNULL_END
