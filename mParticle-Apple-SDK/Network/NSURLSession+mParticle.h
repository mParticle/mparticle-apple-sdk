#import <Foundation/Foundation.h>

@interface NSURLSession(mParticle)

+ (void)freeResources;
+ (BOOL)methodsSwizzled;
+ (void)swizzleMethods;
+ (void)restoreMethods;
+ (void)excludeURLFromNetworkPerformanceMeasuring:(NSURL *)url;
+ (void)preserveQueryMeasuringNetworkPerformance:(NSString *)queryString;
+ (void)resetNetworkPerformanceExclusionsAndFilters;

@end
