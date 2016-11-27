//
//  VoiceMemoListViewController.h
//  SpeakHere
//
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAudioPlayer.h>

#import <DropboxSDK/DropboxSDK.h>
#import <Accounts/Accounts.h>

#import "CustomizeCell.h"
#import "Reachability.h"

#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MessageUI.h>

@class DBRestClient;
@class AddressAnnotation;

@interface VoiceMemoListViewController : UIViewController<DBRestClientDelegate, UITableViewDataSource, UITableViewDelegate,
AVAudioPlayerDelegate,UIAlertViewDelegate, MFMailComposeViewControllerDelegate>
{
    DBRestClient* restClient;
    UIActivityIndicatorView *activityIndicator;
    
    IBOutlet UIBarButtonItem *btnEdit;
    IBOutlet UITableView *tableView;
    IBOutlet UILabel  *timerLabel; 
    IBOutlet UISlider*          m_progress;
    IBOutlet UIButton *btnGroup;
    AVAudioPlayer *audioPlayer;
    NSTimer *playbackTimer;
    NSMutableArray *fileList;
    NSMetadataQuery *query;
    BOOL isGroup;
    
    Reachability* hostReach;
    Reachability* internetReach;
    Reachability* wifiReach;
    
    int m_nSelectedItem;
}

-(IBAction)actionBack;
-(IBAction)actionEdit;
-(IBAction)sliderChanged;
-(IBAction)actionShare;
-(IBAction)actionSetting;
-(IBAction)actionbtnGroup;
-(IBAction)actionTimeSetting;

-(void)playAudio;
-(void)stopAudio;
- (void)initAudio:(NSString*)file;
-(BOOL) isPlaying;
-(void)setGroup:(BOOL)check;

@property (nonatomic, readonly) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, readonly) DBRestClient *restClient;

@property (nonatomic, retain) IBOutlet UILabel *timerLabel;
@property (nonatomic, retain) IBOutlet UISlider *m_progress;
@property (nonatomic, retain) NSTimer  *playbackTimer; 
@property (nonatomic, retain) AVAudioPlayer *audioPlayer;

@property (nonatomic, assign) BOOL isEdit;
@property (nonatomic, assign) BOOL isGroup;
@property (nonatomic, retain) NSMutableArray *cellInfoList;
@property (nonatomic, retain) NSMutableArray *fileList;

@property (nonatomic, retain) NSMetadataQuery *query;

@property(nonatomic, retain) UITableView *tableView;

@property (strong, nonatomic) NSURL *ubiquityURL;
@property (strong, nonatomic) NSURL *absoluteUbiquityURL;
@property (strong, nonatomic) NSMetadataQuery *metadataQuery;
@end
