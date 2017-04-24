//
//  CallHistoryViewController.m
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 12/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import "CallHistoryViewController.h"
#import "UtilityClass.h"
#import "AppDelegate.h"
#import "CallInfo.h"
#import "PlivoCallController.h"
#import "Phone.h"
#import "LoginViewController.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "CallKitInstance.h"
//#import "RecentsTableViewCell.h"

@interface CallHistoryViewController ()
@property (weak, nonatomic) IBOutlet UITableView* callHistoryTableView;
@property (weak, nonatomic) IBOutlet UILabel* noRecentCallsLabel;
- (IBAction)logoutButtonTapped:(id)sender;
@end

@implementation CallHistoryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //[CallInfo addCallInfo:@"siva170404101012"];
    //[CallInfo addCallInfo:@"iPhone5S170406073006"];
    //[CallInfo addCallInfo:@"iPhone6170406073331"];
    //[CallInfo addCallInfo:@"xlite170405101327"];
    
    [CallInfo addCallInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"xlite170405101327",@"CallId",[NSDate date],@"CallTime", nil]];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    if(!([CallInfo getCallsInfoArray].count > 0))
    {
        self.callHistoryTableView.hidden = YES;
        self.noRecentCallsLabel.hidden = NO;
        [self.view bringSubviewToFront:self.noRecentCallsLabel];
        
    }
    else
    {
        self.callHistoryTableView.hidden = NO;
        self.noRecentCallsLabel.hidden = YES;
        [self.view bringSubviewToFront:self.callHistoryTableView];
        [self.callHistoryTableView reloadData];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView Deleages, DataSources

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [CallInfo getCallsInfoArray].count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *editprofileIdentifier = @"CallHistory";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:editprofileIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:editprofileIdentifier];
        
    }
    
    NSArray* callInfoArray = [CallInfo getCallsInfoArray];
    NSDictionary* callInfo = callInfoArray[indexPath.row];

    cell.textLabel.text  = callInfo[@"CallId"];;
    cell.detailTextLabel.text = [self getStringFromDate:callInfo[@"CallTime"]];
    cell.imageView.image = [UIImage imageNamed:@"RecentCallIcon"];
    
    return cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    PlivoCallController* plivoVC = [self.tabBarController.viewControllers objectAtIndex:2];
    [[Phone sharedInstance] setDelegate:plivoVC];

    NSArray* callInfoArray = [CallInfo getCallsInfoArray];
    NSDictionary* callInfo = callInfoArray[indexPath.row];
    
    [CallKitInstance sharedInstance].callUUID = [NSUUID UUID];
    
    [plivoVC performStartCallActionWithUUID:[CallKitInstance sharedInstance].callUUID handle:callInfo[@"CallId"]];
    
    self.tabBarController.selectedViewController = [self.tabBarController.viewControllers objectAtIndex:2];

}

- (IBAction)logoutButtonTapped:(id)sender
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Logout"
                                 message:@"Are you sure you want to logout?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Yes"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle your yes please button action here
                                    
                                    PlivoCallController* plivoVC = [self.tabBarController.viewControllers objectAtIndex:2];
                                    [[Phone sharedInstance] setDelegate:plivoVC];
                                    [plivoVC unRegisterSIPEndpoit];
                                    self.tabBarController.selectedViewController = [self.tabBarController.viewControllers objectAtIndex:2];

                                }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"No"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle no, thanks button
                               }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (NSString *)getStringFromDate:(NSDate*)date
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    // set the date format related to what the string already you have

    [dateFormat setTimeZone:[NSTimeZone systemTimeZone]];
    // again add the date format what the output u need
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *finalDate = [dateFormat stringFromDate:date];    
    return finalDate;
}
@end



//    if ([cell isKindOfClass:RecentsTableViewCell.class])
//    {
//        NSArray* callInfoArray = [CallInfo getCallsInfoArray];
//        NSDictionary* callInfo = callInfoArray[indexPath.row];
//
//        RecentsTableViewCell *contactCell = (RecentsTableViewCell *)cell;
//        contactCell.contactLabel.text = callInfo[@"CallId"];
//        contactCell.timeLabel.text = [self getStringFromDate:callInfo[@"CallTime"]];
//    }

//    ContactsViewController* contactsVC = [self.tabBarController.viewControllers objectAtIndex:1];
//    [[Phone sharedInstance] setDelegate:contactsVC];
//    NSString *cellIdentifier = NSStringFromClass(RecentsTableViewCell.class);
//    UINib *nib = [UINib nibWithNibName:cellIdentifier bundle:NSBundle.mainBundle];
//    [self.callHistoryTableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
