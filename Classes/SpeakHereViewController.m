

#import "SpeakHereViewController.h"
#import "VoiceMemoListViewController.h"
#import "SpeakHereAppDelegate.h"

#import "GameUtils.h"

@implementation SpeakHereViewController




- (void)viewDidLoad {
   
    [super viewDidLoad];
    
}





-(void)viewWillAppear:(BOOL)animated
{
    
}

-(void)uploadFile
{
    NSLog(@"timer");
}

-(void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"stoprecord");
    [controller stopRecord];
    [super viewWillDisappear:TRUE];
}

-(void)stopRecord
{
    [controller stopRecord];
}

-(NSString*)getUniqueFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@-%@.caf",[g_GameUtils getCheckedLabel], [self currentDate], [self currentTime]]];
    return path;
}

- (BOOL)renameFile
{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent: @"recordedFile.caf"];
    
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    
    if(![localFileManager fileExistsAtPath:path])
    {
        NSLog(@"no file");
    }
    
    NSError *renameError = nil;
    BOOL renamed = [localFileManager moveItemAtPath:path toPath:[self getUniqueFilePath] error:&renameError];
    if (!renamed || renameError) {
        NSLog(@"ERROR Moving file: %@ to %@", path, [self getUniqueFilePath]);
        [localFileManager release];
        return FALSE;
    }

    [localFileManager release];
    return TRUE;
}

-(NSString*)currentDate{
    NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
    NSDate *now = [[[NSDate alloc] init]autorelease];
    [fmt setDateFormat:@"yyyy_MM_dd"];    
    NSString* str_date = [fmt stringFromDate:now];
    return str_date;
}

-(NSString*)currentTime{
    NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
    NSDate *now = [[[NSDate alloc] init]autorelease];
    [fmt setDateFormat:@"HH:mm:ss"];    
    NSString* str_date = [fmt stringFromDate:now];
    return str_date;
}

-(void)sendAudiofile:(NSString*)path
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
    
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    if (!fileURL) {
        return;
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
    
    NSURL *iCloudFileURL = [iCloudDocumentsURL URLByAppendingPathComponent:[fileURL lastPathComponent]];
        
    dispatch_queue_t q_default;
    q_default = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(q_default, ^(void) {
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    NSError *error = nil;
    BOOL success = [fileManager setUbiquitous:YES itemAtURL:fileURL
                                destinationURL:iCloudFileURL error:&error];
        dispatch_queue_t q_main= dispatch_get_main_queue();
        dispatch_async(q_main, ^(void) {
            if (success) {
                NSLog(@"moved file to cloud: %@", path);
            }
            if (!success) {
                NSLog(@"Couldn't move file to iCloud: %@", path);
            }
        });
    });
}

-(IBAction)actionMemoList
{
    if( [self renameFile])
    {
        MemoCellInfo *info = [[[MemoCellInfo alloc]init] autorelease];
        info.date = [self currentDate];
        info.time = [self currentTime];
        info.memoLabel = @"None";
        info.file = [self getUniqueFilePath];
        [g_GameUtils addCellInfo:info];
        g_groupName = info.memoLabel;

        //[self sendAudiofile:info.file];
    }

    NSString* res_name = @"VoiceMemoListViewController";
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        res_name = @"VoiceMemoListViewController-iPad";
    else
    {
        if(IS_IPHONE_5)
            res_name = @"VoiceMemoListViewController_568h";
        else
            res_name = @"VoiceMemoListViewController";
    }
    
     VoiceMemoListViewController* memoController = [[VoiceMemoListViewController alloc] initWithNibName:res_name bundle:nil];
    [self presentViewController:memoController animated:YES completion:nil];
    [memoController release];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
    [super dealloc];
}

@end
