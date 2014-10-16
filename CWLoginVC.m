//
//  CWLoginVC.m
//  CardWiser
//
//  Created by Neuron 3/26/14.
//  Copyright (c) 2014 Neuron Solutions INC. All rights reserved.
//

#import "CWLoginVC.h"
#import "CWHomeVC.h"

@interface CWLoginVC () <FBLoginViewDelegate>
{
    bool bRememberMe;       //*>    Save email and password if |bRememberMe = true|
}

@property (weak, nonatomic) IBOutlet UIButton       *btnChecked;
@property (weak, nonatomic) IBOutlet UIButton       *btnRegister;
@property (weak, nonatomic) IBOutlet UIButton       *btnGuest;
@property (weak, nonatomic) IBOutlet UIButton       *btnFacebook;

@property (weak, nonatomic) IBOutlet UITextField    *txfEmail;
@property (weak, nonatomic) IBOutlet UITextField    *txfPassword;

@property (weak, nonatomic) IBOutlet UIView         *viewLoginErrorAlert;

@property (assign, nonatomic) BOOL                  bFacebookLogin;

@end

@implementation CWLoginVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignAllResponders)];
    [self.view addGestureRecognizer:gesture];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    self.navigationController.navigationBar.hidden  = YES;
    
    //*>    If email and password are saved then lgoin with saved credential
    NSMutableDictionary *getUserInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:[Util getFilePathFromDocumentDirectoryForFileName:@"remember"]];
    
    if (getUserInfo)
    {
        bRememberMe                  = true;
        
        self.btnChecked.selected     = YES;
        
        self.txfEmail.text           = [getUserInfo valueForKey:@"Email"];
        self.txfPassword.text        = [getUserInfo valueForKey:@"Pass"];
        
        if(![Engin shared].bUserLoggedIn)
        {
            [self startCallToLoginUser:false];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    
    self.txfEmail.backgroundColor       = [UIColor colorWithPatternImage:[UIImage imageNamed:@"long_txt_feild.png"]];
    self.txfPassword.backgroundColor    = [UIColor colorWithPatternImage:[UIImage imageNamed:@"long_txt_feild.png"]];

    self.txfPassword.text               = @"";
    self.txfEmail.text                  = @"";
    
    self.btnGuest.frame                 = CGRectMake(165, 349, 137, 40);
    self.btnRegister.frame              = CGRectMake(18, 349, 137, 40);

    self.btnFacebook.hidden             = NO;
    self.viewLoginErrorAlert.hidden               = YES;
    
    self.btnChecked.selected            = NO;
    
    [self.txfPassword resignFirstResponder];
    [self.txfEmail resignFirstResponder];
}

#pragma mark - Custom Methods
/**
 **     Archive and save |userDetail| dictionary into "userDetail" file at documentDirectory
 **/
- (void)archiveMe
{
    CWLog(@"%@",[Engin shared].cwUserDetail);
    
    [NSKeyedArchiver archiveRootObject:[Engin shared].cwUserDetail toFile:[Util getFilePathFromDocumentDirectoryForFileName:@"userDetail"]];
}

/**
 **     Save email and password
 **/
- (void)rememberMe
{
    NSMutableDictionary *saveLoginInfo = [[NSMutableDictionary alloc] init];
    [saveLoginInfo setValue:self.txfEmail.text forKey:@"Email"];
    [saveLoginInfo setValue:self.txfPassword.text forKey:@"Pass"];
    
    [NSKeyedArchiver archiveRootObject:saveLoginInfo toFile:[Util getFilePathFromDocumentDirectoryForFileName:@"remember"]];
}

/**
 **     Remove saved email and password
 **/
- (void)unRememberMe
{
    [NSKeyedArchiver archiveRootObject:nil toFile:[Util getFilePathFromDocumentDirectoryForFileName:@"remember"]];
}

/**
 **     Check fields are filled with text if no, show alert
 **/
- (BOOL)canLogin
{
    if (self.bFacebookLogin)
    {
        BOOL bLogin                     = [Engin shared].fb_userEmail && [Engin shared].fb_userID;
        if (!bLogin)
        {
            [CWAlertView showOkAlertWithTitle:@"Attention" message:@"Required feilds are empty!"];
        }
        return bLogin;
    }
    //*>     Verify email field if is not empty
    NSString *strTextFieldText          =   [self.txfEmail.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (strTextFieldText == (id)[NSNull null] || strTextFieldText.length == 0)
    {
        [CWAlertView showOkAlertWithTitle:@"Attention" message:@"Please enter Username!"];
        return NO;
    }
    
    //*>     Verify Password field if is not empty
    strTextFieldText                    = [self.txfPassword.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ( strTextFieldText == (id)[NSNull null] || strTextFieldText.length == 0 )
    {
        [CWAlertView showOkAlertWithTitle:@"Attention" message:@"Password field cannot be empty!"];
        return NO;
    }
    
    return YES;
}

/**
 **     Check if we can log in then call API
 **/
- (void)doLogin
{
    if (![self canLogin])
    {
        return;
    }
    
    //*>     Hide keyboards
    [self resignAllResponders];
    
    //*>     Call api for login
    [self loginAPI_Call];
}

/**
 **     Hide keyboard.
 **/
- (void)resignAllResponders
{
    if ([self.txfEmail isFirstResponder])
        [self.txfEmail resignFirstResponder];
    if ([self.txfPassword isFirstResponder])
        [self.txfPassword resignFirstResponder];
}

/**
 **     Show Animation when move into textFields
 **/
- (void)animationViewBottomToTop:(BOOL)up :(int)movementDistance
{
    int movement = up ? -movementDistance : movementDistance;
    
    [UIView beginAnimations:@"textField" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.50];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

#pragma mark - API Methods
- (void)startCallToLoginUser:(BOOL)facebookLogin
{
    self.bFacebookLogin = facebookLogin;
   
    //*>    Check and then call API
    [self doLogin];
}

/**
 **     Calls Login API.
 **/
- (void)loginAPI_Call
{
    [Engin shared].bUserLoggedIn     = NO;
    //*>    Check network status if available then proceed otherwise show alert.
    if (![appDelegate() bNetworkAvailable])
    {
        [CWAlertView showNetWorkAlert];
        return;
    }
    
    //*>     Show HUD
    [appDelegate() showProgressHUD];
    
    NSString *loginURl;
    NSDictionary *dictParams = nil;
    
    //*>    Build parameters dictionary
    if (self.bFacebookLogin)
    {
        dictParams =   @{
                                 @"username"   :   [ Engin shared].fb_userEmail,
                                 @"fb_id"      :   [Engin shared].fb_userID
                        };
        loginURl = k_API_User_FBLogin;
    }
    else
    {
        dictParams =     @{
                               @"username"   :   self.bFacebookLogin ? [Engin shared].fb_userEmail : self.txfEmail.text,
                               @"password"   :   self.bFacebookLogin ? [Engin shared].fb_userID : self.txfPassword.text
                           };
        loginURl = k_API_User_Login;
    }
    
    CWLog(@"Performing %@ api Request",loginURl);
    
    [[PVNetworkingClient sharedClient] POST:loginURl
                                 parameters:dictParams
                                    success:^(NSURLSessionDataTask *task, id responseObject)
     {
         CWLog(@"%@ Response: %@", loginURl, responseObject);
         
         PVAPI_ResponseModel *responseModel = [[PVAPI_ResponseModel alloc] init];
         [responseModel handleResponse:responseObject];
         
         if (responseModel.error == nil)
         {
             //*>    Set user data in Engin after getting suceess response from Cardwiser API
             [Engin shared].bUserLoggedIn     = YES;
            
             if (bRememberMe)
             {
                 [Engin shared].savePassword  = self.txfPassword.text;
             }
             
             [Engin shared].cwUserDetail        = [responseModel.data objectForKey:@"data"];
             
             [Engin shared].i_memID             = [[[Engin shared].cwUserDetail valueForKey:@"mem_id"] intValue];
             [Engin shared].i_userID            = [[[Engin shared].cwUserDetail valueForKey:@"user_id"] intValue];
             
             if (self.bFacebookLogin)
             {
                 [[Engin shared].cwUserDetail setValue:[Engin shared].strUserFirstNameFB forKey:@"first_name"];
                 [[Engin shared].cwUserDetail setValue:[Engin shared].strUserLastNameFB forKey:@"last_name"];
             }
             
             [self archiveMe];
             
             CWHomeVC *homeVC = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CWHomeVC class])];
             [self.navigationController pushFadeViewController:homeVC];
         }
         else
         {
             self.btnFacebook.hidden             = YES;
             self.viewLoginErrorAlert.hidden               = NO;
             
             self.btnGuest.frame                 = CGRectMake(165, 299, 137, 40);
             self.btnRegister.frame              = CGRectMake(18, 299, 137, 40);
             
             self.txfEmail.backgroundColor       = [UIColor colorWithPatternImage:[UIImage imageNamed:@"long_txt_feild_black.png"]];
             self.txfPassword.backgroundColor    = [UIColor colorWithPatternImage:[UIImage imageNamed:@"long_txt_feild_black.png"]];
             
             //*>    Display an alert with error message
             [CWAlertView showOkAlertWithTitle:@"Error" message:responseModel.error.strMessage];
         }
         
         //*>   Hide HUD
         [appDelegate() hideProgressHUD];
     }
     failure:^(NSURLSessionDataTask *task, NSError *error)
     {
         CWLog(@"%@ Error: %@", k_API_User_Login, error.description);
         
         //*>    Display an alert with error message
         [CWAlertView showOkAlertWithTitle:@"Error" message:error.localizedDescription];
         
         //*>   Hide HUD
         [appDelegate() hideProgressHUD];
     }];
}

#pragma mark - Action Methods
/**
 **     Change |btnChecked| selection state and |bRememberMe| value
 **/
- (IBAction)btnRemeberMe_Action:(UIButton *)sender
{
    bRememberMe                 = !bRememberMe;
    self.btnChecked.selected    = !self.btnChecked.selected;
}

- (IBAction)btnLogIn_Action:(id)sender
{
    [self startCallToLoginUser:NO];
}

/**
 **     SignIn with Facebook.
 **/
- (IBAction)btnSignInWithFacebook_Action:(id)sender
{
    bRememberMe                         = !bRememberMe;
    self.btnChecked.selected            = !self.btnChecked.selected;
    
    self.txfPassword.text               = @"";
    self.txfEmail.text                  = @"";
    
    [self resignAllResponders];

    if ([FBSession.activeSession isOpen])
    {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id<FBGraphUser> user, NSError *error)
        {
            //*>    Set user data in Engin after getting success response from Facebook
            [Engin shared].fb_userEmail        = [user objectForKey:@"email"];
            [Engin shared].fb_userID           = user.id;
             
            [Engin shared].strUserFirstNameFB  = user.first_name;
            [Engin shared].strUserLastNameFB   = user.last_name;
            [Engin shared].strUserName         = user.username;
            
            CWLog(@"usr_id::%@ \n usr_first_name::%@ \n usr_middle_name::%@ \n usr_last_name::%@ \n usr_Username::%@ \n usr_b_day::%@ \n usr_email::%@",user.id, user.first_name, user.middle_name, user.last_name, user.username, user.birthday, [user objectForKey:@"email"]);
             
            [self startCallToLoginUser:YES];
         }];
    }
    else
    {
        //*>    Request for open active facebook session with desired permission
        if (![FBSession.activeSession isOpen])
        {
            NSArray *permissions             = [[NSArray alloc] initWithObjects:@"email", @"user_location", @"public_profile",nil];
            
            [FBSession openActiveSessionWithReadPermissions:permissions
                                               allowLoginUI:YES
                                          completionHandler:
             ^(FBSession *session, FBSessionState state, NSError *error) {
                 CWLog(@"FBSessionState: %u",state);
                 
                //*>    If the session was opened successfully
                 if (!error && state == FBSessionStateOpen)
                 {
                     NSLog(@"Session opened");
                     [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection,
                                                                            id<FBGraphUser> user,
                                                                            NSError *error) {
                         //*>    Set user data in Engin after getting success response from Facebook
                         [Engin shared].fb_userEmail        = [user objectForKey:@"email"];
                         [Engin shared].fb_userID           = user.id;
                         
                         [Engin shared].strUserFirstNameFB  = user.first_name;
                         [Engin shared].strUserLastNameFB   = user.last_name;
                         [Engin shared].strUserName         = user.username;
                         
                         CWLog(@"usr_id::%@ \n usr_first_name::%@ \n usr_middle_name::%@ \n usr_last_name::%@ \n usr_Username::%@ \n usr_b_day::%@ \n usr_email::%@",user.id, user.first_name, user.middle_name, user.last_name, user.username, user.birthday, [user objectForKey:@"email"]);
                         
                         //*>   Perform Login user api call
                         [self startCallToLoginUser:YES];
                     }];
                 }
                 
                 if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed)
                 {
                     CWLog(@"Session closed");
                 }
                 
                 //*>   Handle errors
                 if (error)
                 {
                     CWLog (@"Error");
                     
                     [CWAlertView showOkAlertWithTitle:@"There are some problem in login with facebook" message:error.localizedDescription];
                     
                     //*>   Clear this token
                     [FBSession.activeSession closeAndClearTokenInformation];
                 }
             }];
        }
    }
}

/**
 **     Unwind to Login Screen.
 **/
- (IBAction)unwindToLogin_Action:(UIStoryboardSegue*)sender
{
    
}

#pragma mark - UITextFieldDelegate Methods
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.btnGuest.frame                 = CGRectMake(165, 349, 137, 40);
    self.btnRegister.frame              = CGRectMake(18, 349, 137, 40);
    
    self.txfEmail.backgroundColor       = [UIColor colorWithPatternImage:[UIImage imageNamed:@"long_txt_feild.png"]];
    self.txfPassword.backgroundColor    = [UIColor colorWithPatternImage:[UIImage imageNamed:@"long_txt_feild.png"]];

    self.btnFacebook.hidden             = NO;
    self.viewLoginErrorAlert.hidden               = YES;

    if (textField == self.txfPassword)
    {
        [self animationViewBottomToTop:YES :60];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.txfPassword)
    {
        [self animationViewBottomToTop:NO :60];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.txfEmail)
    {
        [self.txfPassword becomeFirstResponder];
    }
    else
        if (textField == self.txfPassword)
        {
            [textField resignFirstResponder];
            
            //*>     Do login
            [self doLogin];
        }
    return YES;
}

#pragma mark - Memory Cleanup
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
