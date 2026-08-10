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
