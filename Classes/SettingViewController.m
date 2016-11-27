//
//  SettingViewController.m
//  SpeakHere
//
//  Created by James Avakian on 6/10/16.
//  Copyright © 2016 OpticalAutomation. All rights reserved.
//

#import "SettingViewController.h"
#import "AddViewController.h"
#import "GameUtils.h"
#import "SettingCustomizeCell.h"

@interface SettingViewController ()

@end

@implementation SettingViewController
@synthesize tableView;
@synthesize isEdit;
@synthesize cellInfoList;

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
    self.cellInfoList = [[NSMutableArray alloc] init];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:TRUE];
    
    [self getCellListFromDB:@"SELECT * FROM labelInfo ORDER BY id ASC"];
    
    if( self.cellInfoList.count > 0 )
        [self.tableView reloadData];
    
    self.isEdit = FALSE;
    [self setTextEditButton:self.isEdit];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction)actionSettingEdit
{
    self.isEdit = !self.isEdit;
    self.tableView.editing = self.isEdit;
    [self setTextEditButton:self.isEdit];
    [self.tableView reloadData];
}

-(void)setTextEditButton:(BOOL)isEdit
{
    btnEdit.title = @"Edit";
    if( self.isEdit )
        btnEdit.title = @"Done";
}

-(IBAction)actionSettingAdd
{
    NSString* res_name = @"AddViewController";
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        res_name = @"AddViewController-iPad";
    else
    {
        if(IS_IPHONE_5)
            res_name = @"AddViewController_568h";
        else
            res_name = @"AddViewController";
    }
    
    AddViewController* memoController = [[AddViewController alloc] initWithNibName:res_name bundle:nil];
    [self presentViewController:memoController animated:YES completion:nil];
    [memoController release];
}

-(void)getCellListFromDB:(NSString*)sql
{
    if (self.cellInfoList != nil)
    { [self.cellInfoList removeAllObjects];}
    
    NSArray *array = [g_GameUtils getLabelInfo:sql];
    
    int nCount = array.count;
    if( nCount == 0 )
    {
        LabelInfo *info = [[[LabelInfo alloc]init] autorelease];
        info.label = @"None";
        info.check = 1;
        [g_GameUtils addLabelInfo:info];
    }
    
    array = [g_GameUtils getLabelInfo:sql];
    
    nCount = array.count;
    
    for (int i=0; i<nCount; i++) 
    {
        NSDictionary* dataDictionary = [array objectAtIndex:i];
        LabelInfo* info = [[[LabelInfo alloc] init] autorelease];
        
        NSNumber* number1 = [dataDictionary objectForKey:@"id"];
        info.index = [number1 unsignedIntValue];
        
        NSNumber* number2 = [dataDictionary objectForKey:@"checked"];
        info.check = [number2 unsignedIntValue];    
        
        NSString* str2 = [dataDictionary objectForKey:@"label"];
        info.label = str2;
        [self.cellInfoList addObject:info];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"===%d====", self.cellInfoList.count);
    return self.cellInfoList.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    SettingCustomizeCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        //cell = [[[exerciseListUITableCell alloc] init] autorelease];
        
        NSArray * topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"SettingCustomizeCell" owner:self options:nil];
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"SettingCustomizeCell-iPad" owner:self options:nil];
        for(id currentObject in topLevelObjects)
        {
            if([currentObject isKindOfClass:[UITableViewCell class]])
            {
                cell = (SettingCustomizeCell *)currentObject;
                //cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                break;
            }
        }        
    }
    
    [self getCellListFromDB:@"SELECT * FROM labelInfo ORDER BY id ASC"];
    
    LabelInfo *info = [self.cellInfoList objectAtIndex:[indexPath row]];
    [cell setInfo:info];
    [cell showCell];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( [indexPath row] == 0 )
    {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Notice" message:@"This is Default Label" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        SettingCustomizeCell *cell = (SettingCustomizeCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell removeCell];
        [self getCellListFromDB:@"SELECT * FROM labelInfo ORDER BY id ASC"];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadData];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSDate *object = [_objects objectAtIndex:indexPath.row];
    SettingCustomizeCell *cell = (SettingCustomizeCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    
    g_groupName = cell.info.label;
    
    [g_GameUtils replaceLabelInfo:cell.info];
    [self.tableView reloadData];
    
    if( g_rowMemoNumber != -100)
    {
        g_groupName = @"None";
        [g_GameUtils replaceMemoLabel:cell.info.label index:g_rowMemoNumber];
    }

    [self dismissModalViewControllerAnimated:TRUE];
}


@end
