//
//  MPRokt.h
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 4/22/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MPRoktEventCallback : NSObject

@property (nonatomic, copy, nullable) void (^onLoad)(void);
@property (nonatomic, copy, nullable) void (^onUnLoad)(void);
@property (nonatomic, copy, nullable) void (^onShouldShowLoadingIndicator)(void);
@property (nonatomic, copy, nullable) void (^onShouldHideLoadingIndicator)(void);
@property (nonatomic, copy, nullable) void (^onEmbeddedSizeChange)(NSString * _Nonnull, CGFloat);

@end

@interface MPRoktEmbeddedView : UIView

@end

@interface MPRokt : NSObject

- (void)selectPlacements:(NSString *_Nonnull)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes;

- (void)selectPlacements:(NSString *_Nonnull)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes
              placements:(NSDictionary<NSString *, MPRoktEmbeddedView *> * _Nullable)placements
               callbacks:(MPRoktEventCallback * _Nullable)roktEventCallback;

@end
