//
//  VoiceMemoListViewController.m
//  SpeakHere
//
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import "VoiceMemoListViewController.h"
#import "GameUtils.h"
#import "CustomizeCell.h"
#import "SettingViewController.h"
#import "SpeakHereAppDelegate.h"
#import "Reachability.h"
#import "TimeSettingViewController.h"

#import <AVFoundation/AVAudioSession.h>
@interface VoiceMemoListViewController ()

@end

@implementation VoiceMemoListViewController
@synthesize tableView;
@synthesize cellInfoList;
@synthesize isEdit, isGroup;
@synthesize timerLabel, m_progress, playbackTimer, audioPlayer;
@synthesize activityIndicator, restClient;
@synthesize ubiquityURL, metadataQuery, absoluteUbiquityURL;

@synthesize fileList = _fileList;
@synthesize query = _query;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.isGroup = FALSE;
    _query = nil;
    
    self.fileList = [[NSMutableArray alloc] init];
    
    _query = [[NSMetadataQuery alloc] init];
    [_query setSearchScopes:[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDocumentsScope, nil]];
    [_query setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE '*.caf'", NSMetadataItemFSNameKey]];
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(fileListReceived)
                               name:NSMetadataQueryDidFinishGatheringNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(fileListReceived)
                               name:NSMetadataQueryDidUpdateNotification object:nil];
    [_query startQuery];
}

-(void)setGroup:(BOOL)check
{
/*    if(check)
        [btnGroup setImage:[UIImage  imageNamed:@"group_check.png"] forState:UIControlStateNormal];
    else {
        [btnGroup setImage:nil forState:UIControlStateNormal];
    }*/
    NSString* res_name = @"SettingViewController";
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        res_name = @"SettingViewController-iPad";
    else
    {
        if(IS_IPHONE_5)
            res_name = @"SettingViewController_568h";
        else
            res_name = @"SettingViewController";
    }
    SettingViewController* memoController = [[SettingViewController alloc] initWithNibName:res_name bundle:nil];
    [g_GameUtils replaceLabel:@"None"];
    [self presentViewController:memoController animated:YES completion:nil];
    [memoController release];
}

-(void)viewWillAppear:(BOOL)animated
{
    
    // Do any additional setup after loading the view from its nib.
    g_cell = nil;
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [self.activityIndicator stopAnimating];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    //progress bar
    [m_progress addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [m_progress setMaximumTrackImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sld_time_backk.png" ofType:nil]] forState:UIControlStateNormal];
    [m_progress setMinimumTrackImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sld_time_back1.png" ofType:nil]] forState:UIControlStateNormal];
    [m_progress setThumbImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sld_time_thumbb.png" ofType:nil]] forState:UIControlStateNormal];
    [m_progress setMaximumValue:100.0f];
    [m_progress setMinimumValue:0.0f];
    [m_progress setValue:0.0f];
    
    //
    self.cellInfoList = [[NSMutableArray alloc] init];

    if( g_groupName == nil || [g_groupName isEqualToString:@"None"] )
        [self getCellListFromDB:@"SELECT * FROM memoList ORDER BY id DESC"];
    else
        [self getCellListFromDB:[NSString stringWithFormat:@"SELECT * FROM memoList WHERE memoLabel = '%@' ORDER BY id DESC", g_groupName]];
      
    [self.tableView reloadData];
    
    self.isEdit = FALSE;
    [self setTextEditButton:self.isEdit];
    
    m_nSelectedItem = -1;
    
    [super viewWillAppear:TRUE];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self stopAudio];
    [super viewWillDisappear:TRUE];
}

-(void)setTextEditButton:(BOOL)isEdit
{
    btnEdit.title = @"Edit";
    if( self.isEdit )
        btnEdit.title = @"Done";
}

- (void)viewDidUnload
{
    [_query release];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(IBAction)actionbtnGroup
{
    g_rowMemoNumber = -100;
    NSString* res_name = @"SettingViewController";
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        res_name = @"SettingViewController-iPad";
    else
    {
        if(IS_IPHONE_5)
            res_name = @"SettingViewController_568h";
        else
            res_name = @"SettingViewController";
    }
    
    SettingViewController* memoController = [[SettingViewController alloc] initWithNibName:res_name bundle:nil];
    [g_GameUtils replaceLabel:@"None"];
    [self presentViewController:memoController animated:YES completion:nil];
    [memoController release];
}

-(IBAction)actionTimeSetting{
    g_rowMemoNumber = -100;
    NSString* res_name = @"TimeSettingViewController";

    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        res_name = @"TimeSettingViewController-iPad";
    else
    {
        if(IS_IPHONE_5)
            res_name = @"TimeSettingViewController_568h";
        else
            res_name = @"TimeSettingViewController";
    }
    
    TimeSettingViewController* memoController = [[TimeSettingViewController alloc] initWithNibName:res_name bundle:nil];

    [self presentViewController:memoController animated:YES completion:nil];
    [memoController release];
}

-(IBAction)actionBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)actionEdit
{
    self.isEdit = !self.isEdit;
    self.tableView.editing = self.isEdit;
    [self setTextEditButton:self.isEdit];
    [self.tableView reloadData];
}

-(IBAction)sliderChanged
{

}

-(NSString*)currentYear{
    NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
    NSDate *now = [[[NSDate alloc] init]autorelease];
    [fmt setDateFormat:@"YY-MM-dd/HH:mm:ss"];    
    NSString* str_date = [fmt stringFromDate:now];

    return str_date;
}


-(IBAction)actionShare{
    
    if(m_nSelectedItem == -1)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                        message:@"There is no selected item."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        
        alert.tag = -1;
        [alert show];
        [alert release];
    }
    
    [self saveToEmail];
    
//    NSURL *ubiq = [[NSFileManager defaultManager]
//                   URLForUbiquityContainerIdentifier:nil];
//    if (!ubiq) {
//        [[[[UIAlertView alloc]initWithTitle:@"Notice" 
//                                    message:@"No iCloud access"
//                                   delegate:nil 
//                          cancelButtonTitle:@"OK" 
//                          otherButtonTitles:nil]autorelease]show];
//        return;
//    }
//    [self sendAudiofiles];
}

-(void)fileListReceived {
    
    [self.fileList removeAllObjects];

    NSArray* queryResults = [_query results];
    [_query disableUpdates];
    [_query stopQuery];
    NSLog(@"---------%d---------", [queryResults count]);
    
    for (NSMetadataItem* result in queryResults) {
        NSString* fileName = [result valueForAttribute:NSMetadataItemFSNameKey];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        NSURL *iCloudDocumentsURL = [[fm URLForUbiquityContainerIdentifier:nil] URLByAppendingPathComponent:@"Documents"];
        
        NSURL *iCloudFileURL = [iCloudDocumentsURL URLByAppendingPathComponent:fileName];
        [self.fileList addObject:iCloudFileURL];
    }
}


-(IBAction)actionSetting
{
    NSURL *ubiq = [[NSFileManager defaultManager]
                   URLForUbiquityContainerIdentifier:nil];
    if (!ubiq) {
        [[[[UIAlertView alloc]initWithTitle:@"Notice" 
                                    message:@"No iCloud access"
                                   delegate:nil
                          cancelButtonTitle:@"OK" 
                          otherButtonTitles:nil]autorelease]show];
        return;
    }
    
    if( [self.fileList count] < 1 )
    {
        [[[[UIAlertView alloc]initWithTitle:@"Notice" 
                                    message:@"Voicememos don't exist in iCloud"
                                   delegate:nil 
                          cancelButtonTitle:@"OK" 
                          otherButtonTitles:nil]autorelease]show];
        return;
    }
    
    [[[[UIAlertView alloc]initWithTitle:@"Notice" 
                                message:@"Will you restore voicememos from iCloud?"
                               delegate:self
                      cancelButtonTitle:@"OK" 
                      otherButtonTitles:@"Cancel", nil]autorelease]show];
}

///////////////////audio///////////
-(void)playAudio
{
    btnEdit.enabled = FALSE;
    rowCount = g_cell.info.seq-1;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowCount inSection:0];
 
    [self.tableView selectRowAtIndexPath:indexPath animated:YES
                        scrollPosition:UITableViewScrollPositionMiddle];
    
    //set new cell info
    [audioPlayer play];
}

-(BOOL) isPlaying
{
    return audioPlayer.isPlaying;
}

-(void)stopAudio
{
    btnEdit.enabled = TRUE;
    
    if( audioPlayer.isPlaying )
    {
        [playbackTimer invalidate];
        
        [audioPlayer stop];
    }
}

-(NSString*)playTime:(NSString*)file
{
    NSURL *url = [NSURL fileURLWithPath:file];
    
    NSError *error;
    AVAudioPlayer* tmpAudioPlayer = [[AVAudioPlayer alloc]
                   initWithContentsOfURL:url
                   error:&error];
    
    float duration_minutes = floor(tmpAudioPlayer.duration/60);
    float duration_seconds = tmpAudioPlayer.duration - (duration_minutes * 60);
    
    NSString *timeString = [NSString stringWithFormat:@"%0.0f:%0.0f",duration_minutes, duration_seconds]; 
    [tmpAudioPlayer release];
    return timeString;
}

-(void)updateTime
{
    float minutes = floor(audioPlayer.currentTime/60);
    float seconds = audioPlayer.currentTime - (minutes * 60);
    
    float duration_minutes = floor(audioPlayer.duration/60);
    float duration_seconds = 
    audioPlayer.duration - (duration_minutes * 60);
    
    NSString *timeInfoString = [[NSString alloc] 
                                initWithFormat:@"%0.0f:%0.0f / %0.0f:%0.0f",
                                minutes, seconds, 
                                duration_minutes, duration_seconds];
    
    timerLabel.text = timeInfoString;
    [timeInfoString release];
    
}

- (void)initAudio:(NSString*)file {
    
    NSURL *url = [NSURL fileURLWithPath:file];
    
    NSError *error;
    audioPlayer = [[AVAudioPlayer alloc]
                   initWithContentsOfURL:url
                   error:&error];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    
    if (error)
    {
        NSLog(@"Error in audioPlayer: %@", 
              [error localizedDescription]);
    } else {
        audioPlayer.delegate = self;
        [audioPlayer prepareToPlay];
    }
    
    
    playbackTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self
                                                   selector:@selector(updateSlider) userInfo:nil repeats:YES];
    
    m_progress.maximumValue = audioPlayer.duration;
    // Set the valueChanged target
    //[m_progress addTarget:self action:@selector(sliderChanged:) forControlEvents: UIControl EventValueChanged];
}

- (void)updateSlider {
    // Update the slider about the music time
    m_progress.value = audioPlayer.currentTime;
    [self updateTime];
}

- (IBAction)sliderChanged:(UISlider *)sender {
    // Fast skip the music when user scroll the UISlider
    [audioPlayer stop];
    [audioPlayer setCurrentTime:m_progress.value];
    [audioPlayer prepareToPlay];
    [audioPlayer play];
    [self updateTime];
}

- (BOOL) getRepeat
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    return [defaults boolForKey:@"repeat"];
}

-(void)audioPlayerDidFinishPlaying:
(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if( g_cell == nil )
        return;
    
    [g_cell stopAudio];

    
    BOOL repeat = [self getRepeat];
    if( !repeat )
        return;

    if( self.isGroup ) //group play
    {
        do
        {
            rowCount = g_cell.info.seq;
            
            if( rowCount == [self.tableView numberOfRowsInSection:0] )
            {
                rowCount = 0;
            }
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowCount inSection:0];
            //set new cell info
            
            g_cell = (CustomizeCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            
            if( g_firstRowNumber == g_cell.info.seq )
            {
                g_cell = nil;
                return;
            }
            if( [g_cell.textLabel.text isEqualToString:g_groupName] )
            {
                [g_cell startAudio];
                return;
            }
            
        }while(g_firstRowNumber != g_cell.info.seq);

    }
    else // all play
    {
        rowCount = g_cell.info.seq;
        if( rowCount == [self.tableView numberOfRowsInSection:0] )
            rowCount = 0;
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowCount inSection:0];
        //set new cell info
        
        g_cell = (CustomizeCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    
        //[tableView didSelectRowAtIndexPath:indexPath];
        
        if( g_firstRowNumber == g_cell.info.seq )
        {
            g_cell = nil;
            return;
        }
        [g_cell startAudio];
    }
}

int rowCount = 0;
-(void)audioPlayerDecodeErrorDidOccur:
(AVAudioPlayer *)player error:(NSError *)error
{

}

-(void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    
}

-(void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
}

////////////////
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cellInfoList.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    CustomizeCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        //cell = [[[exerciseListUITableCell alloc] init] autorelease];
        
        NSArray * topLevelObjects;
        
        topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CustomizeCell" owner:self options:nil];
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CustomizeCell-iPad" owner:self options:nil];
        
        for(id currentObject in topLevelObjects)
        {
            if([currentObject isKindOfClass:[UITableViewCell class]])
            {
                cell = (CustomizeCell *)currentObject;
                cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                break;
            }
        }        
    }
    

    if( g_groupName == nil || [g_groupName isEqualToString:@"None"] )
        [self getCellListFromDB:@"SELECT * FROM memoList ORDER BY id DESC"];
    else
        [self getCellListFromDB:[NSString stringWithFormat:@"SELECT * FROM memoList WHERE memoLabel = '%@' ORDER BY id DESC", g_groupName]];
       
    [cell setDelegate:self];
    MemoCellInfo *info = [self.cellInfoList objectAtIndex:[indexPath row]];
    info.length = [self playTime:info.file];
    info.seq = [indexPath row]+1;
    [cell setInfo:info];
    [cell showCell];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        CustomizeCell *cell = (CustomizeCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell removeCell];
        [self getCellListFromDB:@"SELECT * FROM memoList ORDER BY id DESC"];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        NSURL *ubiq = [[NSFileManager defaultManager]
                       URLForUbiquityContainerIdentifier:nil];
        if (!ubiq) 
            return;
        
        NSURL *fileURL = [NSURL fileURLWithPath:cell.info.file];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        NSURL *iCloudDocumentsURL = [[fm URLForUbiquityContainerIdentifier:nil] URLByAppendingPathComponent:@"Documents"];
        
        NSURL *iCloudFileURL = [iCloudDocumentsURL URLByAppendingPathComponent:[fileURL lastPathComponent]];
        [fm removeItemAtURL:iCloudFileURL error:nil];

    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    m_nSelectedItem = indexPath.row;
}



-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
}

-(UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellAccessoryDetailDisclosureButton;
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    CustomizeCell *cell = (CustomizeCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    g_rowMemoNumber = cell.info.index;
    
    NSString* res_name = @"SettingViewController";
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        res_name = @"SettingViewController-iPad";
    else
    {
        if(IS_IPHONE_5)
            res_name = @"SettingViewController_568h";
        else
            res_name = @"SettingViewController";
    }
    
    SettingViewController* memoController = [[SettingViewController alloc] initWithNibName:res_name bundle:nil];
    
    [g_GameUtils replaceLabel:cell.info.memoLabel];
    
    [self presentViewController:memoController animated:YES completion:nil];
    [memoController release];
    //[self tableView:tableView didSelectRowAtIndexPath:indexPath];
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
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Notice" message:@"Uploaded successfully to iCloud" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void) saveToEmail
{
    if([self.cellInfoList count] <= m_nSelectedItem)
        return;
    
    MemoCellInfo *info = [self.cellInfoList objectAtIndex:m_nSelectedItem];
    NSString *path = info.file;
    NSURL *pathUrl = [NSURL fileURLWithPath:path];
    NSString *sFileName = [pathUrl lastPathComponent];
    
    if (![MFMailComposeViewController canSendMail])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                        message:@"Your device doesn't support this feature."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        
        alert.tag = -1;
        [alert show];
        [alert release];
        return;
    }
    
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    NSString* strSubject = [NSString stringWithFormat:@"Recorder Pro"];
    [picker setSubject:strSubject];
    
    NSString *content = [NSString stringWithFormat:@""];
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    [picker addAttachmentData:data mimeType:@"cfg" fileName:sFileName];
    
    [picker setMessageBody:content isHTML:NO];
    
    picker.navigationBar.barStyle = UIBarStyleDefault;
    
    [self presentModalViewController:picker animated:YES];
    
    [picker release];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled:
			break;
		case MFMailComposeResultSaved:
			break;
		case MFMailComposeResultSent:
			break;
		case MFMailComposeResultFailed:
			break;
			
		default:
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email" message:@"Sending Failed - Unknown Error :-("
														   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			alert.tag = -1;
            [alert show];
			[alert release];
		}
			
			break;
	}
	[self dismissModalViewControllerAnimated:YES];
}

- (void) configureTextField: (Reachability*) curReach
{
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    BOOL connectionRequired= [curReach connectionRequired];
    NSString* statusString= @"";
    switch (netStatus)
    {
        case NotReachable:
        {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Notice" message:@"Access Not Available" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
            [alert release];
            //Minor interface detail- connectionRequired may return yes, even when the host is unreachable.  We cover that up here...
            connectionRequired= NO;  
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
            [self getCellListFromDB:@"SELECT * FROM memoList"];
            [self sendAudiofiles];
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
        
        NSLog(@"%@", baseLabel);
    }
	if(curReach == internetReach)
	{	
		[self configureTextField:curReach];
	}
	if(curReach == wifiReach)
	{	
		[self configureTextField:curReach];
	}
}
#pragma mark DBRestClientDelegate methods

- (DBRestClient *)restClient {
    
	if (restClient == nil) {
        
		restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
		restClient.delegate = self;
	}
    
	return restClient;
}


- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)srcPath{
	
	NSString *filename = [[srcPath pathComponents] lastObject];
	
	NSString *msg = [NSString stringWithFormat:@"Uploaded File: %@",filename];
	[[[[UIAlertView alloc]initWithTitle:@"Success" 
								message:msg
							   delegate:nil 
					  cancelButtonTitle:@"OK" 
					  otherButtonTitles:nil]autorelease]show];
	
	[self.activityIndicator stopAnimating];
    
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath 
          metadata:(DBMetadata*)metadata
{
    NSString *filename = [[srcPath pathComponents] lastObject];
	NSString *msg = [NSString stringWithFormat:@"Uploaded File:%@",filename];
	[[[[UIAlertView alloc]initWithTitle:@"Success" 
								message:msg
							   delegate:nil 
					  cancelButtonTitle:@"OK" 
					  otherButtonTitles:nil]autorelease]show];
	
	[self.activityIndicator stopAnimating];
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error{
    
	NSLog(@"uploadFileFailedWithError, %@, %@.", [error localizedDescription], [error userInfo]);
	
	NSString *errorMsg = [NSString stringWithFormat:@"%@. %@",[error localizedDescription],[error userInfo]];
	
	[[[[UIAlertView alloc]initWithTitle:@"Error in Uploading Files" 
								message:errorMsg 
							   delegate:nil
					  cancelButtonTitle:@"OK" 
					  otherButtonTitles:nil]autorelease]show];
    [self.activityIndicator stopAnimating];
    
}

- (void)restClient:(DBRestClient *)client uploadFileChunkFailedWithError:(NSError *)error
{
	NSLog(@"uploadFileChunkFailedWithError, %@, %@.", [error localizedDescription], [error userInfo]);
	
	NSString *errorMsg = [NSString stringWithFormat:@"%@. %@",[error localizedDescription],[error userInfo]];
	
	[[[[UIAlertView alloc]initWithTitle:@"Error in Uploading Files" 
								message:errorMsg 
							   delegate:nil
					  cancelButtonTitle:@"OK" 
					  otherButtonTitles:nil]autorelease]show];
    
    [self.activityIndicator stopAnimating];
}

- (void)restClient:(DBRestClient *)client uploadFromUploadIdFailedWithError:(NSError *)error
{
	NSLog(@"uploadFromUploadIdFailedWithError, %@, %@.", [error localizedDescription], [error userInfo]);
	
	NSString *errorMsg = [NSString stringWithFormat:@"%@. %@",[error localizedDescription],[error userInfo]];
	
	[[[[UIAlertView alloc]initWithTitle:@"Error in Uploading Files" 
								message:errorMsg 
							   delegate:nil
					  cancelButtonTitle:@"OK" 
					  otherButtonTitles:nil]autorelease]show];
    
}

-(void)alertView:(UIAlertView *)alert_view didDismissWithButtonIndex:(NSInteger)button_index
{
    if(button_index == 0){
        NSError *error = nil;
        
        [g_GameUtils removeMemoList];
        NSURL *iCloudDocumentsURL = [[[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] URLByAppendingPathComponent:@"Documents"];
        [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:iCloudDocumentsURL error:&error];
        
        for( int i=0 ; i < [self.fileList count]; i++ )
        {
            NSURL *iCloudFileURL = [self.fileList objectAtIndex:i]; // iCloud source
            
            if ([[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:iCloudFileURL error:&error])
            {
                id isDownloading = nil;
                
                if ([iCloudFileURL getResourceValue:&isDownloading forKey:NSURLUbiquitousItemIsDownloadingKey error:&error] && isDownloading)
                {
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *documentsDirectory = [paths objectAtIndex:0];
                    NSURL *destinationURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:[iCloudFileURL lastPathComponent]]];
                    
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSError *error = nil;
                    NSNumber *ableToBeCopied = [NSNumber numberWithBool:YES];
                    
                    // However, ubiquitous items that are not downloaded CANNOT be copied
                    if ([fileManager isUbiquitousItemAtURL:iCloudFileURL]) {
                        [iCloudFileURL getResourceValue:&ableToBeCopied forKey:NSURLUbiquitousItemIsDownloadedKey error:nil];
                    }
                    
                    BOOL success = [fileManager copyItemAtURL:iCloudFileURL toURL:destinationURL error:&error];
                    if (success) {
                        NSString*fileName = [iCloudFileURL lastPathComponent];
                        NSArray *firstSplit = [fileName componentsSeparatedByString:@"."];
                        NSString *name = [firstSplit objectAtIndex:0];
                        
                        firstSplit = [name componentsSeparatedByString:@"-"];
                        MemoCellInfo *info = [[[MemoCellInfo alloc]init] autorelease];
                        
                        info.memoLabel =[firstSplit objectAtIndex:0];
                        info.date = [firstSplit objectAtIndex:1];
                        info.time = [firstSplit objectAtIndex:2];
                        info.file = [documentsDirectory stringByAppendingPathComponent:[iCloudFileURL lastPathComponent]];
                        [g_GameUtils addCellInfo:info];
                        
                        NSLog(@"moved file to local storage: %@, %@, %@", info.memoLabel, info.date, info.file);
                    }
                    if (!success) {
                        NSLog(@"Couldn't move file to local storage:%@ {error{%@}}", [iCloudFileURL lastPathComponent], error);
                    }
                }
                else
                {
                    NSLog(@"Error %@ getting downloading state again for item at %@", error, iCloudFileURL);
                }
            }
            else
            {
                NSLog(@"Error %@ starting to download item at %@", error, iCloudFileURL);
            }
        }
        
        
        if( g_groupName == nil || [g_groupName isEqualToString:@"None"] )
            [self getCellListFromDB:@"SELECT * FROM memoList ORDER BY id DESC"];
        else
            [self getCellListFromDB:[NSString stringWithFormat:@"SELECT * FROM memoList WHERE memoLabel = '%@' ORDER BY id DESC", g_groupName]];
        
        [self.tableView reloadData];
        [[[[UIAlertView alloc]initWithTitle:@"Notice" 
                                    message:@"Downloaded successfully voicememos from iCloud"
                                   delegate:nil 
                          cancelButtonTitle:@"OK" 
                          otherButtonTitles:nil]autorelease]show];

    }
}

@end
