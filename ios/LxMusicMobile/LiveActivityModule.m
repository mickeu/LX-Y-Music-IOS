#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(LiveActivityModule, NSObject)

RCT_EXTERN_METHOD(writeLyricData:(NSString *)lrc
                  songName:(NSString *)songName
                  artist:(NSString *)artist
                  currentTime:(double)currentTime
                  duration:(double)duration
                  isPlaying:(BOOL)isPlaying)

RCT_EXTERN_METHOD(writeFontSize:(NSInteger)fontSize)

RCT_EXTERN_METHOD(startLyricsActivity:(NSString *)lrc
                  songName:(NSString *)songName
                  artist:(NSString *)artist
                  fontSize:(NSInteger)fontSize
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(updatePlaybackState:(NSString *)songName
                  currentTime:(double)currentTime
                  isPlaying:(BOOL)isPlaying)

RCT_EXTERN_METHOD(endLyricsActivity)

RCT_EXTERN_METHOD(isAvailable:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

@end
