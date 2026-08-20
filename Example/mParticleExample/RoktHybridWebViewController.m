#import "RoktHybridWebViewController.h"

#import <WebKit/WebKit.h>
#import <mParticle_Apple_SDK_ObjC/mParticle.h>

static NSString *const kRoktHybridMessageHandlerName = @"roktSession";
static NSString *const kRoktHybridHTMLResource = @"rokt-hybrid";

@interface MPEWeakScriptMessageHandler : NSObject <WKScriptMessageHandler>
@property (nonatomic, weak) id<WKScriptMessageHandler> target;
@end

@implementation MPEWeakScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.target userContentController:userContentController didReceiveScriptMessage:message];
}
@end

@interface RoktHybridWebViewController () <WKScriptMessageHandler>

@property (nonatomic, strong) MPRoktSession *session;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) MPEWeakScriptMessageHandler *messageHandler;

@end

@implementation RoktHybridWebViewController

- (instancetype)initWithSession:(MPRoktSession *)session {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _session = session;
    }
    return self;
}

- (void)dealloc {
    [_webView.configuration.userContentController removeScriptMessageHandlerForName:kRoktHybridMessageHandlerName];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Rokt WebView";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(dismissHybrid)];

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKUserScript *handoffScript = [[WKUserScript alloc] initWithSource:[self handoffJavaScript]
                                                         injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                      forMainFrameOnly:YES];
    [configuration.userContentController addUserScript:handoffScript];
    self.messageHandler = [[MPEWeakScriptMessageHandler alloc] init];
    self.messageHandler.target = self;
    [configuration.userContentController addScriptMessageHandler:self.messageHandler name:kRoktHybridMessageHandlerName];

    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.webView];

    [NSLayoutConstraint activateConstraints:@[
        [self.webView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    [[MParticle sharedInstance] initializeWKWebView:self.webView];

    NSURL *htmlURL = [[NSBundle mainBundle] URLForResource:kRoktHybridHTMLResource withExtension:@"html"];
    if (!htmlURL) {
        NSLog(@"Rokt hybrid: bundled rokt-hybrid.html is missing");
        return;
    }
    [self.webView loadFileURL:htmlURL allowingReadAccessToURL:htmlURL.URLByDeletingLastPathComponent];
}

- (void)dismissHybrid {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)handoffJavaScript {
    NSMutableDictionary *handoff = [NSMutableDictionary dictionary];
    if (self.session.sessionId.length > 0) {
        handoff[@"sessionId"] = self.session.sessionId;
    }
    if (self.session.sessionToken.length > 0) {
        handoff[@"sessionToken"] = self.session.sessionToken;
    }
    if (self.session.expiresAt != nil) {
        handoff[@"expiresAt"] = self.session.expiresAt;
    }

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:handoff options:0 error:&error];
    if (!jsonData || error) {
        NSLog(@"Rokt hybrid: failed to serialize session handoff: %@", error);
        return @"window.__ROKT_HANDOFF = {};";
    }

    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"window.__ROKT_HANDOFF = %@;", json];
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:kRoktHybridMessageHandlerName]) {
        return;
    }
    if (![message.body isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Rokt hybrid: expected dictionary from webview, got %@", [message.body class]);
        return;
    }

    NSDictionary *body = (NSDictionary *)message.body;
    NSString *sessionId = [self stringValue:body[@"sessionId"]];
    if (sessionId.length == 0) {
        NSLog(@"Rokt hybrid: webview posted an empty sessionId");
        return;
    }

    NSString *sessionToken = [self stringValue:body[@"sessionToken"]];
    NSNumber *expiresAt = [self numberValue:body[@"expiresAt"]];
    MPRoktSession *session = [[MPRoktSession alloc] initWithSessionId:sessionId
                                                         sessionToken:sessionToken.length > 0 ? sessionToken : nil
                                                            expiresAt:expiresAt];

    NSLog(@"Rokt hybrid: applying web session to native (id=%@, token=%@)",
          session.sessionId,
          session.sessionToken.length > 0 ? @"present" : @"nil");

    [[MParticle sharedInstance].rokt setSession:session];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary<NSString *, NSString *> *attributes = @{
            @"email": @"j.smit@example.com",
            @"firstname": @"Jenny",
            @"lastname": @"Smith",
            @"sandbox": @"true",
            @"mobile": @"(555)867-5309"
        };
        [[MParticle sharedInstance].rokt selectPlacements:@"RoktLayout" attributes:attributes];
    });
}

- (nullable NSString *)stringValue:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value stringValue];
    }
    return nil;
}

- (nullable NSNumber *)numberValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)value;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *)value;
        if (string.length == 0) {
            return nil;
        }
        return @([string longLongValue]);
    }
    return nil;
}

@end
