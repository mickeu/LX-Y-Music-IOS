#import <React/RCTBridgeModule.h>

// ObjC 桥接文件，让 Swift 的 LiveActivityModule 暴露给 RN
@interface RCT_EXTERN_MODULE(LiveActivityModule, NSObject)

RCT_EXTERN_METHOD(startLyricsActivity:(NSString *)songName
                  artist:(NSString *)artist
                  fontSize:(NSInteger)fontSize)

RCT_EXTERN_METHOD(updateLyric:(NSString *)lyric
                  nextLyric:(NSString *)nextLyric
                  isPlaying:(BOOL)isPlaying)

RCT_EXTERN_METHOD(updateFontSize:(NSInteger)fontSize)

RCT_EXTERN_METHOD(endLyricsActivity)

RCT_EXTERN_METHOD(isAvailable:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

@end
