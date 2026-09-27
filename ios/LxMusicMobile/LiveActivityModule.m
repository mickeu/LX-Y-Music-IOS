#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(LiveActivityModule, NSObject)

RCT_EXTERN_METHOD(startLyricsActivity:(NSString *)songName
                  artist:(NSString *)artist
                  fontSize:(NSInteger)fontSize
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(updateLyric:(NSString *)lyric
                  nextLyric:(NSString *)nextLyric
                  isPlaying:(BOOL)isPlaying
                  scrollOffset:(double)scrollOffset)

RCT_EXTERN_METHOD(updateFontSize:(NSInteger)fontSize)

RCT_EXTERN_METHOD(endLyricsActivity)

RCT_EXTERN_METHOD(isAvailable:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

@end
