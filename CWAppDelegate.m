//
//  CWAppDelegate.m
//  CardWiser
//
//  Created by Neuron 3/20/14.
//  Copyright (c) 2014 Neuron Solutions INC. All rights reserved.
//

#import "CWAppDelegate.h"
#import "PayPalMobile.h"
#import "AFNetworkActivityIndicatorManager.h"

@implementation CWAppDelegate

NSDictionary *returnDict;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //*>    Track Network Status
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        self.bNetworkAvailable = (status == AFNetworkReachabilityStatusNotReachable) ? NO:YES;
        
        CWLog(@"Network Reachability: %@, \n status:%ld", AFStringFromNetworkReachabilityStatus(status), (long)status);
        
    }];
    
    //=>    Enable Activity Indicator Spinner
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
 
    //=>    Setup globad variable to be used for saving in user defaults
    self.defaults = [NSUserDefaults standardUserDefaults];
    
    [[Engin shared] declerationAllInstanceVAriable];
    
     //=>   Initialize PayPal Mobile SDK for Sandbox Environment
    [PayPalMobile initializeWithClientIdsForEnvironments:@{PayPalEnvironmentProduction :kPayPalClientId,PayPalEnvironmentSandbox : kPayPalClientId}];
    
    //=>    Customize StatusBar
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [application setStatusBarStyle:UIStatusBarStyleLightContent];
    
    self.navigationControler.interactivePopGestureRecognizer.enabled = NO;

    _isPortraite = 0;

    NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:4*1024*1024
                                                      diskCapacity:32*1024*1024
                                                          diskPath:@"app_cache"];
    
    //=>    Set the shared cache to our new instance
    [NSURLCache setSharedURLCache:cache];
    
    [FBLoginView class];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    //=>    Need to get the response from the payment when it is done and log it.
    
    CWLog(@"open URL : %@", [url absoluteString]);

    //=>    Parse the return URL to isolate pay_id and complete status
    returnDict = [self parseUrlString:[url absoluteString]];

    //=>    Send notification to resign webview
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:k_Payment_Success object:nil userInfo:returnDict]];
    
    //=>    Get pay_id and completed status from dictionary
    NSString *payID     = [returnDict valueForKey:@"pay_id"];
    NSString *completed = [returnDict valueForKey:@"completed"];
    
    CWLog(@"PayID = %@ status = %@", payID, completed);
    
    return [FBSession.activeSession handleOpenURL:url];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    //=>    Close Active FB Session
    [[FBSession activeSession] close];
}

-(NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if (_isPortraite == 11)
    {
        return UIInterfaceOrientationMaskLandscapeRight;
    }
    else
    {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // Handle the user leaving the app while the Facebook login dialog is being shown
    // For example: when the user presses the iOS "home" button while the login dialog is active
    //[FBAppCall handleDidBecomeActive];

}

#pragma mark - Custom Methods

/**
 **     Parse and Return PaymentId and Payment Status from Return URL
 **/
- (NSDictionary *)parseUrlString:(NSString *)urlString
{
    //=>    Get last path and log (return URL)
    NSString *lastPath = [urlString lastPathComponent];
    CWLog(@"last path = %@",lastPath);
    
    //=>    Remove question mark from path
    lastPath = [lastPath stringByReplacingCharactersInRange:NSMakeRange(0, 0) withString:@""];
    
    //=>    Create new dictionary to store parsed peices of
    NSMutableDictionary *newDict = [NSMutableDictionary new];
    
    //=>    Create array by separating path components
    NSArray *pathComponents = [lastPath componentsSeparatedByString:@"&"];
    
    //=>    Separeate key and value pars by parsing at = sign
    for (NSString *keyValuePair in pathComponents) {
        
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key           = [pairComponents objectAtIndex:0];
        NSString *value         = [pairComponents objectAtIndex:1];
        
        [newDict setObject:value forKey:key];
    }
    
    return newDict;
}

- (void)performLogout
{
    //=>    Clear current FB token
    [FBSession.activeSession closeAndClearTokenInformation];
    
    //=>    Remove current user's id from UserDef
    [self.defaults removeObjectForKey:k_UserDef_LoggedInUserID];
    
    //=>    Reset current user
    //self.curUser = nil;
    
    [self.defaults synchronize];
}


#pragma mark - MBProgressHUD Methods

- (void)showProgressHUD
{
    if (appDelegate().uiNumberOfHUDs == 0)
    {
        //=>    Show progress HUD
        [appDelegate() setProgressHUD:[MBProgressHUD showHUDAddedTo:appDelegate().window animated:YES]];
        [appDelegate() setNewLabelText:@"Please Wait" andNewDescriptionText:@""];
    }
    
    appDelegate().uiNumberOfHUDs++;
}

- (void)hideProgressHUD
{
    appDelegate().uiNumberOfHUDs--;
    
    if (appDelegate().uiNumberOfHUDs == 0)
    {
        //>     Hide progressHUD
        [appDelegate().progressHUD hide:YES];
    }
}

- (void)setNewLabelText:(NSString *)strLabelText andNewDescriptionText:(NSString *)strDescriptionText
{
    appDelegate().progressHUD.removeFromSuperViewOnHide         = YES;
    appDelegate().progressHUD.mode                              = MBProgressHUDModeIndeterminate;
    //appDelegate().progressHUD.labelText                         = strLabelText;
    //appDelegate().progressHUD.detailsLabelText                  = strDescriptionText;
    //appDelegate().progressHUD.labelText                         = @"Accessing Server";
    //appDelegate().progressHUD.detailsLabelText                  = @"";
    [appDelegate().progressHUD setNeedsDisplay];
}

@end

#pragma mark - Convenience Constructors
CWAppDelegate *appDelegate(void)
{
    return (CWAppDelegate *)[[UIApplication sharedApplication] delegate];
}


