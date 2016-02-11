//
//  MPDateFormatter.m
//
//  Copyright 2016 mParticle, Inc.
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

#import "MPDateFormatter.h"

static NSDateFormatter *dateFormatterRFC3339;

@implementation MPDateFormatter

+ (void)initialize {
    dateFormatterRFC3339 = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatterRFC3339 setLocale:enUSPOSIXLocale];
    [dateFormatterRFC3339 setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"];
    [dateFormatterRFC3339 setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

#pragma mark Public static methods
+ (NSDate *)dateFromStringRFC3339:(NSString *)dateString {
    NSDate *date = [dateFormatterRFC3339 dateFromString:dateString];
    return date;
}

+ (NSString *)stringFromDateRFC3339:(NSDate *)date {
    NSString *dateString = [dateFormatterRFC3339 stringFromDate:date];
    return dateString;
}

@end
