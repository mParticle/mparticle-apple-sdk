//
//  MPNetworkOptions.h
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Allows you to override the default HTTPS hosts and certificates used by the SDK.
 */
@interface MPNetworkOptions : NSObject

/**
Allows you to override the default configuration host.
*/
@property (nonatomic) NSString *configHost;
/**
Defaults to false. If set true the configHost above with overwrite the subdirectory of the URL in addition to the host.
*/
@property (nonatomic) BOOL overridesConfigSubdirectory;

/**
Allows you to override the default event host.
*/
@property (nonatomic) NSString *eventsHost;
/**
Defaults to false. If set true the eventsHost above with overwrite the subdirectory of the URL in addition to the host.
*/
@property (nonatomic) BOOL overridesEventsSubdirectory;

/**
Allows you to override the default identity host.
*/
@property (nonatomic) NSString *identityHost;
/**
Defaults to false. If set true the identityHost above with overwrite the subdirectory of the URL in addition to the host.
*/
@property (nonatomic) BOOL overridesIdentitySubdirectory;

/**
Allows you to override the default alias host.
*/
@property (nonatomic) NSString *aliasHost;
/**
Defaults to false. If set true the aliasHost above with overwrite the subdirectory of the URL in addition to the host.
*/
@property (nonatomic) BOOL overridesAliasSubdirectory;

@property (nonatomic) NSArray<NSData *> *certificates;

@property (nonatomic) BOOL pinningDisabledInDevelopment;
/**
Defaults to false. Prevents the eventsHost above from overwriting the alias endpoint.
*/
@property (nonatomic) BOOL eventsOnly;

@end

NS_ASSUME_NONNULL_END
