//
//  MPLaunchInfo.m
//
//  Copyright 2015 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPLaunchInfo.h"
#import "MPIConstants.h"

@interface MPLaunchInfo() {
    NSString *sourceApp;
}

@end


@implementation MPLaunchInfo

- (instancetype)initWithURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    self = [super init];
    if (!self || MPIsNull(url) || MPIsNull(sourceApplication)) {
        return nil;
    }
    
    sourceApp = sourceApplication;
    self.url = url;
    self.annotation = annotation;
    
    return self;
}

- (void)setAnnotation:(id)annotation {
    BOOL (^shouldIncludeObject)(id) = ^(id obj) {
        BOOL shouldInclude = NO;
        if ([obj isKindOfClass:[NSString class]]) {
            shouldInclude = [obj length] <= 1024;
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            shouldInclude = YES;
        }
        
        return shouldInclude;
    };
    
    if ([annotation isKindOfClass:[NSDictionary class]]) {
        NSEnumerator *annotationEnumerator = [annotation keyEnumerator];
        NSMutableDictionary *paramsDictionary = [[NSMutableDictionary alloc] initWithCapacity:((NSDictionary *)annotation).count];
        NSString *key;
        id value;
 
        while ((key = [annotationEnumerator nextObject])) {
            value = annotation[key];
            
            if (shouldIncludeObject(value)) {
                paramsDictionary[key] = value;
            }
        }
        
        _annotation = paramsDictionary.count > 0 ? paramsDictionary : nil;
    } else if ([annotation isKindOfClass:[NSArray class]]) {
        NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:[annotation count]];
        
        for (id obj in annotation) {
            if (shouldIncludeObject(obj)) {
                [items addObject:obj];
            }
        }
        
        _annotation = items.count > 0 ? items : nil;
    } else if ([annotation isKindOfClass:[NSString class]]) {
        _annotation = shouldIncludeObject(annotation) ? annotation : nil;
    } else if ([annotation isKindOfClass:[NSNumber class]]) {
        _annotation = annotation;
    } else {
        _annotation = nil;
    }
}

- (void)setUrl:(NSURL *)url {
    _url = url;
    
    if (sourceApp) {
        NSString *urlString = [url absoluteString];
        NSRange appLinksRange = [urlString rangeOfString:@"al_applink_data"];
        
        if (appLinksRange.location == NSNotFound) {
            _sourceApplication = sourceApp;
        } else {
            _sourceApplication = [[NSString alloc] initWithFormat:@"AppLink(%@)", sourceApp];
        }
    } else {
        _sourceApplication = nil;
    }
}

@end
