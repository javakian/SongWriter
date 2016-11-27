//
//  CustomizeCell.m
//  CheckingList
//
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import "CustomizeCell.h"
#import "GameUtils.h"
#import "VoiceMemoListViewController.h"
#import "SpeakHereAppDelegate.h"

#import <AVFoundation/AVAudioPlayer.h>

@interface CustomizeCell ()

@end

@implementation CustomizeCell

@synthesize btnCheck;
@synthesize lblID;
@synthesize lblMeeting;
@synthesize lblTime;
@synthesize lblLength;
@synthesize startFlag;
@synthesize info;
@synthesize delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code.
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state.
}

-(IBAction)clickBtn:(id)sender
{
    g_cell = self;
    g_firstRowNumber = self.info.seq;
    g_groupName = self.info.memoLabel;
    if( self.startFlag )
    {
        for (id cell in self.superview.subviews)
        {
            if([cell isKindOfClass:[CustomizeCell class]])
                [cell stopAudio];
        }
        [self startAudio];
    }
    else {
        [self.btnCheck setImage:[UIImage  imageNamed:@"startt.png"] forState:UIControlStateNormal];
        [delegate stopAudio];
        self.startFlag = TRUE;
    }
}

-(void)startAudio
{
    [self.btnCheck setImage:[UIImage  imageNamed:@"stopp.png"] forState:UIControlStateNormal];
    [delegate initAudio:self.info.file];
    [delegate playAudio];
    self.startFlag = FALSE;
}

-(void)stopAudio
{
    self.startFlag = TRUE;
    [self.btnCheck setImage:[UIImage  imageNamed:@"startt.png"] forState:UIControlStateNormal];
    [delegate stopAudio];
}

-(void)removeCell
{
    [g_GameUtils removeCellInfo:self.info];
    //[self.info release];
}

-(void)showCell
{
    //self.lblID = self.info.index;
    self.startFlag = TRUE;
    self.lblID.text = [NSString stringWithFormat:@"%d", self.info.seq];
    self.lblLength.text = self.info.length;
    self.lblMeeting.text = self.info.memoLabel;
    self.textLabel.text = self.info.memoLabel;
    self.textLabel.hidden = TRUE;
    
    if( [self.lblMeeting.text isEqualToString:@"None"])
    {
        self.lblMeeting.text = self.info.date;
        self.lblTime.text = self.info.time;
    }
    else
        self.lblTime.text = [NSString stringWithFormat:@"%@ %@", self.info.date, self.info.time];
}

- (void)dealloc {
    [super dealloc];
}

@end