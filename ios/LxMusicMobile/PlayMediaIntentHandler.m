#import "PlayMediaIntentHandler.h"

@implementation PlayMediaIntentHandler

- (void)handleIntent:(INPlayMediaIntent *)intent
          completion:(void (^)(INPlayMediaIntentResponse *))completion
{
    NSMutableArray *mediaNames = [NSMutableArray array];
    for (INMediaItem *item in intent.mediaItems) {
        if (item.identifier) {
            [mediaNames addObject:item.identifier];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:@"LXSpotifyPlayMedia"
                          object:nil
                        userInfo:@{
                            @"mediaItems": mediaNames,
                            @"playShuffled": @(intent.playShuffled.boolValue)
                        }];
    });

    INPlayMediaIntentResponse *response =
        [[INPlayMediaIntentResponse alloc] initWithCode:INPlayMediaIntentResponseCodeSuccess
                                            userActivity:nil];
    completion(response);
}

@end
