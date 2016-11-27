

#import <Foundation/Foundation.h>

#import "AQLevelMeter.h"

#import "AQPlayer.h"
#import "AQRecorder.h"


@interface SpeakHereController : NSObject {

	IBOutlet UIButton*	btn_record;
	IBOutlet UILabel*			fileDescription;
    IBOutlet UILabel*			passedTime;
	IBOutlet AQLevelMeter*		lvlMeter_in;
    IBOutlet UISlider*          m_sldVolume;
    
	AQPlayer*					player;
	AQRecorder*					recorder;
	BOOL						playbackWasInterrupted;
 	BOOL						recordingWasInterrupted;
	BOOL						playbackWasPaused;
	BOOL                        isPause;
    float                       nVolume;
    
	CFStringRef					recordFilePath;	
    
    NSTimer *controlVisibilityTimer;
}

@property (nonatomic, retain)	UIButton		*btn_record;
@property (nonatomic, retain)	UILabel				*fileDescription;
@property (nonatomic, retain)	UILabel				*passedTime;
@property (nonatomic, retain)	AQLevelMeter		*lvlMeter_in;
@property (nonatomic, retain)	UISlider*          m_sldVolume;


@property (readonly)			AQPlayer			*player;
@property (readonly)			AQRecorder			*recorder;
@property						BOOL				playbackWasInterrupted;

- (IBAction)record: (id) sender;
- (IBAction)play: (id) sender;
- (void)stopRecord;
@end
