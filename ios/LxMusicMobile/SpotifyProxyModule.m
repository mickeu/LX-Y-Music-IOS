#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(SpotifyProxyModule, NSObject)

RCT_EXTERN_METHOD(start)
RCT_EXTERN_METHOD(stop)
RCT_EXTERN_METHOD(updateInfo:(NSString *)trackId
                  songName:(NSString *)songName
                  artist:(NSString *)artist
                  progressMs:(NSInteger)progressMs
                  durationMs:(NSInteger)durationMs
                  isPlaying:(BOOL)isPlaying)

@end
