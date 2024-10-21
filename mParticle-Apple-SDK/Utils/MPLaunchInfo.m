#import "MPLaunchInfo.h"
#import "MPIConstants.h"
#import <UIKit/UIKit.h>
#import "MParticleSwift.h"
#import "MPILogger.h"
#import "mParticle.h"

@interface MPLaunchInfo() {
    NSString *sourceApp;
}

@end


@implementation MPLaunchInfo

- (instancetype)initWithURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    self = [super init];
    if (!self || MPIsNull(url)) {
        return nil;
    }
    
    sourceApp = sourceApplication;
    self.url = url;
    self.annotation = annotation;
    
    NSMutableDictionary *options = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    if (_sourceApplication) {
        options[UIApplicationOpenURLOptionsSourceApplicationKey] = _sourceApplication;
    }
    
    if (_annotation) {
        options[UIApplicationOpenURLOptionsAnnotationKey] = _annotation;
    }
    
    if (options.count > 0) {
        _options = [options copy];
    }
    
    return self;
}

- (nonnull instancetype)initWithURL:(nonnull NSURL *)url options:(nullable NSDictionary<NSString *, id> *)options {
    self = [super init];
    if (!self || MPIsNull(url)) {
        return nil;
    }
    
    _options = options;
    sourceApp = options[UIApplicationOpenURLOptionsSourceApplicationKey];
    self.annotation = options[UIApplicationOpenURLOptionsAnnotationKey];
    self.url = url;
    
    return self;
}

#pragma mark Public accessors
- (void)setAnnotation:(id)annotation {
    Class NSDateClass = [NSDate class];
    Class NSDataClass = [NSData class];
    Class NSDictionaryClass = [NSDictionary class];
    Class NSArrayClass = [NSArray class];
    Class NSSetClass = [NSSet class];
    
    id (^valueFromObject)(id) = ^(id obj) {
        id value = nil;
        
        if ([obj isKindOfClass:NSDateClass]) {
            value = [MPDateFormatter stringFromDateRFC3339:obj];
        } else if ([obj isKindOfClass:NSDataClass] || [obj isKindOfClass:NSDictionaryClass] || [obj isKindOfClass:NSArrayClass] || [obj isKindOfClass:NSSetClass]) {
            value = nil;
        } else {
            value = obj;
        }
        
        return value;
    };
    
    NSString * (^serializeDataObject)(id) = ^(id annotationObject) {
        NSData *annotationData = nil;
        NSError *error = nil;
        
        @try {
            annotationData = [NSJSONSerialization dataWithJSONObject:annotationObject options:0 error:&error];
        } @catch (NSException *exception) {
            MPILogError(@"Error serializing annotation from app launch: %@", annotationObject);
            return (NSString *)nil;
        }
        
        NSString *serializedAnnotation = !error ? [[NSString alloc] initWithData:annotationData encoding:NSUTF8StringEncoding] : nil;
        return serializedAnnotation;
    };
    
    if ([annotation isKindOfClass:[NSDictionary class]]) {
        __block NSMutableDictionary *annotationDictionary = [[NSMutableDictionary alloc] initWithCapacity:((NSDictionary *)annotation).count];
        
        [((NSDictionary *)annotation) enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
            id value = valueFromObject(obj);
            
            if (value) {
                annotationDictionary[key] = value;
            }
        }];
        
        _annotation = serializeDataObject(annotationDictionary);
    } else if ([annotation isKindOfClass:[NSArray class]]) {
        __block NSMutableArray *annotationArray = [[NSMutableArray alloc] initWithCapacity:((NSArray *)annotation).count];
        
        [((NSArray *)annotation) enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id value = valueFromObject(obj);
            
            if (value) {
                [annotationArray addObject:value];
            }
        }];
        
        _annotation = serializeDataObject(annotationArray);
    } else if ([annotation isKindOfClass:[NSString class]]) {
        _annotation = annotation;
    } else if ([annotation isKindOfClass:[NSNumber class]]) {
        _annotation = [annotation stringValue];
    } else if ([annotation isKindOfClass:NSDateClass]) {
        _annotation = valueFromObject(annotation);
    } else {
        _annotation = nil;
    }
}

- (void)setUrl:(NSURL *)url {
    _url = url;
    
    if (sourceApp) {
        NSString *urlString = [url absoluteString];
        NSRange appLinksRange = [urlString rangeOfString:@"al_applink_data"];
        _sourceApplication = appLinksRange.location == NSNotFound ? sourceApp : [[NSString alloc] initWithFormat:@"AppLink(%@)", sourceApp];
    } else {
        _sourceApplication = nil;
    }
}

@end
