//
//  MPKitApptentiveUtils.h
//  mParticle-Apptentive
//
//  Created by Alex Lementuev on 5/2/21.
//  Copyright © 2021 mParticle. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

id MPKitApptentiveParseValue(NSString *value);

/// Normalizes an mParticle `serviceRegion` config value to an ApptentiveKit region raw value (`us`, `eu`, or `au`).
/// Defaults to `us` when the value is missing, blank, unsupported (including `CA`), or unrecognized.
NSString * MPKitApptentiveNormalizeServiceRegion(NSString * _Nullable region);

NS_ASSUME_NONNULL_END
