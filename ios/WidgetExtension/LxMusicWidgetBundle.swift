import WidgetKit
import SwiftUI

@main
struct LxMusicWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            LyricsLiveActivity()
        }
    }
}
