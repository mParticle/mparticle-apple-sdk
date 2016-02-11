//
//  StreamsStorage.m
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

#import "StreamsStorage.h"
#import "Stream.h"

@interface StreamsStorage()

@property (nonatomic, strong) NSMutableArray<Stream *> *streams;

@end


@implementation StreamsStorage

- (NSArray *)fetchStreams {
    if (_streams.count > 0) {
        return (NSArray *)_streams;
    }
    
    NSArray *titles = @[@"Bip Bop",
                        @"Vevo Playlist",
                        @"Back to the Mac",
                        @"Wild Life",
                        @"Mango Open Movie Project",
                        @"Oceans",
                        @"Artbeats",
                        @"Sintel Trailer",
                        @"\"Purchase\" of video (eCommerce)",
                        @"This will log an error",
                        @"This will log an exception"];
    
    NSArray *urls = @[@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8",
                      @"http://vevoplaylist-live.hls.adaptive.level3.net/vevo/ch1/appleman.m3u8",
                      @"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8",
                      @"http://playertest.longtailvideo.com/adaptive/wowzaid3/playlist.m3u8",
                      @"http://content.jwplatform.com/manifests/vM7nH0Kl.m3u8",
                      @"http://playertest.longtailvideo.com/adaptive/oceans_aes/oceans_aes.m3u8",
                      @"http://cdn-fms.rbs.com.br/vod/hls_sample1_manifest.m3u8",
                      @"http://walterebert.com/playground/video/hls/sintel-trailer.m3u8",
                      @"http://video-to-be-purchased",
                      @"This://is-not-a-valid-URL",
                      @"Exception"];
    
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
