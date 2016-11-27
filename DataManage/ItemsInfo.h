//
//  AlarmInfo.h
//  WakeMe
//
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import <CoreData/CoreData.h>

#define _STR_DROPBOX_APPKEY_    @"w0wgz59mcbaz6wx"
#define _STR_DROPBOX_SECRET_    @"s1dzzn15z4v1dx5"

@interface MemoCellInfo : NSObject {
    int         index;
    int         seq;
    NSString    *date;
    NSString    *time;
    NSString    *memoLabel;
    NSString    *length;
    NSString    *file;
}

@property (nonatomic, retain)   NSString    *date;;
@property (nonatomic, retain)   NSString    *time;;
@property (nonatomic, retain)   NSString    *memoLabel;;
@property (nonatomic, retain)   NSString    *length;;
@property (nonatomic, retain)   NSString    *file;;

@property (nonatomic)           int         index;
@property (nonatomic)           int         seq;

@end

@interface LabelInfo : NSObject {
    int         index;
    int         check;
    NSString    *label;
}

@property (nonatomic, retain)   NSString    *label;;
@property (nonatomic)           int         index;
@property (nonatomic)           int         check;

@end

