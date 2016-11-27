

int g_min = 0, g_sec = 0;

#import "SpeakHereController.h"
#import <MediaPlayer/MPMusicPlayerController.h>

@implementation SpeakHereController

@synthesize player;
@synthesize recorder;

@synthesize btn_record;
@synthesize fileDescription, passedTime;
@synthesize lvlMeter_in;
@synthesize playbackWasInterrupted;
@synthesize m_sldVolume;

char *OSTypeToStr(char *buf, OSType t)
{
	char *p = buf;
	char str[4], *q = str;
	*(UInt32 *)str = CFSwapInt32(t);
	for (int i = 0; i < 4; ++i) {
		if (isprint(*q) && *q != '\\')
			*p++ = *q++;
		else {
			sprintf(p, "\\x%02x", *q++);
			p += 4;
		}
	}
	*p = '\0';
	return buf;
}

-(void)setFileDescriptionForFormat: (CAStreamBasicDescription)format withName:(NSString*)name
{
	char buf[5];
	const char *dataFormat = OSTypeToStr(buf, format.mFormatID);
	NSString* description = [[NSString alloc] initWithFormat:@"(%d ch. %s @ %g Hz)", format.NumberChannels(), dataFormat, format.mSampleRate, nil];
	fileDescription.text = description;
	[description release];	
}

-(void)setDispalyPassedTime
{
    g_sec++;
    if( g_sec > 59 )
    {
        g_min++;
        g_sec = 0;
    }
    
    NSString* description = [[NSString alloc] initWithFormat:@"%02d:%02d",g_min, g_sec, nil];
	passedTime.text = description;
	[description release];
}

#pragma mark Playback routines

-(void)stopPlayQueue
{
	player->StopQueue();
	[lvlMeter_in setAq: nil];
	btn_record.enabled = YES;
}

-(void)pausePlayQueue
{
	player->PauseQueue();
	playbackWasPaused = YES;
}

- (void)stopRecord
{
    if (recorder->IsRunning()) // If we are currently recording, stop and save the file.
    {
	// Disconnect our level meter from the audio queue
	[lvlMeter_in setAq: nil];
	
	recorder->StopRecord();
	
	// dispose the previous playback queue
	player->DisposeQueue(true);

	// now create a new queue for the recorded file
	recordFilePath = (CFStringRef)[NSTemporaryDirectory() stringByAppendingPathComponent: @"recordedFile.caf"];
	player->CreateQueueForFile(recordFilePath);
		
	// Set the button's state back to "record"
	[btn_record setImage:[UIImage  imageNamed:@"record_btnn.png"] forState:UIControlStateNormal];
    }
    isPause = FALSE;
    [self stopPassedTime];
}

- (IBAction)play:(id)sender
{
	if (player->IsRunning())
	{
		if (playbackWasPaused) {
			OSStatus result = player->StartQueue(true);
			if (result == noErr)
				[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:self];
		}
		else
			[self stopPlayQueue];
	}
	else
	{		
		OSStatus result = player->StartQueue(false);
		if (result == noErr)
			[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:self];
	}

}

- (IBAction)record:(id)sender
{
	if (recorder->IsRunning()) // If we are currently recording, stop and save the file.
	{
        [btn_record setImage:[UIImage  imageNamed:@"record_btnn.png"] forState:UIControlStateNormal];
        [self pausePassedTime];
        recorder->pause();
        isPause = TRUE;
		//[self stopRecord];
	}
	else // If we're not recording, start.
	{
        if( isPause == FALSE )
        {
		// Set the button's state to "stop"
            [btn_record setImage:[UIImage  imageNamed:@"pause_btnn.png"] forState:UIControlStateNormal];
				
            // Start the recorder
            recorder->StartRecord(CFSTR("recordedFile.caf"));
		
            [self setFileDescriptionForFormat:recorder->DataFormat() withName:@"Recorded File"];
		
            // Hook the level meter up to the Audio Queue for the recorder
            [lvlMeter_in setAq: recorder->Queue()];
        }
        else {
            recorder->resume();
        }
        [self startPassedTime];
	}	
}

- (void)stopPassedTime {
    g_min = 0;
    g_sec = 0;
	// If a timer exists then cancel and release
	if (controlVisibilityTimer) {
		[controlVisibilityTimer invalidate];
		[controlVisibilityTimer release];
		controlVisibilityTimer = nil;
	}
}

- (void)pausePassedTime {
	// If a timer exists then cancel and release
	if (controlVisibilityTimer) {
		[controlVisibilityTimer invalidate];
		[controlVisibilityTimer release];
		controlVisibilityTimer = nil;
	}
}

// Enable/disable control visiblity timer
- (void)startPassedTime {
    controlVisibilityTimer = [[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setDispalyPassedTime) userInfo:nil repeats:YES] retain];
}

#pragma mark AudioSession listeners
void interruptionListener(	void *	inClientData,
                          UInt32	inInterruptionState)
{
	SpeakHereController *THIS = (SpeakHereController*)inClientData;
	if (inInterruptionState == kAudioSessionBeginInterruption)
	{
        if (THIS->player->IsRunning()) {
			//the queue will stop itself on an interruption, we just need to update the UI
			[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueStopped" object:THIS];
			THIS->playbackWasInterrupted = YES;
		}
        
        if (THIS->recorder->IsRunning()) {
            //the queue will stop itself on an interruption, we just need to update the UI
            THIS->recorder->pause();
			[[NSNotificationCenter defaultCenter] postNotificationName:@"recordingQueueStopped" object:THIS];
			THIS->recordingWasInterrupted = YES;
		}
	}
	else if (inInterruptionState == kAudioSessionEndInterruption) {
        if (THIS->playbackWasInterrupted)
        {
            // we were playing back when we were interrupted, so reset and resume now
            THIS->player->StartQueue(true);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:THIS];
            THIS->playbackWasInterrupted = NO;
        }
        
        if (THIS->recordingWasInterrupted) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"recordingQueueResumed" object:THIS];
            THIS->playbackWasInterrupted = NO;
            THIS->recorder->resume();
        }
    }
}

void propListener(	void *                  inClientData,
					AudioSessionPropertyID	inID,
					UInt32                  inDataSize,
					const void *            inData)
{
	SpeakHereController *THIS = (SpeakHereController*)inClientData;
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
		CFDictionaryRef routeDictionary = (CFDictionaryRef)inData;			
		//CFShow(routeDictionary);
		CFNumberRef reason = (CFNumberRef)CFDictionaryGetValue(routeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
		SInt32 reasonVal;
		CFNumberGetValue(reason, kCFNumberSInt32Type, &reasonVal);
		if (reasonVal != kAudioSessionRouteChangeReason_CategoryChange)
		{

			if (reasonVal == kAudioSessionRouteChangeReason_OldDeviceUnavailable)
			{			
				if (THIS->player->IsRunning()) {
					[THIS pausePlayQueue];
					[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueStopped" object:THIS];
				}		
			}

			// stop the queue if we had a non-policy route change
			if (THIS->recorder->IsRunning()) {
				[THIS stopRecord];
			}
		}	
	}
	else if (inID == kAudioSessionProperty_AudioInputAvailable)
	{
		if (inDataSize == sizeof(UInt32)) {
			UInt32 isAvailable = *(UInt32*)inData;
			// disable recording if input is not available
			THIS->btn_record.enabled = (isAvailable > 0) ? YES : NO;
		}
	}
}
	
- (void)volumeChanged:(NSNotification *)notification
{
    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    
    NSLog(@"volume = %g, nVolume = %g", volume, nVolume);
    // Do stuff with volume
    if (nVolume != volume * 100.0f) {
        [m_sldVolume setValue:volume * 100.0f];
        nVolume = (float)volume;
        //        [self setVolumeValue];
    }
}

- (void) updateVolume: (UISlider *) slider
{
    int nVal = (int)[slider value];
    nVolume = (float)nVal;
    [self setVolumeValue];
}

- (void) setVolumeValue
{
    int nVal = (int)nVolume;
    
    float fVolume = 1.0f * nVal / 100;
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:fVolume];
    
    //if( m_pRecorder != NULL )
      //  m_pRecorder->setMixVolume( fVolume );
}

#pragma mark Initialization routines
- (void)awakeFromNib
{		
	// Allocate our singleton instance for the recorder & player object
	isPause = FALSE;
    
    recorder = new AQRecorder();
	player = new AQPlayer();
    
    m_sldVolume.backgroundColor = [UIColor clearColor];
    [m_sldVolume setMaximumTrackImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sld_set_sound1.png" ofType:nil]] forState:UIControlStateNormal];
    [m_sldVolume setMaximumValue:100.0f];
    [m_sldVolume setMinimumTrackImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sld_set_sound.png" ofType:nil]] forState:UIControlStateNormal];
    [m_sldVolume setMinimumValue:0.0f];
    [m_sldVolume setThumbImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sld_set_thumb.png" ofType:nil]] forState:UIControlStateNormal];
    [m_sldVolume setValue:100.0f];
    [m_sldVolume addTarget:self action:@selector(updateVolume:) forControlEvents:UIControlEventValueChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(volumeChanged:) 
                                                 name:@"AVSystemController_SystemVolumeDidChangeNotification" 
                                               object:nil];
    nVolume = 100.0f;

    
	OSStatus error = AudioSessionInitialize(NULL, NULL, interruptionListener, self);
	if (error) printf("ERROR INITIALIZING AUDIO SESSION! %ld\n", error);
	else 
	{
		UInt32 category = kAudioSessionCategory_PlayAndRecord;	
		error = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
		if (error) printf("couldn't set audio category!");
		
        category = kAudioSessionOverrideAudioRoute_Speaker;
        error = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(category), &category);
        
		error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self);
		if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %ld\n", error);
		UInt32 inputAvailable = 0;
		UInt32 size = sizeof(inputAvailable);
		
		// we do not want to allow recording if input is not available
		error = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &inputAvailable);
		if (error) printf("ERROR GETTING INPUT AVAILABILITY! %ld\n", error);
		btn_record.enabled = (inputAvailable) ? YES : NO;
		
		// we also need to listen to see if input availability changes
		error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioInputAvailable, propListener, self);
		if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %ld\n", error);

		error = AudioSessionSetActive(true); 
		if (error) printf("AudioSessionSetActive (true) failed");
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackQueueStopped:) name:@"playbackQueueStopped" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackQueueResumed:) name:@"playbackQueueResumed" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingQueueStopped:) name:@"recordingQueueStopped" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingQueueResumed:) name:@"recordingQueueResumed" object:nil];

	UIColor *bgColor = [[UIColor alloc] initWithRed:.39 green:.44 blue:.57 alpha:0];
	[lvlMeter_in setBackgroundColor:bgColor];
	[lvlMeter_in setBorderColor:bgColor];
	[bgColor release];
	
	// disable the play button since we have no recording to play yet
	playbackWasInterrupted = NO;
	playbackWasPaused = NO;
}

# pragma mark Notification routines
- (void)playbackQueueStopped:(NSNotification *)note
{
     NSLog(@"playbackkQueueStopped");
	[lvlMeter_in setAq: nil];
	btn_record.enabled = YES;
}

- (void)playbackQueueResumed:(NSNotification *)note
{
    NSLog(@"playbackQueueResumed");
	btn_record.enabled = NO;
	[lvlMeter_in setAq: player->Queue()];
}

- (void)recordingQueueStopped:(NSNotification *)note
{
    NSLog(@"recordingQueueStopped");
 	[btn_record setImage:[UIImage  imageNamed:@"record_btnn.png"] forState:UIControlStateNormal];
	[lvlMeter_in setAq: nil];
}

- (void)recordingQueueResumed:(NSNotification *)note
{
    [btn_record setImage:[UIImage  imageNamed:@"pause_btnn.png"] forState:UIControlStateNormal];
    NSLog(@"recordingQueueResumed");
	[lvlMeter_in setAq: recorder->Queue()];
    // benvium: not sure what the buttton should say in this case
}

#pragma mark Cleanup
- (void)dealloc
{
	[btn_record release];
	[fileDescription release];
	[lvlMeter_in release];
	[passedTime release];
	delete player;
	delete recorder;
	
	[super dealloc];
}

@end
