#import "MPIViewController.h"
#import "StreamsStorage.h"
#import "Stream.h"

@import mParticle_Apple_SDK;

static NSString *const PlaybackControllerItemStatusObservationContext = @"PlaybackViewControllerItemStatusObservationContext";
static NSString *const PlaybackControllerRateObservationContext = @"PlaybackViewControllerRateObservationContext";

@interface MPIViewController() {
    UIColor *selectedColor;
    UIColor *cellColor;
    UIColor *focusColor;
    NSIndexPath *focusedIndexPath;
    NSIndexPath *selectedIndexPath;
    Stream *currentStream;
    NSUInteger selectedIndex;
}

@property (nonatomic, strong, readonly) NSArray<Stream *> *streams;

@end


@implementation MPIViewController

@synthesize streams = _streams;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    selectedColor = [UIColor colorWithRed:9.0/255.0 green:8.0/255.0 blue:23.0/255.0 alpha:1];
    cellColor = [UIColor colorWithRed:19.0/255.0 green:28.0/255.0 blue:43.0/255.0 alpha:1];
    focusColor = [UIColor colorWithRed:59.0/255.0 green:68.0/255.0 blue:83.0/255.0 alpha:1];
    
    focusedIndexPath = nil;
    selectedIndexPath = nil;
    currentStream = nil;
    
    selectedIndex = 0;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleSessionDidBegin:)
                               name:mParticleSessionDidBeginNotification
                             object:nil];
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:mParticleSessionDidBeginNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if TARGET_OS_IOS == 1
    UIImage *mParticleLogo = [UIImage imageNamed:@"mParticle_navigation"];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:mParticleLogo];
    [self.navigationItem.titleView sizeThatFits:CGSizeMake(100, 44)];
#endif
    
    MParticle *mParticle = [MParticle sharedInstance];
    
    [mParticle logScreen:@"Video Streams"
               eventInfo:@{@"Launch":@YES}];
    
    MPIdentityApiRequest *identityRequest = [MPIdentityApiRequest requestWithEmptyUser];
    identityRequest.email = @"user@thisappisawesomewhyhaventithoughtaboutbuildingit.com";
    [[mParticle identity] modify:identityRequest completion:nil];
    
    MPEvent *timedEvent = [[MPEvent alloc] initWithName:@"First Selection Time" type:MPEventTypeNavigation];
    
    [mParticle beginTimedEvent:timedEvent];
}

#pragma mark UITableView DataSource and Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.streams.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"VideoStreams";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    Stream *stream = self.streams[indexPath.row];
    cell.textLabel.text = stream.title;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedIndexPath = [indexPath copy];
    selectedIndex = indexPath.row;
    Stream *stream = self.streams[selectedIndex];
    
#if TARGET_OS_IOS == 1
    if (_playerViewController != nil) {
        self.playerViewController.title = stream.title;
    }
    
    NSTimeInterval duration = [self.transitionCoordinator transitionDuration];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    });
#endif
    
    // If you select one of the indexPaths that will not playback a stream
    // and instead are pure examples of the mParticle SDK operations
    if (selectedIndex > 7) {
        if (_playerViewController != nil && self.playerViewController.player.rate != 0) {
            [self.playerViewController.player pause];
        }
        
        switch (selectedIndex) {
            case 8: // Logs an event with a simulated purchase of a video
                [self logCommerceEvent];
                break;
                
            case 9: // Logs an error
                [self logError];
                break;
                
            case 10: // Logs an exception
                [self logException];
                break;
                
            case 11: // Toggle Opt Out
                [[MParticle sharedInstance] setOptOut:![[MParticle sharedInstance] optOut]];
                _streams = [[[StreamsStorage alloc] init] fetchStreams];
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                break;
                
            default:
                break;
        }
        
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    [self playStream:stream];
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray<NSIndexPath *> *visibleIndexPaths = [tableView indexPathsForVisibleRows];
    UITableViewCell *cell;
    
    for (NSIndexPath *visibleIndexPath in visibleIndexPaths) {
        cell = [tableView cellForRowAtIndexPath:visibleIndexPath];
        UIColor *backgroundColor;

#if TARGET_OS_IOS == 1
        if ([visibleIndexPath isEqual:indexPath]) {
            backgroundColor = selectedColor;
        } else {
            backgroundColor = cellColor;
        }
#elif TARGET_OS_TV == 1
        if ([visibleIndexPath isEqual:indexPath] || [visibleIndexPath isEqual:selectedIndexPath]) {
            backgroundColor = selectedColor;
        } else {
            backgroundColor = cellColor;
        }
#else
        backgroundColor = cellColor;
#endif
        
        cell.contentView.backgroundColor = backgroundColor;
    }
}

#if TARGET_OS_TV == 1
- (void)tableView:(UITableView *)tableView didUpdateFocusInContext:(UITableViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    NSArray<NSIndexPath *> *visibleIndexPaths = [tableView indexPathsForVisibleRows];
    focusedIndexPath = [context nextFocusedIndexPath];
    
    for (int i = 0; i < 4; ++i) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UITableViewCell *cell;
            
            for (NSIndexPath *visibleIndexPath in visibleIndexPaths) {
                cell = [tableView cellForRowAtIndexPath:visibleIndexPath];
                UIColor *backgroundColor;
                
                if ([visibleIndexPath isEqual:focusedIndexPath]) {
                    backgroundColor = focusColor;
                } else if ([visibleIndexPath isEqual:selectedIndexPath]) {
                    backgroundColor = selectedColor;
                } else {
                    backgroundColor = cellColor;
                }
                
                cell.contentView.backgroundColor = backgroundColor;
            }
        });
    }
}
#endif

#pragma mark Private accessors
- (NSArray<Stream *> *)streams {
    if (_streams) {
        return _streams;
    }
    
    StreamsStorage *streamsStorage = [[StreamsStorage alloc] init];
    _streams = [streamsStorage fetchStreams];
    
    return _streams;
}

#pragma mark Private methods
- (void)handleSessionDidBegin:(NSNotification *)notification {
    [[MParticle sharedInstance] setSessionAttribute:@"Playcount" value:@0];
}

- (void)logCommerceEvent {
    // Creates a product object
    MPProduct *product = [[MPProduct alloc] initWithName:@"Awesome Movie" sku:@"1234567890" quantity:@1 price:@9.99];
    product.brand = @"A Studio";
    product.category = @"Science Fiction";
    product.couponCode = @"XYZ123";
    product.position = 1;
    product[@"custom key"] = @"custom value"; // A product may contain arbitrary custom key/value pairs
    
    // Creates a commerce event object
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    commerceEvent.checkoutOptions = @"Credit Card";
    commerceEvent.screenName = @"Timeless Movies";
    commerceEvent.checkoutStep = 4;
    commerceEvent[@"an_extra_key"] = @"an_extra_value"; // A commerce event may contain arbitrary custom key/value pairs
    
    // Creates a transaction attribute object
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Movie seller";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @0.87;
    transactionAttributes.revenue = @12.09;
    transactionAttributes.transactionId = @"zyx098";
    commerceEvent.transactionAttributes = transactionAttributes;
    
    // Logs a commerce event
    [[MParticle sharedInstance] logCommerceEvent:commerceEvent];
}

- (void)logError {
    NSDictionary *eventInfo = @{@"Cause":@"Invalid stream URL"};
    
    [[MParticle sharedInstance] logError:@"Playback Error" eventInfo:eventInfo];
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

#pragma mark Gesture recognizers
- (IBAction)handleRemotePlayPause:(id)sender {
    if (!self.playerViewController) {
        return;
    }
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Pressed Remote Play/Pause" type:MPEventTypeOther];
    
    BOOL playing = self.playerViewController.player.rate != 0;
    if (playing) {
        event.info = @{@"Action":@"Pause"};
        [self.playerViewController.player pause];
    } else {
        event.info = @{@"Action":@"Play"};
        [self.playerViewController.player play];
    }
    
    [[MParticle sharedInstance] logEvent:event];
}

#pragma mark Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PlaybackSegue"]) {
#if TARGET_OS_IOS == 1
        if (_playerViewController) {
            [self stopObservingPlayerProperties];
        }
#endif
        
        self.playerViewController = segue.destinationViewController;
    }
}

#pragma mark Playback
- (void)playStream:(Stream *)stream {
    if (currentStream) {
        [self stopObservingPlayerProperties];
    }
    
    currentStream = stream;
    AVPlayer *avPlayer = [AVPlayer playerWithURL:currentStream.url];
    self.playerViewController.player = avPlayer;
    
    [self startObservingPlayerProperties];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Video Playback" type:MPEventTypeOther];
    event.info = @{@"Title":currentStream.title};
    
    MParticle *mParticle = [MParticle sharedInstance];
    [mParticle logEvent:event];
    [mParticle incrementSessionAttribute:@"Playcount" byValue:@1];
    
    MPEvent *timedEvent = [mParticle eventWithName:@"First Selection Time"];
    if (timedEvent) {
        timedEvent.info = @{@"Title":currentStream.title};
        [mParticle endTimedEvent:timedEvent];
    }
}

- (void)startObservingPlayerProperties {
    [self.playerViewController.player addObserver:self
                                       forKeyPath:@"rate"
                                          options:0
                                          context:(__bridge void *)PlaybackControllerRateObservationContext];
    
    [self.playerViewController.player.currentItem addObserver:self
                                                   forKeyPath:@"status"
                                                      options:0
                                                      context:(__bridge void *)PlaybackControllerItemStatusObservationContext];
}

- (void)stopObservingPlayerProperties {
    [self.playerViewController.player removeObserver:self forKeyPath:@"rate" context:(__bridge void *)PlaybackControllerRateObservationContext];
    
    [self.playerViewController.player.currentItem removeObserver:self forKeyPath:@"status" context:(__bridge void *)PlaybackControllerItemStatusObservationContext];
}

#pragma mark KVOs
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void *)PlaybackControllerRateObservationContext) {
        if (currentStream) {
            MPEvent *event = [[MPEvent alloc] initWithName:@"Video Changed Rate" type:MPEventTypeOther];
            event.info = @{@"Title":currentStream.title,
                           @"Rate":@(self.playerViewController.player.rate)};
            
            [[MParticle sharedInstance] logEvent:event];
        }
    } else if (context == (__bridge void *)PlaybackControllerItemStatusObservationContext) {
        AVPlayerItemStatus playerItemStatus = self.playerViewController.player.currentItem.status;
        
        if (playerItemStatus == AVPlayerItemStatusReadyToPlay) {
            [self.playerViewController.player play];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
