//
//  CustomizeCell.h
//  CheckingList
//
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItemsInfo.h"

@class VoiceMemoListViewController;

@interface CustomizeCell : UITableViewCell<UITextFieldDelegate>{
    IBOutlet UIButton *btnCheck;
    IBOutlet UILabel *lblID;
    IBOutlet UILabel *lblMeeting;
    IBOutlet UILabel *lblTime;
    IBOutlet UILabel *lblLength;
    
    VoiceMemoListViewController *delegate;
    //db structure
    MemoCellInfo *info;
    
    BOOL startFlag;
}

-(IBAction)clickBtn:(id)sender;
-(void)startAudio;
-(void)stopAudio;
-(void)removeCell;
-(void)showCell;

@property (nonatomic, retain) VoiceMemoListViewController*      delegate;
@property (nonatomic)BOOL startFlag;
@property(nonatomic,retain) MemoCellInfo *info;
@property(nonatomic,retain)IBOutlet UIButton *btnCheck;
@property(nonatomic,retain)IBOutlet UILabel *lblID;
@property(nonatomic,retain)IBOutlet UILabel *lblMeeting;
@property(nonatomic,retain)IBOutlet UILabel *lblTime;
@property(nonatomic,retain)IBOutlet UILabel *lblLength;


@end
