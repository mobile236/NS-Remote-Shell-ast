//
//  NSRemoteEvent.m
//  
//
//  Created by Lakr Aream on 2022/2/5.
//

// TS: Thread Safe

#import "TSEventLoop.h"

@interface TSEventLoop () 

@property (nonatomic, nonnull, strong) NSThread *associatedThread;
@property (nonatomic, nonnull, strong) NSRunLoop *associatedRunLoop;
@property (nonatomic, nonnull, strong) NSTimer *associatedTimer;
@property (nonatomic, nonnull, strong) NSPort *associatedPort;
@property (nonatomic, nullable, weak) NSRemoteShell *parent;

@end

@implementation TSEventLoop

- (instancetype)initWithParent:(__weak NSRemoteShell*)parent {
    if (self = [super init]) {
        _parent = parent;
        _associatedThread = [[NSThread alloc] initWithTarget:self
                                                    selector:@selector(associatedThreadHandler)
                                                      object:NULL];
        NSString *threadName = [[NSString alloc] initWithFormat:@"wiki.qaq.shell.%p", parent];
        [_associatedThread setName:threadName];
        NSLog(@"opening thread %@", threadName);
        [_associatedThread start];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%@ object at %p deallocating", [self className], self);
    [self destroyLoop];
}

- (void)explicitRequestHandle {
    [self.associatedPort sendBeforeDate:[[NSDate alloc] init]
                             components:NULL
                                   from:NULL
                               reserved:NO];
}

- (void)associatedThreadHandler {
    self.associatedRunLoop = [NSRunLoop currentRunLoop];
    
    self.associatedPort = [[NSPort alloc] init];
    self.associatedPort.delegate = self;
    [self.associatedRunLoop addPort:self.associatedPort forMode:NSRunLoopCommonModes];
    
    self.associatedTimer = [[NSTimer alloc] initWithFireDate: [[NSDate alloc] init]
                            interval:0.2
                            target:self selector:@selector(associatedLoopHandler)
                            userInfo:NULL
                            repeats:YES];
    [self.associatedRunLoop addTimer:self.associatedTimer forMode:NSRunLoopCommonModes];
    [self.associatedRunLoop run];
    NSLog(@"thread %@ exiting", [[NSThread currentThread] name]);
}

- (void)handleMachMessage:(void *)msg {
    // we don't care about the message, if received any, call handler
    [self associatedLoopHandler];
}

- (void)associatedLoopHandler {
#if DEBUG
    NSString *name = [[NSThread currentThread] name];
    NSString *want = [[NSString alloc] initWithFormat:@"wiki.qaq.shell.%p", self.parent];
    assert([name isEqualToString:want]);
#endif
    [self.parent handleRequestsIfNeeded];
}

- (void)destroyLoop {
    [self.associatedTimer invalidate];
    [self.associatedRunLoop removePort:self.associatedPort forMode:NSRunLoopCommonModes];
    CFRunLoopStop([self.associatedRunLoop getCFRunLoop]);
}

@end
