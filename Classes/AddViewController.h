//
//  AddViewController.h
//  SpeakHere
//
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddViewController : UIViewController
{
    IBOutlet UITextField *textField;
}

-(IBAction)actionSave;
-(IBAction)actionClose;
@end
