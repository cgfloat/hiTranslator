//
//  SMPing.m
//  SuperMasterVPN
//
//  Created by supermaster on 2021/8/9.
//

#import "SMPing.h"

@implementation SMPingItem
@end

@implementation SMPing
+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static SMPing * __instance = nil;
    dispatch_once(&onceToken, ^{
        __instance = [[SMPing alloc] init];
    });
    return __instance;
}

- (instancetype)initWithHost:(NSString *)host count:(NSInteger)count pingCallback:(void(^)(SMPingItem *item))callback {
    if (self = [super init]) {
        self.hostName = host;
        self.count = count;
        self.pingCallback = callback;
        self.pinger = [[SimplePing alloc] initWithHostName:host];
        self.pinger.addressStyle = SimplePingAddressStyleAny;
        self.pinger.delegate = self;
        [self.pinger start];
    }
    return self;
}

+ (instancetype)startPingWithHost:(NSString *)host count:(NSInteger)count pingCallback:(void(^)(SMPingItem *item))callback {
    return [[self alloc] initWithHost:host count:count pingCallback:callback];
}

- (void)clean:(enum SMPingStatus)status {
    SMPingItem *item = [[SMPingItem alloc] init];
    item.hostName = self.hostName;
    item.status = status;
    if (self.pingCallback && SMPing.shared.queueCount) {
        self.pingCallback(item);
    }
    [self.pinger stop];
    self.pinger = nil;
    [self.sendTimer invalidate];
    self.sendTimer = nil;
    [self removePacketTimer];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pingTimeout) object:nil];
    self.hostName = nil;
    self.startDate = nil;
    self.pingCallback = nil;
}

- (void)sendPing {
    if (self.count < 1) {
        [self stopPing];
        return;
    }
    self.count -= 1;
    self.startDate = NSDate.date;
    [self.pinger sendPingWithData:nil];
    [self performSelector:@selector(pingTimeout) withObject:nil afterDelay:2];
}

- (void)stopPing {
    NSLog(@"[IP] Ping %@ STOP", self.hostName);
    [self clean: finished];
}

- (void)pingTimeout {
    NSLog(@"[IP] Ping %@ TIMEOUT", self.hostName);
    [self clean:timeout];
}

- (void)pingFail {
    NSLog(@"[IP] Ping %@ FAIL", self.hostName);
    [self clean:error];
}

- (void)addSendPacketTimer {
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.sendPacketTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(self.sendPacketTimer, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC) , DISPATCH_TIME_FOREVER, 0);
    dispatch_source_set_event_handler(self.sendPacketTimer, ^{
        [self clean:timeout];
    });
    dispatch_resume(self.sendPacketTimer);
}

- (void)removePacketTimer {
    if (self.sendPacketTimer) {
        dispatch_source_cancel(self.sendPacketTimer);
    }
}

#pragma mark - SimpingDelegate
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
    NSLog(@"[IP] Start Ping %@", self.hostName);
    [self sendPing];
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(pinger) userInfo:nil repeats:YES];
    SMPingItem *item = SMPingItem.new;
    item.hostName = self.hostName;
    item.status = start;
    if (self.pingCallback) {
        self.pingCallback(item);
    }
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error {
    NSLog(@"[IP] Ping %@ Error:%@", self.hostName, error.localizedDescription);
    [self pingFail];
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pingTimeout) object:nil];
    NSLog(@"[IP] Ping %@ %hu send packet success", self.hostName, sequenceNumber);
    [self addSendPacketTimer];
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pingTimeout) object:nil];
    NSLog(@"[IP] send packet failed: %@ Error:%@", self.hostName, error.localizedDescription);
    [self clean:failToSendPacket];
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pingTimeout) object:nil];
    [self removePacketTimer];
    NSTimeInterval time = fabs(self.startDate.timeIntervalSinceNow * 1000);
    NSLog(@"[IP] %@ %hu received, size = %ld, time = %.2f", self.hostName,sequenceNumber, (unsigned long)packet.length, time > 999.9 ? 9999 : time);
    SMPingItem *item = SMPingItem.new;
    item.hostName = self.hostName;
    item.status = receivePacket;
    item.singleTime = time;
    if (self.pingCallback) {
        self.pingCallback(item);
    }
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pingTimeout) object:nil];
//    NSLog(@"[IP] receive UNEXPECTED packet");
}

@end
