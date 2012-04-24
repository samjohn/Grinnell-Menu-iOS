//
//  VenueView.m
//  Grinnell-Menu-iOS
//
//  Created by Colin Tremblay on 10/22/11.
//  Copyright 2011 __GrinnellAppDev__. All rights reserved.
//

//FOR TESTING
#define kDiningMenu [NSURL URLWithString:@"http://tcdb.grinnell.edu/apps/glicious/menu.php?mon=12&day=14&year=2011"]

#import "VenueViewController.h"
#import "Grinnell_Menu_iOSAppDelegate.h"
#import "Dish.h"
#import "Venue.h"
#import "SettingsViewController.h"
#import "DishViewController.h"

#import "FlurryAnalytics.h"

@implementation VenueViewController{
    NSArray *menuVenueNamesFromJSON;
    NSMutableArray *originalVenues;
    NSString *alert;
}
@synthesize grinnellDiningLabel;
@synthesize dateLabel;
@synthesize menuchoiceLabel;

@synthesize anotherTableView, date, mealChoice, mainURL, jsonDict;

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

//We add this method here because when the VenueviewController is waking up. Turning on screen. We would also like to take advantage of that and do some initialization of our own. i.e loading the items
- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {         
    }
    return self;
}

-(void)getDishes {
    Grinnell_Menu_iOSAppDelegate *mainDelegate = (Grinnell_Menu_iOSAppDelegate *)[[UIApplication sharedApplication] delegate];
    [originalVenues removeAllObjects];
    [mainDelegate.venues removeAllObjects];
    
    NSString *key = [[NSString alloc] init];
    if ([self.mealChoice isEqualToString:@"Breakfast"]) {
        key = @"BREAKFAST";
    } else if ([self.mealChoice isEqualToString:@"Lunch"]) {
        key = @"LUNCH";
    } else if ([self.mealChoice isEqualToString:@"Dinner"]) {
        key = @"DINNER";
    } else if ([self.mealChoice isEqualToString:@"Outtakes"]) {
        key = @"OUTTAKES";
    }
        
    NSDictionary *mainMenu = [self.jsonDict objectForKey:key]; 
    
    //Put data on screen
    //This is a dictionary of dictionaries. Each venue is a key in the main dictionary. Thus we will have to sort through each venue(dict) the main jsondict(dict) and create dish objects for each object that is in the venue. 
    
    menuVenueNamesFromJSON = [[NSArray alloc] init];
    menuVenueNamesFromJSON = [mainMenu allKeys];
    
    //Here we fill the venues array to contain all the venues. 
    for (NSString *venuename in menuVenueNamesFromJSON) {
        NSLog(@"venuenames: %@", venuename);
        Venue *gvenue = [[Venue alloc] init];
        gvenue.name = venuename;
        if ([gvenue.name isEqualToString:@"ENTREES                  "] && [key isEqualToString:@"LUNCH"]) {
            NSLog(@"Found it here");
                continue;
        }
       // NSLog(@"Adding object: %@", gvenue);
        [mainDelegate.venues addObject:gvenue];
    }
    
    //Remove the Entree venue
    [mainDelegate.venues removeObject:@"ENTREES"];
    
    //So for each Venue...
    for (Venue *gVenue in mainDelegate.venues) {
        
        //We create a dish
        gVenue.dishes = [[NSMutableArray alloc] initWithCapacity:10];
        NSArray *dishesInVenue = [mainMenu objectForKey:gVenue.name];
        
        for (int i = 0; i < dishesInVenue.count; i++) {
            Dish *dish = [[Dish alloc] init];
            //loop through for the number of dishes
            NSDictionary *actualdish = [dishesInVenue objectAtIndex:i];
            
            dish.name = [actualdish objectForKey:@"name"];
            
            if (![[actualdish objectForKey:@"vegan"] isEqualToString:@"false"]) 
                dish.vegan = YES;
            if (![[actualdish objectForKey:@"ovolacto"] isEqualToString:@"false"]) 
                dish.ovolacto = YES;
            //then finally we add this new dish to it's venue
            [gVenue.dishes addObject:dish];
        }
    }
    [originalVenues setArray:mainDelegate.venues];    
    [self applyFilters];
}

- (IBAction)showInfo:(id)sender{ 
    
    // Records when user goes to info, pushes to Flurry
    [FlurryAnalytics logEvent:@"Flipped to Settings"];
     
    SettingsViewController *settings = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settings];
    navController.navigationBar.barStyle = UIBarStyleBlack;
    navController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:navController animated:YES];
}

- (IBAction)changeMeal:(id)sender{
    
    UIAlertView *mealmessage = [[UIAlertView alloc] 
                                initWithTitle:@"Select Meal" 
                                message:nil
                                delegate:self 
                                cancelButtonTitle:@"Cancel" 
                                otherButtonTitles:nil
                                ];
    
    //Completely remove text from JSON output when menu is not present. in other words.. Removes the button from the alert view if no meal is present for that day.    
    if ([jsonDict objectForKey:@"BREAKFAST"]) {
        [mealmessage addButtonWithTitle:@"Breakfast"];
    }
    
    if ([jsonDict objectForKey:@"LUNCH"]) {
        [mealmessage addButtonWithTitle:@"Lunch"];
    }
    if ( [jsonDict objectForKey:@"DINNER"]) {
        [mealmessage addButtonWithTitle:@"Dinner"];
    }
    if ([jsonDict objectForKey:@"OUTTAKES"]) {
        [mealmessage addButtonWithTitle:@"Outtakes"];
    }
    
    [mealmessage show];
}

- (void)viewDidLoad{
    Grinnell_Menu_iOSAppDelegate *mainDelegate = (Grinnell_Menu_iOSAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIBarButtonItem *changeMeal = [[UIBarButtonItem alloc] initWithTitle:@"Change Meal" style:UIBarButtonItemStyleBordered target:self action:@selector(changeMeal:)];
    [self.navigationItem setRightBarButtonItem:changeMeal];
    
    [super viewDidLoad];
    
    originalVenues = [[NSMutableArray alloc] init];
    mainDelegate.venues = [[NSMutableArray alloc] init];
    [self getDishes];
    self.title = @"Venues";
    menuchoiceLabel.text = self.mealChoice;
    
    NSLog(@"Date: %@", date);
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
   // [dateFormatter  setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter  setDateFormat:@"MMM dd"];
    NSString *formattedDate = [dateFormatter stringFromDate:date];
    NSLog(@"Date: %@", formattedDate);
    
    dateLabel.text = formattedDate;
    grinnellDiningLabel.font = [UIFont fontWithName:@"Vivaldi" size:35];
    grinnellDiningLabel.textColor = [UIColor colorWithRed:.8 green:.8 blue:1 alpha:1];
    dateLabel.textColor = [UIColor colorWithRed:.8 green:.8 blue:1 alpha:1];
    menuchoiceLabel.textColor = [UIColor colorWithRed:.8 green:.8 blue:1 alpha:1];
    
    dateLabel.font = [UIFont fontWithName:@"Vivaldi" size:20];
    menuchoiceLabel.font = [UIFont fontWithName:@"Vivaldi" size:20];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:YES];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:YES];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
}

- (void)viewDidUnload {
    [self setGrinnellDiningLabel:nil];
    [self setDateLabel:nil];
    [self setMenuchoiceLabel:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated{
    [self applyFilters];
    [anotherTableView reloadData];
    [super viewWillAppear:YES];
}


- (void)applyFilters{
    Grinnell_Menu_iOSAppDelegate *mainDelegate = (Grinnell_Menu_iOSAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSPredicate *veganPred, *ovoPred;
    BOOL ovoSwitch, veganSwitch;
    veganSwitch = [[NSUserDefaults standardUserDefaults] boolForKey:@"VeganSwitchValue"];
    ovoSwitch = [[NSUserDefaults standardUserDefaults] boolForKey:@"OvoSwitchValue"];
    [mainDelegate.venues removeAllObjects];
    for (Venue *v in originalVenues) {
        Venue *venue = [[Venue alloc] init];
        venue.name = v.name;
        for (Dish *d in v.dishes) {
            Dish *dish = [[Dish alloc] init];
            dish.name = d.name;
            dish.venue = d.venue;
            dish.nutAllergen = d.nutAllergen;
            dish.glutenFree = d.glutenFree;
            dish.vegetarian = d.vegetarian;
            dish.vegan = d.vegan;
            dish.ovolacto = d.ovolacto;
            dish.hasNutrition = d.hasNutrition;
            [venue.dishes addObject:dish];
        }
        [mainDelegate.venues addObject:venue];
    }
    
    if (!ovoSwitch && !veganSwitch){
    }
    
    else if (ovoSwitch){
        ovoPred = [NSPredicate predicateWithFormat:@"ovolacto == YES"];
        veganPred = [NSPredicate predicateWithFormat:@"vegan == YES"];
        
        NSMutableArray *preds = [[NSMutableArray alloc] init];
        [preds removeAllObjects];
        [preds addObject:ovoPred];
        [preds addObject:veganPred];
        NSPredicate *compoundPred = [NSCompoundPredicate orPredicateWithSubpredicates:preds];
        
        for (Venue *v in mainDelegate.venues){
            [v.dishes filterUsingPredicate:compoundPred];
        }
    }
    
    else if (veganSwitch){
        veganPred = [NSPredicate predicateWithFormat:@"vegan == YES"];
        for (Venue *v in mainDelegate.venues) {
            [v.dishes filterUsingPredicate:veganPred];
        }
    }
    //Remove empty venues if all items are filtered out of a venue
    NSMutableArray *emptyVenues = [[NSMutableArray alloc] init];
    for (Venue *v in mainDelegate.venues) {
        if (v.dishes.count == 0){
            [emptyVenues addObject:v];
        }
    }
    [mainDelegate.venues removeObjectsInArray:emptyVenues];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    // Return the number of sections.
    Grinnell_Menu_iOSAppDelegate *mainDelegate = (Grinnell_Menu_iOSAppDelegate *)[[UIApplication sharedApplication] delegate];
    return mainDelegate.venues.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    Grinnell_Menu_iOSAppDelegate *mainDelegate = (Grinnell_Menu_iOSAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    Venue *venue = [mainDelegate.venues objectAtIndex:section];
    return venue.name; 
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if ([self tableView:tableView titleForHeaderInSection:section] != nil) {
        return 40;
    }
    else {
        // If no section header title, no section header needed
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{

    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
   // NSString *formattedSectionTitle = [sectionTitle capitalizedString];
    if (sectionTitle == nil) {
        return nil;
    }
    // Create label with section title
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, 6, 300, 30);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
   // label.font = [UIFont fontWithName:@"Vivaldi" size:32];
    label.font = [UIFont boldSystemFontOfSize:20];
    //[UIFont fontWithName:@"Vivaldi" size:38]
    
    label.text = sectionTitle;
    
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    [view addSubview:label];
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section{
    Grinnell_Menu_iOSAppDelegate *mainDelegate = (Grinnell_Menu_iOSAppDelegate *)[[UIApplication sharedApplication] delegate];
    Venue *venue = [mainDelegate.venues objectAtIndex:section];
    return venue.dishes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    // Configure the cell...    
    Grinnell_Menu_iOSAppDelegate *mainDelegate = (Grinnell_Menu_iOSAppDelegate *)[[UIApplication sharedApplication] delegate];
    Venue *venue = [mainDelegate.venues objectAtIndex:indexPath.section];
    Dish *dish = [venue.dishes objectAtIndex:indexPath.row];
    
    cell.textLabel.text = dish.name;
    
    // accessory type
    if (!dish.hasNutrition){
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else{
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    if (indexPath.section % 2)
    {
       [cell setBackgroundColor:[UIColor colorWithRed:.8 green:.8 blue:1 alpha:1]];

    }
    else 
        //[cell setBackgroundColor:[UIColor colorWithRed:0.8 green:0.5 blue:.5 alpha:1]];
 [cell setBackgroundColor:[UIColor underPageBackgroundColor]];
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    DishViewController *dishView = [[DishViewController alloc] initWithNibName:@"DishView" bundle:nil];
    dishView.dishRow = indexPath.row;
    dishView.dishSection = indexPath.section;
    
	[self.navigationController pushViewController:dishView animated:YES];
}




#pragma mark UIAlertViewDelegate Methods
// Called when an alert button is tapped.
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    else {
        NSString *titlePressed = [alertView buttonTitleAtIndex:buttonIndex];
        self.mealChoice = titlePressed;

        [self getDishes];
        NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [anotherTableView reloadData];
        menuchoiceLabel.text = self.mealChoice;
        [anotherTableView scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];

    }
}

@end