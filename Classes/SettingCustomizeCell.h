
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItemsInfo.h"

@interface SettingCustomizeCell : UITableViewCell<UITextFieldDelegate>{
    //db structure
    LabelInfo *info;
}

-(void)removeCell;
-(void)showCell;

@property(nonatomic,retain) LabelInfo *info;
@end
