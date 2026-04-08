#import "ViewController.h"
#import <mParticle_Apple_SDK.h>
@import RoktContracts;

@interface ViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIButton *overlayButton;
@property (nonatomic, strong) UIButton *bottomsheetButton;
@property (nonatomic, strong) UIStackView *eventLogStack;
@property (nonatomic, strong) UILabel *eventLogHeader;
@property (nonatomic, strong) NSMutableArray<NSString *> *eventLog;
@property (nonatomic, assign) BOOL overlayTriggered;
@property (nonatomic, assign) BOOL bottomsheetTriggered;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.eventLog = [NSMutableArray array];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    [self setupUI];
}

- (void)setupUI {
    // Checkmark icon
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:56];
    UIImageView *checkmark = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.circle.fill" withConfiguration:config]];
    checkmark.tintColor = [self colorFromHex:@"#C20075"];
    checkmark.contentMode = UIViewContentModeCenter;

    // Title
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Order Confirmed";
    titleLabel.font = [UIFont boldSystemFontOfSize:28];
    titleLabel.textAlignment = NSTextAlignmentCenter;

    // Subtitle
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"Reference: ORDER-12345";
    subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    subtitleLabel.textColor = UIColor.secondaryLabelColor;
    subtitleLabel.textAlignment = NSTextAlignmentCenter;

    // Overlay button
    self.overlayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.overlayButton setTitle:@"Load Rokt Placement" forState:UIControlStateNormal];
    [self.overlayButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.overlayButton.backgroundColor = [self colorFromHex:@"#C20075"];
    self.overlayButton.layer.cornerRadius = 8;
    self.overlayButton.contentEdgeInsets = UIEdgeInsetsMake(12, 24, 12, 24);
    [self.overlayButton addTarget:self action:@selector(loadOverlayPlacement) forControlEvents:UIControlEventTouchUpInside];

    // Bottomsheet button
    self.bottomsheetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.bottomsheetButton setTitle:@"Load Bottomsheet Placement" forState:UIControlStateNormal];
    [self.bottomsheetButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.bottomsheetButton.backgroundColor = [self colorFromHex:@"#5A2D82"];
    self.bottomsheetButton.layer.cornerRadius = 8;
    self.bottomsheetButton.contentEdgeInsets = UIEdgeInsetsMake(12, 24, 12, 24);
    [self.bottomsheetButton addTarget:self action:@selector(loadBottomsheetPlacement) forControlEvents:UIControlEventTouchUpInside];

    // Event log header (initially hidden)
    self.eventLogHeader = [[UILabel alloc] init];
    self.eventLogHeader.text = @"Event Log";
    self.eventLogHeader.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.eventLogHeader.hidden = YES;

    // Event log stack
    self.eventLogStack = [[UIStackView alloc] init];
    self.eventLogStack.axis = UILayoutConstraintAxisVertical;
    self.eventLogStack.spacing = 4;
    self.eventLogStack.alignment = UIStackViewAlignmentLeading;

    // Event log container
    UIView *eventLogContainer = [[UIView alloc] init];
    eventLogContainer.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    eventLogContainer.layer.cornerRadius = 10;
    eventLogContainer.clipsToBounds = YES;
    eventLogContainer.hidden = YES;
    eventLogContainer.tag = 100;

    [eventLogContainer addSubview:self.eventLogHeader];
    [eventLogContainer addSubview:self.eventLogStack];

    self.eventLogHeader.translatesAutoresizingMaskIntoConstraints = NO;
    self.eventLogStack.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.eventLogHeader.topAnchor constraintEqualToAnchor:eventLogContainer.topAnchor constant:12],
        [self.eventLogHeader.leadingAnchor constraintEqualToAnchor:eventLogContainer.leadingAnchor constant:12],
        [self.eventLogHeader.trailingAnchor constraintEqualToAnchor:eventLogContainer.trailingAnchor constant:-12],
        [self.eventLogStack.topAnchor constraintEqualToAnchor:self.eventLogHeader.bottomAnchor constant:8],
        [self.eventLogStack.leadingAnchor constraintEqualToAnchor:eventLogContainer.leadingAnchor constant:12],
        [self.eventLogStack.trailingAnchor constraintEqualToAnchor:eventLogContainer.trailingAnchor constant:-12],
        [self.eventLogStack.bottomAnchor constraintEqualToAnchor:eventLogContainer.bottomAnchor constant:-12],
    ]];

    // Main stack
    self.stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        checkmark, titleLabel, subtitleLabel,
        self.overlayButton, self.bottomsheetButton,
        eventLogContainer
    ]];
    self.stackView.axis = UILayoutConstraintAxisVertical;
    self.stackView.spacing = 24;
    self.stackView.alignment = UIStackViewAlignmentCenter;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;

    // Scroll view
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.stackView];
    [self.view addSubview:self.scrollView];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.stackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor constant:40],
        [self.stackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:16],
        [self.stackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor constant:-16],
        [self.stackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:-16],
        [self.stackView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-32],
        [eventLogContainer.widthAnchor constraintEqualToAnchor:self.stackView.widthAnchor],
    ]];
}

- (NSDictionary<NSString *, NSString *> *)attributes {
    return @{
        @"email": @"jenny.smith@rokt.com",
        @"firstname": @"Jenny",
        @"lastname": @"Smith",
        @"confirmationref": @"ORDER-12345",
        @"billingzipcode": @"10014",
        @"sandbox": @"true"
    };
}

- (void)loadOverlayPlacement {
    self.overlayTriggered = YES;
    self.overlayButton.enabled = NO;
    self.overlayButton.alpha = 0.5;

    [[MParticle sharedInstance].rokt selectPlacements:@"MSDKOverlayLayout"
                                          attributes:[self attributes]
                                       embeddedViews:nil
                                              config:nil
                                             onEvent:nil];
}

- (void)loadBottomsheetPlacement {
    self.bottomsheetTriggered = YES;
    self.bottomsheetButton.enabled = NO;
    self.bottomsheetButton.alpha = 0.5;

    __weak typeof(self) weakSelf = self;

    [[MParticle sharedInstance].rokt events:@"MSDKBottomsheetLayout" onEvent:^(RoktEvent * _Nonnull event) {
        NSString *description = [weakSelf describeEvent:event];
        NSLog(@"RoktEvent: %@", description);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf appendEventLog:description];
        });
    }];

    [[MParticle sharedInstance].rokt selectPlacements:@"MSDKBottomsheetLayout"
                                          attributes:[self attributes]
                                       embeddedViews:nil
                                              config:nil
                                             onEvent:nil];
}

- (void)appendEventLog:(NSString *)entry {
    [self.eventLog addObject:entry];

    UIView *eventLogContainer = [self.view viewWithTag:100];
    eventLogContainer.hidden = NO;
    self.eventLogHeader.hidden = NO;

    // Insert at top (reversed order like Swift example)
    UILabel *label = [[UILabel alloc] init];
    label.text = entry;
    label.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    label.numberOfLines = 0;
    [self.eventLogStack insertArrangedSubview:label atIndex:0];
}

- (NSString *)describeEvent:(RoktEvent *)event {
    if ([event isKindOfClass:[RoktShowLoadingIndicator class]]) {
        return @"ShowLoadingIndicator";
    } else if ([event isKindOfClass:[RoktHideLoadingIndicator class]]) {
        return @"HideLoadingIndicator";
    } else if ([event isKindOfClass:[RoktPlacementReady class]]) {
        RoktPlacementReady *e = (RoktPlacementReady *)event;
        return [NSString stringWithFormat:@"PlacementReady - %@", e.identifier ?: @""];
    } else if ([event isKindOfClass:[RoktPlacementInteractive class]]) {
        RoktPlacementInteractive *e = (RoktPlacementInteractive *)event;
        return [NSString stringWithFormat:@"PlacementInteractive - %@", e.identifier ?: @""];
    } else if ([event isKindOfClass:[RoktOfferEngagement class]]) {
        RoktOfferEngagement *e = (RoktOfferEngagement *)event;
        return [NSString stringWithFormat:@"OfferEngagement - %@", e.identifier ?: @""];
    } else if ([event isKindOfClass:[RoktPositiveEngagement class]]) {
        RoktPositiveEngagement *e = (RoktPositiveEngagement *)event;
        return [NSString stringWithFormat:@"PositiveEngagement - %@", e.identifier ?: @""];
    } else if ([event isKindOfClass:[RoktFirstPositiveEngagement class]]) {
        RoktFirstPositiveEngagement *e = (RoktFirstPositiveEngagement *)event;
        return [NSString stringWithFormat:@"FirstPositiveEngagement - %@", e.identifier ?: @""];
    } else if ([event isKindOfClass:[RoktOpenUrl class]]) {
        RoktOpenUrl *e = (RoktOpenUrl *)event;
        return [NSString stringWithFormat:@"OpenUrl - %@", e.url];
    } else if ([event isKindOfClass:[RoktPlacementClosed class]]) {
        RoktPlacementClosed *e = (RoktPlacementClosed *)event;
        return [NSString stringWithFormat:@"PlacementClosed - %@", e.identifier ?: @""];
    } else if ([event isKindOfClass:[RoktPlacementCompleted class]]) {
        RoktPlacementCompleted *e = (RoktPlacementCompleted *)event;
        return [NSString stringWithFormat:@"PlacementCompleted - %@", e.identifier ?: @""];
    } else if ([event isKindOfClass:[RoktPlacementFailure class]]) {
        RoktPlacementFailure *e = (RoktPlacementFailure *)event;
        return [NSString stringWithFormat:@"PlacementFailure - %@", e.identifier ?: @""];
    }
    return NSStringFromClass([event class]);
}

- (UIColor *)colorFromHex:(NSString *)hex {
    NSString *cleaned = [[hex stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] uppercaseString];
    unsigned int rgbValue = 0;
    [[NSScanner scannerWithString:cleaned] scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue >> 16) & 0xFF) / 255.0
                           green:((rgbValue >> 8) & 0xFF) / 255.0
                            blue:(rgbValue & 0xFF) / 255.0
                           alpha:1.0];
}

@end
