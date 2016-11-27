//
//  AddViewController.m
//  SpeakHere
//
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import "AddViewController.h"
#import "GameUtils.h"
@interface AddViewController ()

@end

@implementation AddViewController

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

-(IBAction)actionSave
{
    if( [textField.text length] == 0)
    {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Notice" message:@"Empty Label" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    LabelInfo *info = [[[LabelInfo alloc]init] autorelease];
    info.label = textField.text;
    [g_GameUtils addLabelInfo:info];
    
    [self dismissModalViewControllerAnimated:TRUE];
}

-(IBAction)actionClose
{
    [self dismissModalViewControllerAnimated:TRUE];
}

@end
