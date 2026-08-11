//
//  MPKitApptentiveUtils.m
//  mParticle-Apptentive
//
//  Created by Alex Lementuev on 5/2/21.
//  Copyright © 2021 mParticle. All rights reserved.
//

#import "MPKitApptentiveUtils.h"

static NSNumber *parseNumber(NSString *str) {
    static NSNumberFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSNumberFormatter alloc] init];
    }
    
    return [formatter numberFromString:str];
}

id MPKitApptentiveParseValue(NSString *value) {
    if ([value caseInsensitiveCompare:@"true"] == NSOrderedSame) {
        return [NSNumber numberWithBool:YES];
    }
    
    if ([value caseInsensitiveCompare:@"false"] == NSOrderedSame) {
        return [NSNumber numberWithBool:NO];
    }
    
    NSNumber *number = parseNumber(value);
    if (number != nil) {
        return number;
    }
    
    return value;
}

NSString * MPKitApptentiveNormalizeServiceRegion(NSString * _Nullable region) {
    NSString *trimmed = [region stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return @"us";
    }

    if ([trimmed caseInsensitiveCompare:@"US"] == NSOrderedSame) {
        return @"us";
    }
    if ([trimmed caseInsensitiveCompare:@"EU"] == NSOrderedSame) {
        return @"eu";
    }
    if ([trimmed caseInsensitiveCompare:@"AU"] == NSOrderedSame) {
        return @"au";
    }
    if ([trimmed caseInsensitiveCompare:@"CA"] == NSOrderedSame) {
        NSLog(@"mParticle -> Apptentive serviceRegion 'CA' is not supported by the current Apptentive iOS SDK; defaulting to US.");
        return @"us";
    }

    NSLog(@"mParticle -> Unrecognized Apptentive serviceRegion '%@'; defaulting to US.", trimmed);
    return @"us";
}
