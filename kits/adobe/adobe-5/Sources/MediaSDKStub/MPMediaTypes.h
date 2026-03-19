// CI stub header for mParticle-Apple-Media-SDK.
// Defines the types needed by MPKitAdobeMedia.m so that pod lib lint can compile
// the AdobeMedia subspec against the local mParticle-Apple-SDK 9.0.0 without
// fetching the real CDN release (which requires mParticle-Apple-SDK ~> 8.37).
// TODO: Remove this file (and MPMediaTypes.m + mParticle-Apple-Media-SDK.podspec at repo root)
// once the mParticle-Apple-Media-SDK v9.0 PR is merged and released to CocoaPods CDN.

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MPMediaEventName) {
    MPMediaEventNameSessionStart,
    MPMediaEventNamePlay,
    MPMediaEventNamePause,
    MPMediaEventNameSessionEnd,
    MPMediaEventNameSeekStart,
    MPMediaEventNameSeekEnd,
    MPMediaEventNameBufferStart,
    MPMediaEventNameBufferEnd,
    MPMediaEventNameUpdatePlayheadPosition,
    MPMediaEventNameAdClick,
    MPMediaEventNameAdBreakStart,
    MPMediaEventNameAdBreakEnd,
    MPMediaEventNameAdStart,
    MPMediaEventNameAdEnd,
    MPMediaEventNameAdSkip,
    MPMediaEventNameSegmentStart,
    MPMediaEventNameSegmentSkip,
    MPMediaEventNameSegmentEnd,
    MPMediaEventNameUpdateQoS,
};

typedef NS_ENUM(NSInteger, MPMediaStreamType) {
    MPMediaStreamTypeOnDemand,
    MPMediaStreamTypeLinear,
    MPMediaStreamTypePodcast,
    MPMediaStreamTypeAudiobook,
};

typedef NS_ENUM(NSInteger, MPMediaContentType) {
    MPMediaContentTypeVideo,
    MPMediaContentTypeAudio,
};

@interface MPMediaAdBreak : NSObject
@property (nonatomic, copy, nullable) NSString *title;
@end

@interface MPMediaAdContent : NSObject
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *id;
@property (nonatomic, strong, nullable) NSNumber *position;
@property (nonatomic, strong, nullable) NSNumber *duration;
@property (nonatomic, copy, nullable) NSString *advertiser;
@property (nonatomic, copy, nullable) NSString *campaign;
@property (nonatomic, copy, nullable) NSString *creative;
@property (nonatomic, copy, nullable) NSString *placement;
@property (nonatomic, copy, nullable) NSString *siteId;
@end

@interface MPMediaSegment : NSObject
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong, nullable) NSNumber *duration;
@end

@interface MPMediaQoS : NSObject
@property (nonatomic, strong, nullable) NSNumber *bitRate;
@property (nonatomic, strong, nullable) NSNumber *startupTime;
@property (nonatomic, strong, nullable) NSNumber *fps;
@property (nonatomic, strong, nullable) NSNumber *droppedFrames;
@end

@interface MPMediaEvent : NSObject
@property (nonatomic, copy, nullable) NSString *mediaSessionId;
@property (nonatomic, assign) MPMediaEventName mediaEventName;
@property (nonatomic, assign) MPMediaStreamType streamType;
@property (nonatomic, assign) MPMediaContentType contentType;
@property (nonatomic, copy, nullable) NSString *mediaContentId;
@property (nonatomic, copy, nullable) NSString *mediaContentTitle;
@property (nonatomic, strong, nullable) NSNumber *duration;
@property (nonatomic, strong, nullable) NSNumber *playheadPosition;
@property (nonatomic, strong, nullable) MPMediaAdBreak *adBreak;
@property (nonatomic, strong, nullable) MPMediaAdContent *adContent;
@property (nonatomic, strong, nullable) MPMediaSegment *segment;
@property (nonatomic, strong, nullable) MPMediaQoS *qos;
@end
