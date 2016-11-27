//
//  SettingViewController.h
//  SpeakHere
//
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
{
IBOutlet UITableView *tableView;
IBOutlet UIBarButtonItem *btnEdit;
}

@property(nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) BOOL isEdit;
@property (nonatomic, retain) NSMutableArray *cellInfoList;

-(IBAction)actionSettingEdit;
-(IBAction)actionSettingAdd;
-(void)setCell:(NSString*)label;
@end
