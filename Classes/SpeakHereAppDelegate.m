

#import "SpeakHereAppDelegate.h"
#import "SpeakHereViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "GameUtils.h"
#import "Reachability.h"
#import <AVFoundation/AVAudioSession.h>

#import "iRate.h"

#define kFILENAME @"mydocument.dox"

@implementation SpeakHereAppDelegate
@synthesize cellInfoList;

+ (void)initialize
{
    //set the bundle ID. normally you wouldn't need to do this
    //as it is picked up automatically from your Info.plist file
    //but we want to test with an app that's actually on the store
    [iRate sharedInstance].applicationBundleID =
    [iRate sharedInstance].appStoreID = 
	[iRate sharedInstance].onlyPromptIfLatestVersion = NO;
    
    [iRate sharedInstance].daysUntilPrompt = 0;
    [iRate sharedInstance].usesUntilPrompt = 3;
    [iRate sharedInstance].eventsUntilPrompt = 3;
    
    //[iRate sharedInstance].previewMode = YES;
}

- (void)dealloc
{
    [self.window release];
    [self.navigationViewController release];
    
    [super dealloc];
}

-(void)getCellListFromDB:(NSString*)sql
{
    if (self.cellInfoList != nil)
    { [self.cellInfoList removeAllObjects];}
    
    NSArray *array = [g_GameUtils getCellInfo:sql];
    
    int nCount = array.count;
    if( nCount == 0 )
        return;
    
    for (int i=0; i<nCount; i++) 
    {
        NSDictionary* dataDictionary = [array objectAtIndex:i];
        MemoCellInfo* info = [[[MemoCellInfo alloc] init] autorelease];
        
        NSNumber* number1 = [dataDictionary objectForKey:@"id"];
        info.index = [number1 unsignedIntValue];
        
        NSString* str1 = [dataDictionary objectForKey:@"date"];
        info.date = str1;    
        
        NSString* str2 = [dataDictionary objectForKey:@"time"];
        info.time = str2;
        
        NSString* str3 = [dataDictionary objectForKey:@"memoLabel"];
        info.memoLabel = str3;
        
        NSString* str4 = [dataDictionary objectForKey:@"length"];
        info.length = str4;
        
        NSString* str5 = [dataDictionary objectForKey:@"file"];
        info.file = str5;
        
        [self.cellInfoList addObject:info];
    }
}

-(void)sendAudiofiles
{
    if( [self.cellInfoList count] == 0)
        return;
    for( int i=0; i<[self.cellInfoList count]; i++)
    {
        MemoCellInfo *info = [self.cellInfoList objectAtIndex:i];
        NSString *path = info.file;
        
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        if (!fileURL) {
            continue;
        }
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        NSURL *iCloudDocumentsURL = [[fm URLForUbiquityContainerIdentifier:nil] URLByAppendingPathComponent:@"Documents"];
        
        if ([fm fileExistsAtPath:[iCloudDocumentsURL path]] == NO)
        {
            NSLog(@"iCloud Documents directory does not exist");
            [fm createDirectoryAtURL:iCloudDocumentsURL withIntermediateDirectories:YES attributes:nil error:nil];
        } else {
            NSLog(@"iCloud Documents directory exists");
        }
        
        NSString*fileName = [NSString stringWithFormat:@"%@-%@-%@.caf", info.memoLabel, info.date, info.time];
        NSURL *iCloudFileURL = [iCloudDocumentsURL URLByAppendingPathComponent:fileName];
        
        NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
        NSError *error = nil;
        //BOOL success = [fileManager setUbiquitous:YES itemAtURL:fileURL
        //                             destinationURL:iCloudFileURL error:&error];
        BOOL success = [fileManager copyItemAtURL:fileURL toURL:iCloudFileURL error:&error];
        
        if (success) {
            NSLog(@"moved file to cloud: %@", path);
        }
        if (!success) {
            NSLog(@"Couldn't move file to iCloud: %@", path);
        }
    }
}


//Called by Reachability whenever status changes.
- (void) configureTextField: (Reachability*) curReach
{
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    BOOL connectionRequired= [curReach connectionRequired];
    NSString* statusString= @"";
    switch (netStatus)
    {
        case NotReachable:
        {
            isSending = FALSE;
            break;
        }
            
        case ReachableViaWWAN:
        {
            [self getCellListFromDB:@"SELECT * FROM memoList"];
            [self sendAudiofiles];
            break;
        }
        case ReachableViaWiFi:
        {
            isSending = YES;
            break;
        }
    }
    if(connectionRequired)
    {
        statusString= [NSString stringWithFormat: @"%@, Connection Required", statusString];
    }
}

- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateInterfaceWithReachability: curReach];
}

- (void) updateInterfaceWithReachability: (Reachability*) curReach
{
    if(curReach == hostReach)
	{
		[self configureTextField:curReach];
//        NetworkStatus netStatus = [curReach currentReachabilityStatus];
        BOOL connectionRequired= [curReach connectionRequired];
        
        NSString* baseLabel=  @"";
        if(connectionRequired)
        {
            baseLabel=  @"Cellular data network is available.\n  Internet traffic will be routed through it after a connection is established.";
        }
        else
        {
            baseLabel=  @"Cellular data network is active.\n  Internet traffic will be routed through it.";
        }
    }
	if(curReach == internetReach)
	{	
		[self configureTextField:curReach];
	}
	if(curReach == wifiReach)
	{	
        NSLog(@"wifi connect");
		[self configureTextField:curReach];
	}
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    //[self initDropBox];
    isBackground = NO;
    isSending = NO;
    self.cellInfoList = [[NSMutableArray alloc] init];
    g_GameUtils = [[GameUtils alloc] init];
    //[self initDropBox];
    
    application.applicationIconBadgeNumber = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];

    wifiReach = [[Reachability reachabilityForLocalWiFi] retain];
    [wifiReach startNotifier];
    [self updateInterfaceWithReachability: wifiReach];
    
    NSString* res_name = @"";
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        res_name = @"SpeakHereViewController-iPad";
    }
    else
    {
        if(IS_IPHONE_5)
            res_name = @"SpeakHereViewController_568h";
        else
            res_name = @"SpeakHereViewController";
    }
    
    self.speakhearViewController = [[SpeakHereViewController alloc] initWithNibName:res_name bundle:nil];
    
    self.navigationViewController = [[UINavigationController alloc] initWithRootViewController:self.speakhearViewController];
    [self.navigationViewController setNavigationBarHidden:YES];
    
    self.window.rootViewController = self.navigationViewController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif {
    // Handle the notificaton when the app is running
    NSLog(@"Recieved Notification %@",notif);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


-(void) uploadFile2Dropbox
{
    
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	if ([[DBSession sharedSession] handleOpenURL:url]) {
		if ([[DBSession sharedSession] isLinked]) {
			NSLog(@"Successfully loged");
		}
		return YES;
	}
	
	return NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    
    isBackground = NO;
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.speakhearViewController stopRecord];
    isBackground = YES;
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
	UIApplication*    app = [UIApplication sharedApplication];
	
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
	
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		while (isBackground) {
            if( isSending )
            {
                [self getCellListFromDB:@"SELECT * FROM memoList"];
                [self sendAudiofiles];
            }

            [NSThread sleepForTimeInterval:(1800)];
		}
		
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    });
    
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


// This method will be used for iOS versions grater than 4.2.
- (BOOL)application:(UIApplication *)application openURL:(NSURL*)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    if ([[DBSession sharedSession] handleOpenURL:url]) {
		if ([[DBSession sharedSession] isLinked]) {
			NSLog(@"Successfully loged");
		}
		return YES;
	}
    
    return NO;
}

#pragma mark - dropbox
- (void)initDropBox
{
    // Set these variables before launching the app
    NSString* appKey = _STR_DROPBOX_APPKEY_;
	NSString* appSecret = _STR_DROPBOX_SECRET_;
	NSString *root = @"RecordedPossition/"; // Should be set to either kDBRootAppFolder or kDBRootDropbox
	// You can determine if you have App folder access or Full Dropbox along with your consumer key/secret
	// from https://dropbox.com/developers/apps 
	
	// Look below where the DBSession is created to understand how to use DBSession in your app
	
	NSString* errorMsg = nil;
	if ([appKey rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
		errorMsg = @"Make sure you set the app key correctly";
	} else if ([appSecret rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
		errorMsg = @"Make sure you set the app secret correctly";
	} else if ([root length] == 0) {
		errorMsg = @"Set your root to use either App Folder of full Dropbox";
	} else {
		NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
		NSData *plistData = [NSData dataWithContentsOfFile:plistPath];
		NSDictionary *loadedPlist = 
        [NSPropertyListSerialization 
         propertyListFromData:plistData mutabilityOption:0 format:NULL errorDescription:NULL];
		NSString *scheme = [[[[loadedPlist objectForKey:@"CFBundleURLTypes"] objectAtIndex:0] objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
		if ([scheme isEqual:appKey]) {
			errorMsg = @"Set your URL scheme correctly in dailyposition-Info.plist";
		}
	}
	
	DBSession* session = 
    [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:@""];
	session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
	[DBSession setSharedSession:session];
    [session release];
	
	[DBRequest setNetworkRequestDelegate:self];
    
	if (errorMsg != nil) {
		[[[[UIAlertView alloc]
		   initWithTitle:@"Error Configuring Session" message:errorMsg 
		   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
		  autorelease]
		 show];
	}
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId
{
    
}

#pragma mark -
#pragma mark DBNetworkRequestDelegate methods

static int outstandingRequests;

- (void)networkRequestStarted {
	outstandingRequests++;
	if (outstandingRequests == 1) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	}
}

- (void)networkRequestStopped {
	outstandingRequests--;
	if (outstandingRequests == 0) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}


@end