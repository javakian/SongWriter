//
//  AlarmInfo.m
//  WakeMe
//
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import "ItemsInfo.h"
#import "GameUtils.h"


@implementation MemoCellInfo

@synthesize  index,seq,  date, time, memoLabel, length, file;
- (id)init {
	if(self == [super init]) {
        index = 0;
        seq = 1;
        date = @"";
        time = @"";
        memoLabel = @"Customize";
        length = @"0";
        file = @"";
	}
	return self;
}

@end

@implementation LabelInfo

@synthesize  index, check,  label;
- (id)init {
	if(self == [super init]) {
        index = 0;
        check = 0;
        label = @"Customize";
    }
	return self;
}

@end