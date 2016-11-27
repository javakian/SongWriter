//
//  GameUtils.m
//  MonkeyTime
//
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import "GameUtils.h"

GameUtils*			g_GameUtils;
CustomizeCell *g_cell;
int g_firstRowNumber;
int          g_rowMemoNumber;
NSString*    g_groupName;

@implementation GameUtils

// on "init" you need to initialize your instance
- (id)init
{
	if( (self = [super init] )) {
		[self readEnvironment];
		[self openDB];
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}

- (void)readEnvironment {
}

- (void)writeEnvironment {
}

- (void)applicationWillTerminate {
	[self writeEnvironment];
}

#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (void) ensureDirs:(NSString*)path 
{
	NSFileManager* fileManager = [NSFileManager defaultManager];
	if([fileManager fileExistsAtPath:path]) {
		return;
	}
	[fileManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
}


#pragma mark database

- (void)openDB 
{
    if (database_all == NULL) {
        BOOL success;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"datas.sqlite"];
		NSLog(@"===========writableDB%@=========", writableDBPath);
        if ([fileManager fileExistsAtPath:writableDBPath] == NO) {
            NSString *defaultDBPath = [[NSBundle mainBundle] pathForResource:@"datas" ofType:@"sqlite"];
            
            NSLog(@"documentsDirectory = %@", documentsDirectory);
            NSLog(@"writableDBPath = %@", writableDBPath);
            NSLog(@"defaultDBPath = %@", defaultDBPath);
            
            success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
            if (!success) {
                NSCAssert1(0, @"Failed to create writable database_list file with message '%@'.", [error localizedDescription]);
            }
        }
		
        if (sqlite3_open([writableDBPath UTF8String], &database_all) != SQLITE_OK) {
            sqlite3_close(database_all);
            database_all = NULL;
            NSCAssert1(0, @"Failed to open database_list with message '%s'.", sqlite3_errmsg(database_all));
        }

        sqlite3_stmt *ppStmt;
        /*NSString *query = @"drop table checkingList";
        if( sqlite3_prepare_v2(database_all, [query UTF8String], -1, &ppStmt, NULL) == SQLITE_OK)
            sqlite3_step(ppStmt);
        sqlite3_finalize(ppStmt);
*/
        
        NSString* query = @"create table memoList(id int,date varchar(255), time varchar(255), memoLabel varchar(255), length varchar(255), file varchar(255))";
        if( sqlite3_prepare_v2(database_all, [query UTF8String], -1, &ppStmt, NULL) == SQLITE_OK)
            sqlite3_step(ppStmt);
        sqlite3_finalize(ppStmt);
        
        query = @"create table labelInfo(id int,checked int, label varchar(255))";
        if( sqlite3_prepare_v2(database_all, [query UTF8String], -1, &ppStmt, NULL) == SQLITE_OK)
            sqlite3_step(ppStmt);
        sqlite3_finalize(ppStmt);
        
	}
}

- (void)closeDB {
    if(database_all == NULL) 
		return;
	
    if(sqlite3_close(database_all) != SQLITE_OK) {
        NSCAssert1(0, @"Error: failed to close database_list with message '%s'.", sqlite3_errmsg(database_all));
    }
    database_all = NULL;
}

- (void)addCellInfo:(MemoCellInfo*)info {
	if(info == nil)
		return;
	if(database_all == nil)
		return;
	int nKey=0;
	
	NSString *sql = [NSString stringWithFormat:@"SELECT MAX(id) FROM memoList"];    	
	sqlite3_stmt *statement;
	if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
	{
		if (sqlite3_step(statement) == SQLITE_ROW) 
		{		
			nKey = sqlite3_column_int(statement,0);
		}
	}
	
	sqlite3_finalize(statement);
	nKey++;

	info.index = nKey;
    
	sql = [NSString stringWithFormat:@"insert into memoList(id, date, time, memoLabel, length, file) VALUES(%d, '%@','%@', '%@', '%@', '%@')",
					  nKey, info.date, info.time, info.memoLabel, info.length, info.file];
    
    
	sqlite3_prepare(database_all, [sql UTF8String], -1, &statement, NULL);    
	
    if(sqlite3_step(statement) != SQLITE_DONE ) 
		NSLog( @"Error: %s", sqlite3_errmsg(database_all) ); 
	else 
		NSLog( @"Insert into row id = %lld", sqlite3_last_insert_rowid(database_all)); 

	sqlite3_finalize(statement); 
}

-(void)replaceMemoLabel:(NSString*)label index:(int)row
{
	NSString *    sql = [NSString stringWithFormat:@"UPDATE memoList SET memoLabel = '%@' WHERE id=%d", 
                         label, row];
	
	sqlite3_stmt *statement;
	if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
		sqlite3_step(statement);
    
	sqlite3_finalize(statement);
    
}

- (NSArray*)getCellInfo:(NSString*)sql
{
	sqlite3_stmt* statement;
	id result;
	NSMutableArray* thisArray = [NSMutableArray arrayWithCapacity:9];
    
	if (sqlite3_prepare(database_all, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW) {
			NSMutableDictionary* thisDict = [NSMutableDictionary dictionaryWithCapacity:9];
			for (int i = 0; i < sqlite3_column_count(statement); i++) {
				if (sqlite3_column_type(statement, i) == SQLITE_TEXT)
					result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,i)];
				else if (sqlite3_column_type(statement,i) == SQLITE_INTEGER)
					result = [NSNumber numberWithInt:(int)sqlite3_column_int(statement,i)];

				if (result)
					[thisDict setObject:result forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement,i)]];
			}
			[thisArray addObject:[NSDictionary dictionaryWithDictionary:thisDict]];
		}
		sqlite3_step(statement);
	}
	sqlite3_finalize(statement);
    
	return thisArray;
}


- (void)removeCellInfo:(MemoCellInfo*)info {
	if(database_all == nil)
		return;
	
    NSString *str1;
    NSString *sql = [NSString stringWithFormat:@"SELECT file FROM memoList WHERE id=%d", info.index];
    sqlite3_stmt *statement;
    if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            str1 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,0)];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:str1]) {
                [[NSFileManager defaultManager] removeItemAtPath:str1 error:nil];
            }
        }
    }
    sqlite3_finalize(statement);

	sql = [NSString stringWithFormat:@"DELETE FROM memoList WHERE id=%d", info.index];
	
	if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
		sqlite3_step(statement);
}

- (void)removeMemoList {
	if(database_all == nil)
		return;
	
    NSString *str1;
    NSString *sql = [NSString stringWithFormat:@"SELECT file FROM memoList"];
    sqlite3_stmt *statement;
    if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            str1 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,0)];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:str1]) {
                [[NSFileManager defaultManager] removeItemAtPath:str1 error:nil];
            }
        }
    }
    sqlite3_finalize(statement);
    
	sql = [NSString stringWithFormat:@"DELETE FROM memoList"];
	
	if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
		sqlite3_step(statement);
}

- (void)addLabelInfo:(LabelInfo*)info {
	if(info == nil)
		return;
	if(database_all == nil)
		return;
	int nKey=0;
	
	NSString *sql = [NSString stringWithFormat:@"SELECT MAX(id) FROM labelInfo"];    	
	sqlite3_stmt *statement;
	if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
	{
		if (sqlite3_step(statement) == SQLITE_ROW) 
		{		
			nKey = sqlite3_column_int(statement,0);
		}
	}
	
	sqlite3_finalize(statement);
	nKey++;
    
	info.index = nKey;
    
	sql = [NSString stringWithFormat:@"insert into labelInfo(id, checked, label) VALUES(%d, %d, '%@')",
           nKey, info.check, info.label];
    
    
	sqlite3_prepare(database_all, [sql UTF8String], -1, &statement, NULL);    
	
    if(sqlite3_step(statement) != SQLITE_DONE ) 
		NSLog( @"Error: %s", sqlite3_errmsg(database_all) ); 
	else 
		NSLog( @"Insert into row id = %lld", sqlite3_last_insert_rowid(database_all)); 
    
	sqlite3_finalize(statement); 
}

- (NSString*)getCheckedLabel{
    
	if(database_all == nil)
		return nil;
	
	NSString *sql = [NSString stringWithFormat:@"SELECT label FROM labelInfo WHERE checked = 1"];    	
	sqlite3_stmt *statement;
	if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
	{
		if (sqlite3_step(statement) == SQLITE_ROW) 
		{		
			NSString *label = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,0)];
            sqlite3_finalize(statement);
            return label;
		}
	}
	
	return nil;
}

- (void)replaceLabelInfo:(LabelInfo*)info {
	if(database_all == nil)
		return;
	
	NSString *sql = [NSString stringWithFormat:@"UPDATE labelInfo SET checked = 0"];
	
	sqlite3_stmt *statement;
	if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
		sqlite3_step(statement);
    
	sqlite3_finalize(statement);
    
    sql = [NSString stringWithFormat:@"UPDATE labelInfo SET checked = 1 WHERE id=%d", 
					 info.index];
	
	if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
		sqlite3_step(statement);
    
	sqlite3_finalize(statement);
    
}

- (void)replaceLabel:(NSString*)str {
	if(database_all == nil)
		return;
	
	NSString *sql = [NSString stringWithFormat:@"UPDATE labelInfo SET checked = 0"];
	
	sqlite3_stmt *statement;
	if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
		sqlite3_step(statement);
    
	sqlite3_finalize(statement);
    
    sql = [NSString stringWithFormat:@"SELECT * FROM labelInfo WHERE label='%@'", str];
    
    NSString *sql1 = [NSString stringWithFormat:@"UPDATE labelInfo SET checked = 1 WHERE label='None'"];
    
    if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
    {
        sql1 = [NSString stringWithFormat:@"UPDATE labelInfo SET checked = 1 WHERE label='%@'", str];
    }
    sqlite3_finalize(statement);
    
    if (sqlite3_prepare(database_all,[sql1 UTF8String],-1,&statement,NULL) == SQLITE_OK)
        sqlite3_step(statement);
    
    sqlite3_finalize(statement);
}


- (NSArray*)getLabelInfo:(NSString*)sql
{
	sqlite3_stmt* statement;
	id result;
	NSMutableArray* thisArray = [NSMutableArray arrayWithCapacity:9];
    
	if (sqlite3_prepare(database_all, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW) {
			NSMutableDictionary* thisDict = [NSMutableDictionary dictionaryWithCapacity:9];
			for (int i = 0; i < sqlite3_column_count(statement); i++) {
				if (sqlite3_column_type(statement, i) == SQLITE_TEXT)
					result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,i)];
				else if (sqlite3_column_type(statement,i) == SQLITE_INTEGER)
					result = [NSNumber numberWithInt:(int)sqlite3_column_int(statement,i)];
                
				if (result)
					[thisDict setObject:result forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement,i)]];
			}
			[thisArray addObject:[NSDictionary dictionaryWithDictionary:thisDict]];
		}
		sqlite3_step(statement);
	}
	sqlite3_finalize(statement);
    
	return thisArray;
}


- (void)removeLabelInfo:(LabelInfo*)info {
	if(database_all == nil)
		return;
	
	NSString *sql = [NSString stringWithFormat:@"DELETE FROM labelInfo WHERE id=%d", info.index];
	
	sqlite3_stmt *statement;
	if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
		sqlite3_step(statement);
}


-(void)sqlExecute:(NSString*)sql
{
	if(database_all == nil)
		return;
	
	sqlite3_stmt *statement;
	if (sqlite3_prepare(database_all,[sql UTF8String],-1,&statement,NULL) == SQLITE_OK)
		sqlite3_step(statement);
    
	sqlite3_finalize(statement);
}
@end
