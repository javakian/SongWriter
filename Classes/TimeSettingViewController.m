//
//  TimeSettingViewController.m
//  SpeakHere
//
//  Created by 陈玉亮 on 12-10-17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "TimeSettingViewController.h"

@interface TimeSettingViewController ()

@end

@implementation TimeSettingViewController

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
    // Do any additional setup after loading the view from its nib.
    
    BOOL check = [self getRepeat];
    
    if( check )
        [btnRepeat setImage:[UIImage  imageNamed:@"btn_check"] forState:UIControlStateNormal];
    else {
         [btnRepeat setImage:nil forState:UIControlStateNormal];
    }
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction)actionTimeSettingBack
{
    [self dismissModalViewControllerAnimated:TRUE];
}

- (void) setRepeat: (BOOL) bMute
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSNumber* aVolume  =	[NSNumber numberWithBool: bMute];	
	[defaults setObject:aVolume forKey:@"repeat"];
	[NSUserDefaults resetStandardUserDefaults];	
}

- (BOOL) getRepeat
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	return [defaults boolForKey:@"repeat"];
}

BOOL repeat = TRUE;

-(IBAction)actionRepeat
{
    repeat = !repeat;
    
    if( repeat )
        [btnRepeat setImage:[UIImage  imageNamed:@"btn_check"] forState:UIControlStateNormal];
    else {
        [btnRepeat setImage:nil forState:UIControlStateNormal];
    }
    [self setRepeat:repeat];
}
@end
