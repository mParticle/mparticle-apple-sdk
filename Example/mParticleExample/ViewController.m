#import "ViewController.h"
#import "mParticle.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate> {
    NSArray *selectorNames;
}

@property (nonatomic, strong) NSArray *cellTitles;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _tableView = [[UITableView alloc] initWithFrame:self.view.frame];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
}

#pragma mark Private accessors
- (NSArray *)cellTitles {
    if (_cellTitles) {
        return _cellTitles;
    }
    
    _cellTitles = @[@"Log Simple Event", @"Log Event", @"Log Screen", @"Log Commerce Event", @"Log Timed Event",
                    @"Log Error", @"Log Exception", @"Set User Attribute", @"Increment User Attribute",
                    @"Set Session Attribute", @"Increment Session Attribute", @"Register Remote", @"Log Base Event"];
    
    selectorNames = @[@"logSimpleEvent", @"logEvent", @"logScreen", @"logCommerceEvent", @"logTimedEvent",
                      @"logError", @"logException", @"setUserAttribute", @"incrementUserAttribute",
                      @"setSessionAttribute", @"incrementSessionAttribute", @"registerRemote", @"logBaseEvent"];
    
    return _cellTitles;
}

#pragma mark UITableViewDataSource and UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cellTitles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"mParticleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.minimumScaleFactor = 0.5;
    cell.textLabel.text = self.cellTitles[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString(selectorNames[indexPath.row]);
    [self performSelector:selector];
#pragma clang diagnostic pop
}

#pragma mark Examples
- (void)logSimpleEvent {
    
    [[MParticle sharedInstance] logEvent:@"Simple Event Name"
                               eventType:MPEventTypeOther
                               eventInfo:@{@"SimpleKey":@"SimpleValue"}];
}

- (void)logEvent {
    // Creates an event object
    MPEvent *event = [[MPEvent alloc] initWithName:@"Event Name" type:MPEventTypeTransaction];
    
    // Add attributes to an event
    event.customAttributes = @{@"A_String_Key":@"A String Value",
                   @"A Number Key":@(42),
                   @"A Date Key":[NSDate date]};
    
    // Custom flags are attributes sent to mParticle, but not forwarded to other providers
    [event addCustomFlag:@"Top Secret" withKey:@"Not_forwarded_to_providers"];
    
    // Logs an event
    [[MParticle sharedInstance] logEvent:event];
}

- (void)logScreen {
    [[MParticle sharedInstance] logScreen:@"Home Screen" eventInfo:nil];
}

- (void)logCommerceEvent {
    // Creates a product object
    MPProduct *product = [[MPProduct alloc] initWithName:@"Awesome Book" sku:@"1234567890" quantity:@1 price:@9.99];
    product.brand = @"A Publisher";
    product.category = @"Fiction";
    product.couponCode = @"XYZ123";
    product.position = 1;
    product[@"custom key"] = @"custom value"; // A product may contain custom key/value pairs
    
    // Creates a commerce event object
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    commerceEvent.checkoutOptions = @"Credit Card";
    commerceEvent.screenName = @"Timeless Books";
    commerceEvent.checkoutStep = 4;
    commerceEvent.customAttributes = @{@"an_extra_key": @"an_extra_value"}; // A commerce event may contain custom key/value pairs
    
    // Creates a transaction attribute object
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Book seller";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @0.87;
    transactionAttributes.revenue = @12.09;
    transactionAttributes.transactionId = @"zyx098";
    commerceEvent.transactionAttributes = transactionAttributes;
    
    // Logs a commerce event
    [[MParticle sharedInstance] logCommerceEvent:commerceEvent];
}

- (void)logTimedEvent {
    MParticle *mParticle = [MParticle sharedInstance];
    
    // Begins a timed event
    NSString *eventName = @"Timed Event";
    MPEvent *timedEvent = [[MPEvent alloc] initWithName:eventName type:MPEventTypeTransaction];
    [mParticle beginTimedEvent:timedEvent];
    
    // Dispatches a block after a random time between 1 and 5 seconds
    double delay = arc4random_uniform(4000.0) / 1000.0 + 1.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Retrieves a timed event by event name
        MPEvent *retrievedTimedEvent = [mParticle eventWithName:eventName];
        
        if (retrievedTimedEvent) {
            // Logs a timed event
            [mParticle endTimedEvent:retrievedTimedEvent];
        }
    });
}

- (void)logError {
    NSDictionary *eventInfo = @{@"cause":@"slippery floor"};
    
    [[MParticle sharedInstance] logError:@"Oops" eventInfo:eventInfo];
}

- (void)logException {
    @try {
        // Invokes a non-existing method
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL crashSelector = NSSelectorFromString(@"someMethodThatDoesNotExist");
        [self performSelector:crashSelector withObject:nil];
#pragma clang diagnostic pop
    } @catch (NSException *exception) {
        // Logs an exception and informs the view controller where it happened
        [[MParticle sharedInstance] logException:exception topmostContext:self];
    }
}

- (void)setUserAttribute {
    MParticle *mParticle = [MParticle sharedInstance];
    
    // Sets 'Age' as a user attribute utilizing one of the pre-defined mParticle constants
    NSString *age = [@(21 + arc4random_uniform(80)) stringValue];
    [mParticle.identity.currentUser setUserAttribute:mParticleUserAttributeAge value:age];
    
    // Sets 'Gender' as a user attribute utilizing one of the pre-defined mParticle constants
    NSString *gender = arc4random_uniform(2) ? @"m" : @"f";
    [mParticle.identity.currentUser setUserAttribute:mParticleUserAttributeGender value:gender];
    
    // Sets a numeric user attribute using a custom key
    [mParticle.identity.currentUser setUserAttribute:@"Achieved Level" value:@4];
}

- (void)incrementUserAttribute {
    // Increments the value of a numeric user attribute
    [[MParticle sharedInstance].identity.currentUser incrementUserAttribute:@"Achieved Level" byValue:@1];
}

- (void)setSessionAttribute {
    MParticle *mParticle = [MParticle sharedInstance];
    
    // Sets session attributes
    [mParticle setSessionAttribute:@"Station" value:@"Classic Rock"];
    [mParticle setSessionAttribute:@"Song Count" value:@1];
}

- (void)incrementSessionAttribute {
    // Increments a numeric session attribute
    [[MParticle sharedInstance] incrementSessionAttribute:@"Song Count" byValue:@1];
}

- (void)registerRemote {
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

@end
