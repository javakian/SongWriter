

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "CustomizeCell.h"

@class Reachability;
@class SpeakHereViewController;

@interface SpeakHereAppDelegate : UIResponder <UIApplicationDelegate, DBSessionDelegate, DBNetworkRequestDelegate> {

    UIBackgroundTaskIdentifier bgTask;
    
    Reachability* hostReach;
    Reachability* internetReach;
    Reachability* wifiReach;
    
    BOOL isSending;
    BOOL isBackground;
}


- (void)initDropBox;

@property (nonatomic, retain) NSMutableArray *cellInfoList;
@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationViewController;
@property (nonatomic, retain) SpeakHereViewController *speakhearViewController;

@end

