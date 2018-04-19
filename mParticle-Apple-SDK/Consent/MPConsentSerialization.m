#import "MPConsentSerialization.h"
#import "MPConsentState.h"
#import "MPILogger.h"
#import "MPIConstants.h"


@implementation MPConsentSerialization

#pragma mark public methods

+ (nullable NSDictionary *)serverDictionaryFromConsentState:(MPConsentState *)state {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    // ...
    return dictionary;
}

+ (nullable NSString *)stringFromConsentState:(MPConsentState *)state {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    // ...
    NSString *string = [self stringFromDictionary:dictionary];
    if (!string) {
        MPILogError(@"Failed to create string from consent dictionary=%@", dictionary);
        return nil;
    }
    return string;
}

+ (nullable MPConsentState *)consentStateFromString:(NSString *)string {
    MPConsentState *state = nil;
    NSDictionary *dictionary = [self dictionaryFromString:string];
    if (!dictionary) {
        MPILogError(@"Failed to create consent state from string=%@", string);
        return nil;
    }
    // ...
    return state;
}

#pragma mark private helpers

+ (nullable NSDictionary *)dictionaryFromString:(NSString *)string {
    const char *rawString = string.UTF8String;
    NSUInteger length = string.length;
    if (rawString == NULL || length == 0) {
        MPILogError(@"Empty or invalid UTF-8 C string when trying to convert string=%@", string);
        return nil;
    }
    
    NSData *data = [NSData dataWithBytes:rawString length:length];
    if (!data) {
        MPILogError(@"Unable to create NSData with UTF-8 rawString=%s length=%@", rawString, @(length));
        return nil;
    }
    
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error) {
        MPILogError(@"Creating JSON object failed with error=%@ when trying to deserialize data=%@", error, data);
        return nil;
    }
    
    if (!jsonObject) {
        MPILogError(@"Unable to create JSON object from data=%@", data);
        return nil;
    }
    
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unable to create NSDictionary (got %@ instead) when trying to deserialize JSON data=%@", [jsonObject class], data);
        return nil;
    }
    
    NSDictionary *dictionary = (NSDictionary *)jsonObject;
    return dictionary;
}

+ (nullable NSString *)stringFromDictionary:(NSDictionary *)dictionary {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    if (error) {
        MPILogError(@"NSJSONSerialization returned an error=%@ when trying to serialize dictionary=%@", error, dictionary);
        return nil;
    }
    if (!data) {
        MPILogError(@"Unable to create NSData with dictionary=%@", dictionary);
        return nil;
    }
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!string) {
        MPILogError(@"Unable to create UTF-8 string from JSON data=%@ dictionary=%@", data, dictionary);
        return nil;
    }
    return string;
}

@end
