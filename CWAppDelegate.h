//
//  CWAppDelegate.h
//  CardWiser
//
//  Created by Neuron 3/20/14.
//  Copyright (c) 2014 Neuron Solutions INC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MBProgressHUD;

@interface CWAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UINavigationController *navigationControler;

@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, strong) NSString *strAPNSToken;

@property (nonatomic, assign) int isPortraite;
@property (nonatomic, assign) BOOL bNetworkAvailable;

//=>    Global references
@property (nonatomic, strong) FBSession *session;
//@property (strong, nonatomic) User      *curUser;

//=>     Global reference to progressHUD. We will use it as hud in every screen
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, assign) NSUInteger uiNumberOfHUDs;

- (void)performLogout;

- (void)showProgressHUD;
- (void)hideProgressHUD;

@end

CWAppDelegate *appDelegate(void);


