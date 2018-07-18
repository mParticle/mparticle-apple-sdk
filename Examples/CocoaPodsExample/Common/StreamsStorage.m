#import "StreamsStorage.h"
#import "Stream.h"
#import "MParticle.h"

@interface StreamsStorage()

@property (nonatomic, strong) NSMutableArray<Stream *> *streams;

@end


@implementation StreamsStorage

- (NSArray *)fetchStreams {
    if (_streams.count > 0) {
        return (NSArray *)_streams;
    }
    
    NSArray *titles = @[@"Bip Bop",
                        @"Airshow (no sound)",
                        @"Back to the Mac",
                        @"Wild Life",
                        @"Mango Open Movie Project",
                        @"Oceans",
                        @"Artbeats",
                        @"Sintel Trailer",
                        @"\"Purchase\" of video (eCommerce)",
                        @"This will log an error",
                        @"This will log an exception",
                        [NSString stringWithFormat:@"This will toggle Opt Out state: %@", [[MParticle sharedInstance] optOut] ? @"Opted-Out" : @"Opted-In"]];
    
    NSArray *urls = @[@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8",
                      @"http://cdn3.viblast.com/streams/hls/airshow/playlist.m3u8",
                      @"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8",
                      @"http://playertest.longtailvideo.com/adaptive/wowzaid3/playlist.m3u8",
                      @"http://content.jwplatform.com/manifests/vM7nH0Kl.m3u8",
                      @"http://playertest.longtailvideo.com/adaptive/oceans_aes/oceans_aes.m3u8",
                      @"http://cdn-fms.rbs.com.br/vod/hls_sample1_manifest.m3u8",
                      @"http://walterebert.com/playground/video/hls/sintel-trailer.m3u8",
                      @"http://video-to-be-purchased",
                      @"This://is-not-a-valid-URL",
                      @"Exception",
                      @"OptOut"];
    
    NSUInteger idx = 0;

    _streams = [[NSMutableArray alloc] initWithCapacity:titles.count];

    for (NSString *title in titles) {
        NSURL *url = [NSURL URLWithString:urls[idx]];
        Stream *stream = [[Stream alloc] initWithTitle:title url:url];
        
        if (stream) {
            [_streams addObject:stream];
        }
        
        ++idx;
    }

    return (NSArray *)_streams;
}

@end
