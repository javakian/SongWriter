

#import <UIKit/UIKit.h>

@class SpeakHereController;

@interface SpeakHereViewController : UIViewController{
  
	IBOutlet SpeakHereController *controller;
    IBOutlet UIButton*	btn_memoList;
    
}
-(void)stopRecord;
-(IBAction)actionMemoList;

@end

