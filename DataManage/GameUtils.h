//
//  GameUtils.h
//  MonkeyTime
//
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "ItemsInfo.h"
#import "CustomizeCell.h"

@interface GameUtils : NSObject {
    
	sqlite3*	database_all;
}

- (void)applicationWillTerminate;
- (void)writeEnvironment;
- (void)readEnvironment;
- (NSString*)ResNameForDevice:(NSString*) name;

- (void)openDB;
- (void)closeDB;

- (void)addCellInfo:(MemoCellInfo*)info;
- (NSArray*)getCellInfo:(NSString*)sql;
-(void)replaceMemoLabel:(NSString*)label index:(int)row;
- (void)removeCellInfo:(MemoCellInfo*)info;
- (void)removeMemoList;

- (void)addLabelInfo:(LabelInfo*)info;
- (NSArray*)getLabelInfo:(NSString*)sql;
- (void)removeLabelInfo:(LabelInfo*)info;
- (void)replaceLabelInfo:(LabelInfo*)info;
- (void)replaceLabel:(NSString*)str;
- (NSString*)getCheckedLabel;

-(void)sqlExecute:(NSString*)sql;

@end

extern GameUtils*	g_GameUtils;
extern CustomizeCell *g_cell;
extern int          g_firstRowNumber;
extern NSString*    g_groupName;
extern int          g_rowMemoNumber;

