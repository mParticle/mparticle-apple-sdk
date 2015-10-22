//
//  MPDevice.h
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

#import <QuartzCore/QuartzCore.h>

@class CTCarrier;

extern NSString *const kMPDeviceInformationKey;


@interface MPDevice : NSObject <NSCopying>

@property (nonatomic, strong, readonly) NSString *advertiserId;
@property (nonatomic, strong, readonly) NSString *architecture;
@property (nonatomic, strong, readonly) NSString *brand;
@property (nonatomic, strong, readonly) CTCarrier *carrier;
@property (nonatomic, strong, readonly) NSString *country;
@property (nonatomic, strong, readonly) NSString *deviceIdentifier;
@property (nonatomic, strong, readonly) NSString *language;
@property (nonatomic, strong, readonly) NSNumber *limitAdTracking;
@property (nonatomic, strong, readonly) NSString *manufacturer __attribute__((const));
@property (nonatomic, strong, readonly) NSString *model;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *platform __attribute__((const));
@property (nonatomic, strong, readonly) NSString *product;
@property (nonatomic, strong, readonly) NSData *pushNotificationToken;
@property (nonatomic, strong, readonly) NSString *operatingSystem;
@property (nonatomic, strong, readonly) NSString *timezoneOffset;
@property (nonatomic, strong, readonly) NSString *timezoneDescription;
@property (nonatomic, strong, readonly) NSString *vendorId;
@property (nonatomic, strong, readonly) NSString *radioAccessTechnology;
@property (nonatomic, unsafe_unretained, readonly) CGSize screenSize;
@property (nonatomic, unsafe_unretained, readonly, getter = isTablet) BOOL tablet;

+ (NSDictionary *)jailbrokenInfo;
- (NSDictionary *)dictionaryRepresentation;

@end
