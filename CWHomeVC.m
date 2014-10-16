//
//  CWHomeVC.m
//  CardWiser
//
//  Created by Neuron 3/26/14.
//  Copyright (c) 2014 Neuron Solutions INC. All rights reserved.
//

#import "CWHomeVC.h"
#import "CWBuyGiftCardsSecondProcessVC.h"
#import "CWSettingsVC.h"
#import "CWEditProfileVC.h"
#import "CWWithDrawFundsVC.h"
#import "CWMyListingVC.h"
#import "CWLoginVC.h"
#import "CWMyPurchaseCardsVC.h"
#import "CWWithDrawFundsVC.h"
#import "CWPurchaseNexusCoinsVC.h"
#import "CWLabelNexusCoins.h"
#import "CWCardAnnotation.h"
#import <MapKit/MapKit.h>


//*>    Define macros for MyCard that display on Home Screen
#define kCardBrandName              @"Card Brand Name"
#define kCardImageUrl               @"Card ImageUrl"
#define kCardStoreLocationLat       @"Card Store Lat"
#define kCardStoreLocationLong      @"Card Store Long"

@interface CWHomeVC () <CLLocationManagerDelegate>
{
    UISwipeGestureRecognizer    *swipeMenuLeft;
    UISwipeGestureRecognizer    *swipeMenuRight;
    CLLocationManager           *locationManager;
}

@property (weak, nonatomic) IBOutlet UIView *viewMain;
@property (weak, nonatomic) IBOutlet UIView *viewSideMenu;
@property (weak, nonatomic) IBOutlet UITableView *tblMenu;
@property (weak, nonatomic) IBOutlet UIButton *btnSideMenu;
@property (weak, nonatomic) IBOutlet CWLabelNexusCoins *lblBalance;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) NSArray               *arrMenuViewTitles;
@property (strong, nonatomic) NSArray               *arrMenuViewImages;
@property (strong, nonatomic) NSArray               *arrMenuViewSelectedImages;
@property (nonatomic, strong) NSMutableArray        *arrMycards;
@property (nonatomic, strong) NSMutableArray        *arrMapAnnotations;

@end

@implementation CWHomeVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //*>    Initilize LocationManager
    locationManager                 = [[CLLocationManager alloc] init];
    locationManager.delegate        = self;
    self.mapView.showsUserLocation  = YES;
    //*>   We don't want to be notified of small changes in location, Update after movements of 500 meter
    locationManager.distanceFilter  = 500;
    
    //*>    Intialize menu title array
    self.arrMenuViewTitles          = [[NSArray alloc] initWithObjects:@"Home", @"My Profile", @"My Cards", @"My Listings", @"Nexus Coins", @"Withdraw Funds", @"Settings", @"Logout", nil];
    
    //*>    Intialize menu icon array with images
    self.arrMenuViewImages          = [[NSArray alloc] initWithObjects:@"home_icon.png", @"profile_icon.png", @"mycards_icon.png", @"listing_icon.png", @"nc_coin_icon.png", @"withdraw_icon.png", @"settings_icon.png", @"logout_icon.png",nil];
    
    //*>    Intialize menu icon array with selected images
    self.arrMenuViewSelectedImages  = [[NSArray alloc] initWithObjects:@"home_selected_icon.png", @"profile_selected_icon.png", @"mycards_selected_icon.png", @"listing_selected_icon.png", @"nc_coin_selected_icon.png", @"withdraw_selected_icon.png", @"settings_selected_icon.png", @"logout_selected_icon.png",nil];
    
    //*>    Set balance with Nexus coin on label
    NSInteger balance     = [[[Engin shared].cwUserDetail valueForKey:@"available_funds"] integerValue];
    self.lblBalance.text  = [NSString localizedStringWithFormat:@"Balance: %ld %@", (long)balance, kNexusCoinImage];
    
    [self.tblMenu reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    //*>    Start getting location update
    [locationManager startUpdatingLocation];
    
    //*>    Add SwipeGestureRecognizer
    swipeMenuLeft               = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeToLeft)];
    [swipeMenuLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [[self view] addGestureRecognizer:swipeMenuLeft];
    
    swipeMenuRight              = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeToRight)];
    [swipeMenuRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [[self view] addGestureRecognizer:swipeMenuRight];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
     //*>    Stop getting location update
    [locationManager stopUpdatingLocation];
}

#pragma mark - Custom Methods
/**
 **     Show  markers for the stores who's cards are available in Cardwiser that are within 2 mile radius of where the user is at.
 **/
- (void)displayCardsAnnotationOnMap
{
    self.arrMapAnnotations = [NSMutableArray new];
    //*>    TODO Remove: Test Data: For testing purpose
    /////////////
    //CLLocationCoordinate2D sanFrancisco = CLLocationCoordinate2DMake(37.786996, -122.419281);
    CLLocationCoordinate2D sanFrancisco = CLLocationCoordinate2DMake(22.739389000000000000, 75.884983499999980000); //Indore LIG

    CLLocationCoordinate2D bernalHeights = CLLocationCoordinate2DMake(37.744385, -122.417046);

    
    NSDictionary *dictHomeDepot   =   [[NSDictionary alloc] initWithObjectsAndKeys:@"The Home Depot", kCardBrandName,@"pin_home_depot", kCardImageUrl, [NSString stringWithFormat:@"%@",[NSNumber numberWithDouble:sanFrancisco.latitude]], kCardStoreLocationLat, [NSString stringWithFormat:@"%@",[NSNumber numberWithDouble:sanFrancisco.longitude]], kCardStoreLocationLong,  nil];
    
    NSDictionary *dictPetMart   =  [[NSDictionary alloc] initWithObjectsAndKeys:@"Pet Smart", kCardBrandName, @"pin_petsmart", kCardImageUrl, [NSString stringWithFormat:@"%f",bernalHeights.latitude], kCardStoreLocationLat, [NSString stringWithFormat:@"%f",bernalHeights.longitude], kCardStoreLocationLong, nil];
    
    /////////////
    
    self.arrMycards         = [[NSMutableArray alloc] initWithObjects:dictHomeDepot, dictPetMart,nil];

    for (NSDictionary *card in self.arrMycards)
    {
        CLLocationCoordinate2D cord;
        cord.latitude       = [[card valueForKey:kCardStoreLocationLat] doubleValue];
        cord.longitude      = [[card valueForKey:kCardStoreLocationLong] doubleValue];
        
        
        MKMapPoint annotationPoint = MKMapPointForCoordinate(cord);
        MKMapPoint currentLocPoint = MKMapPointForCoordinate(locationManager.location.coordinate);
        
        //*>    For Testing
        //MKMapPoint currentLocPoint = MKMapPointForCoordinate(sanFrancisco);

        CLLocationDistance  annotationDist = MKMetersBetweenMapPoints (annotationPoint, currentLocPoint);
       
        //*>    Check if card store is within two mile range of users current location then add Annotation of that store on map view
        if (annotationDist <= 2*1609.34)
        {
            //*>    Initialze |CardAnnotation|
            CWCardAnnotation *annotation        = [[CWCardAnnotation alloc] init];
            annotation.strTitle                 = [card valueForKey:kCardBrandName];
            annotation.strAnnotationImageUrl    = [card valueForKey:kCardImageUrl];
            annotation.coordinate               = cord;
            
            CWLog(@"Card: lat %f, long:%f", annotation.coordinate.latitude, annotation.coordinate.longitude);
            [self.arrMapAnnotations addObject:annotation];
        }

    }
    
    //*>    Remove any annotations that exist
    [self.mapView removeAnnotations:self.mapView.annotations];

    //*>    Check if annotations exist
    if (self.arrMapAnnotations.count > 0)
    {
        //*>    Add all annotations
        [self.mapView addAnnotations:self.arrMapAnnotations];
       
        //*>    Zoom map so that display annotion of all cards on map
        //[self.mapView showAnnotations:self.arrMapAnnotations animated:YES];
    }
    
    //*>  Zoom map 2 mile radius of where the user is at
    double miles = 2.0;
    double scalingFactor = ABS((cos(2 * M_PI * locationManager.location.coordinate.latitude / 360.0) ));
    
    MKCoordinateSpan span;
    
    span.latitudeDelta = miles/69.0;
    span.longitudeDelta = miles/(scalingFactor * 69.0);
    
    MKCoordinateRegion region;
    region.span = span;
    region.center = locationManager.location.coordinate;
    
    [self.mapView setRegion:region animated:YES];

}

/**
 **     Detect left swipe event and swipe home view to left
 **/
- (void)handleSwipeToLeft
{
    self.btnSideMenu.tag = 0;
    [UIView animateWithDuration:0.5 animations:^(void){
        [self.viewMain setFrame:CGRectMake(0, 0, self.viewMain.frame.size.width, self.viewMain.frame.size.height)];
    }];
}

/**
 **     Detect Right swipe event and swipe home view to right
 **/
- (void)handleSwipeToRight
{
    self.btnSideMenu.tag = 1;
    [UIView animateWithDuration:0.5 animations:^(void){
        [self.viewMain setFrame:CGRectMake(270, 0, self.viewMain.frame.size.width, self.viewMain.frame.size.height)];
    }];
}


- (void)selectedSection:(id)sender
{
    UIButton *btnSelectedHeader         = (UIButton *) sender;
    self.btnSideMenu.tag                = 0;
    
    [UIView animateWithDuration:0.5 animations:^(void){
        
        [self.viewMain setFrame:CGRectMake(0, 0, self.viewMain.frame.size.width, self.viewMain.frame.size.height)];
    }];
    
    //*>    Tap on Profile
    if (btnSelectedHeader.tag == 1)
    {
        CWEditProfileVC *profile = (CWEditProfileVC *) [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CWEditProfileVC class])];
        [self.navigationController pushFadeViewController:profile];
    }
    else //*>    Tap on My Cards
        if (btnSelectedHeader.tag == 2)
        {
            CWMyPurchaseCardsVC *myPurchaseCardsVC = (CWMyPurchaseCardsVC *)[self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CWMyPurchaseCardsVC class])];
            [self.navigationController pushFadeViewController:myPurchaseCardsVC];
        }
        else //*>    Tap on My Listing
            if (btnSelectedHeader.tag == 3)
            {
                CWMyListingVC *myListings = (CWMyListingVC *) [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CWMyListingVC class])];
                [self.navigationController pushFadeViewController:myListings];
            }
            else //*>    Tap on Nexus Coin
                if (btnSelectedHeader.tag == 4)
                {
                    CWPurchaseNexusCoinsVC *nexusCoinsVC = (CWPurchaseNexusCoinsVC *) [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CWPurchaseNexusCoinsVC class])];
                    [self.navigationController pushFadeViewController:nexusCoinsVC];
                }
                else //*>    Tap on Withdraw Funds
                    if (btnSelectedHeader.tag == 5)
                    {
                        CWWithDrawFundsVC *withdrawFunds = (CWWithDrawFundsVC *) [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CWWithDrawFundsVC class])];
                        [self.navigationController pushFadeViewController:withdrawFunds];
                    }
                    else//*>    Tap on Settings
                        if (btnSelectedHeader.tag == 6)
                        {
                            CWSettingsVC *settings = (CWSettingsVC *) [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CWSettingsVC class])];
                            [self.navigationController pushFadeViewController:settings];
                        }
                        else //*>    Tap on Logout
                            if (btnSelectedHeader.tag == 7)
                            {
                                //*>    Clear user's stored data
                                [Engin shared].menueList     = false;
                                [Engin shared].cwUserDetail  = nil;
                                [Engin shared].bUserLoggedIn = NO;

                                //*>    Get all view controllers object and remove them
                                NSMutableArray *allViewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
                                [allViewControllers removeAllObjects];
                                
                                //*>    Push to login view cotroller
                                CWLoginVC *loginVC = (CWLoginVC *)[self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CWLoginVC class])];
                                [self.navigationController pushFadeViewController:loginVC];
                            }
}

#pragma mark - Action Methods
/**
 **     Show/Hide menu view with animation on tap of menu button
 **/
- (IBAction)btnMenu_Action:(UIButton *)sender
{
    if (sender.tag == 0)
    {
        //*>    Show Menu View
        self.btnSideMenu.tag = 1;
        [UIView animateWithDuration:0.5 animations:^(void){
            [self.viewMain setFrame:CGRectMake(270, 0, self.viewMain.frame.size.width, self.viewMain.frame.size.height)];
        }];
    }
    else
    {
        //*>    Hide Menu View
        self.btnSideMenu.tag = 0;
        [UIView animateWithDuration:0.5 animations:^(void){
            [self.viewMain setFrame:CGRectMake(0, 0, self.viewMain.frame.size.width, self.viewMain.frame.size.height)];
        }];
    }
}

/**
 **     Unwind to Home Screen.
 **/
- (IBAction)unwindToHome_Action:(UIStoryboardSegue*)sender
{
    
}

#pragma mark - TableViewDelegate Methods

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    //*>    Initialize header view object
    UIView *viewHeader              = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 47)];
    
    UIButton *btnHeaderView         = [[UIButton alloc] initWithFrame:viewHeader.frame];
    btnHeaderView.tag               = section;
    [btnHeaderView addTarget:self action:@selector(selectedSection:) forControlEvents:UIControlEventTouchUpInside];
    [btnHeaderView setBackgroundImage:[UIImage imageNamed:@"slide_menu_section.png"] forState:UIControlStateNormal];
    [btnHeaderView setBackgroundImage:[UIImage imageNamed:@"slide_menu_selected_section.png"] forState:UIControlStateHighlighted];
    
    //*>    Set Header title
    [btnHeaderView setTitle:[self.arrMenuViewTitles objectAtIndex:section] forState:UIControlStateNormal];
    btnHeaderView.titleLabel.font   = [UIFont fontWithName:@"Helvetica Neue" size:13];
    btnHeaderView.titleLabel.frame  = CGRectMake(75, 0, 150, 47);
    [btnHeaderView setTitleColor:Font_Golden_Color forState:UIControlStateNormal];
    [btnHeaderView setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    
    btnHeaderView.titleEdgeInsets               = UIEdgeInsetsMake(0, 45, 0, 0);
    btnHeaderView.contentHorizontalAlignment    = UIControlContentHorizontalAlignmentLeft;
    
    //*>    Set Menu icon
    [btnHeaderView setImage:[UIImage imageNamed:[self.arrMenuViewImages objectAtIndex:section]] forState:UIControlStateNormal];
    [btnHeaderView setImage:[UIImage imageNamed:[self.arrMenuViewSelectedImages objectAtIndex:section]] forState:UIControlStateHighlighted];
    btnHeaderView.imageEdgeInsets               = UIEdgeInsetsMake(0, 30, 0, 0);

    [viewHeader addSubview:btnHeaderView];
    
    return viewHeader;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    
    UIView *separatorView = [[UIView alloc]initWithFrame:CGRectMake(0, 10, tableView.frame.size.width, 2)];
    
    [separatorView setBackgroundColor:[UIColor blackColor]];
    return separatorView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return self.arrMenuViewTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 0;
}


#pragma mark - MKMapViewDelegate

/**
 **    User tapped the disclosure button of  Card
 **/

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    CWLog(@"Clicked on annotation");

    // here we illustrate how to detect which annotation type was clicked on for its callout
    id <MKAnnotation> annotation = [view annotation];
    if ([annotation isKindOfClass:[CWCardAnnotation class]])
    {
        CWBuyGiftCardsSecondProcessVC *product  = (CWBuyGiftCardsSecondProcessVC *)[self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CWBuyGiftCardsSecondProcessVC class])];
        //*>    TODO: Remove Test data,  make api call for getting list of all cards of selected brand.
        product.strBrandTitle                   = @"Best Buy Gift Cards";
        product.iBrandId                        = 11;
        product.strBrandImagePath               = @"http://testdev.cardwiser.com/api/../images/brands/med/11_bestbuy.png";
        product.strCardDetail                   = @"Buy Best Buy gift cards online at a discount from Raise to get a great deal on electronics at your nearest Best Buy location or online at Bestbuy.com. Best Buy gift cards do not expire, and you can save big on your favorite gadgets when you purchase a Best Buy gift card for less than face value. When you buy discount Best Buy gift cards from Raise, you get free shipping and a 100% member satisfaction guarantee. Use Raise to buy Best Buy gift cards online at a discount so you can spend less and save more on electronics, computers and cameras.";
        
        [self.navigationController pushFadeViewController:product];
    }
}

/**
 **     Create and return cards Annotation view
 **/
- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    CWLog(@"Display Annotation");
    MKAnnotationView *returnedAnnotationView = nil;
    
    if ([annotation isKindOfClass:[CWCardAnnotation class]])
        {
            returnedAnnotationView      = [CWCardAnnotation createViewAnnotationForMapView:self.mapView annotation:annotation];
            
            //*> provide the annotation view's image
            returnedAnnotationView.image = [UIImage imageNamed:((CWCardAnnotation*)annotation).strAnnotationImageUrl];

            //*>    Create and add Callout button on |rightCalloutAccessoryView|
            UIButton *rightButton       = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 9, 17)];

            [rightButton setBackgroundImage:[UIImage imageNamed:@"back_icon_3.png"] forState:UIControlStateNormal];
            [rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
            
            ((MKPinAnnotationView *)returnedAnnotationView).rightCalloutAccessoryView = rightButton;
        }
    return returnedAnnotationView;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    CWLog(@"CLLocationManager error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CWLog(@"location did updated");

    CLLocation *newLocation     = [locations lastObject];
    NSUInteger locationCount    = locations.count;
    CLLocation *oldLocation     = (locationCount > 1 ? locations[locationCount - 2] : nil);
    
    if (!oldLocation || ((oldLocation.coordinate.latitude != newLocation.coordinate.latitude) && (oldLocation.coordinate.longitude != newLocation.coordinate.longitude)))
    {
        //*>   TODO: Perform API call for getting stores data
        
        //*>    Configure map view
        [self displayCardsAnnotationOnMap];
    }
}

#pragma mark - Memory Cleanup
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
