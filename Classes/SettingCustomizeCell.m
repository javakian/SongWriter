//
//  CustomizeCell.m
//  CheckingList
//
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import "SettingCustomizeCell.h"
#import "GameUtils.h"

#import <AVFoundation/AVAudioPlayer.h>

@interface SettingCustomizeCell ()

@end

@implementation SettingCustomizeCell

@synthesize info;

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
}

-(void)removeCell
{
    [g_GameUtils removeLabelInfo:self.info];
}


-(void)showCell
{
    //self.lblID = self.info.index;
    self.textLabel.font = [UIFont systemFontOfSize:12];
    self.textLabel.text = self.info.label;
    
   if( self.info.check == 1 )
   {
     self.imageView.image = [UIImage  imageNamed:@"btn_check.png"];
   }
   else {
       self.imageView.image = nil;
   }
}

- (void)dealloc {
    [super dealloc];
}

@end