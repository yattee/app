import SwiftUI

struct ShareButton: View {
    let contentItem: ContentItem

    @EnvironmentObject<AccountsModel> private var accounts
    @EnvironmentObject<NavigationModel> private var navigation
    @EnvironmentObject<PlayerModel> private var player

    init(contentItem: ContentItem) {
        self.contentItem = contentItem
    }

    var body: some View {
        Menu {
            instanceActions
            Divider()
            if !accounts.isDemo {
                youtubeActions
            }
        } label: {
            Label("Share...", systemImage: "square.and.arrow.up")
        }
        .menuStyle(.borderlessButton)
        #if os(macOS)
            .frame(maxWidth: 35)
        #endif
    }

    private var instanceActions: some View {
        Group {
            Button(labelForShareURL(accounts.app.name)) {
                if let url = player.playerAPI.shareURL(contentItem) {
                    shareAction(url)
                } else {
                    navigation.presentAlert(
                        title: "Could not create share link",
                        message: "For custom locations you can configure Frontend URL in Locations settings"
                    )
                }
            }

            if contentItemIsPlayerCurrentVideo {
                Button(labelForShareURL(accounts.app.name, withTime: true)) {
                    shareAction(
                        player.playerAPI.shareURL(
                            contentItem,
                            time: player.backend.currentTime
                        )!
                    )
                }
            }
        }
    }

    private var youtubeActions: some View {
        Group {
            if let url = accounts.api.shareURL(contentItem, frontendHost: "www.youtube.com") {
                Button(labelForShareURL("YouTube")) {
                    shareAction(url)
                }

                if contentItemIsPlayerCurrentVideo {
                    Button(labelForShareURL("YouTube", withTime: true)) {
                        shareAction(
                            accounts.api.shareURL(
                                contentItem,
                                frontendHost: "www.youtube.com",
                                time: player.backend.currentTime
                            )!
                        )
                    }
                }
            }
        }
    }

    private var contentItemIsPlayerCurrentVideo: Bool {
        contentItem.contentType == .video && contentItem.video?.videoID == player.currentVideo?.videoID
    }

    private func shareAction(_ url: URL) {
        #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(url.absoluteString, forType: .string)
        #else
            player.pause()
            navigation.shareURL = url
            navigation.presentingShareSheet = true
        #endif
    }

    private func labelForShareURL(_ app: String, withTime: Bool = false) -> String {
        if withTime {
            #if os(macOS)
                return String(format: "Copy %@ link with time".localized(), app)
            #else
                return String(format: "Share %@ link with time".localized(), app)
            #endif
        } else {
            #if os(macOS)
                return String(format: "Copy %@ link".localized(), app)
            #else
                return String(format: "Share %@ link".localized(), app)
            #endif
        }
    }
}

struct ShareButton_Previews: PreviewProvider {
    static var previews: some View {
        ShareButton(
            contentItem: ContentItem(video: Video.fixture)
        )
        .injectFixtureEnvironmentObjects()
    }
}
