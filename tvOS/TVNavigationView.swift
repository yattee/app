import Defaults
import SwiftUI

struct TVNavigationView: View {
    @EnvironmentObject<AccountsModel> private var accounts
    @EnvironmentObject<PlayerModel> private var player
    @EnvironmentObject<NavigationModel> private var navigation
    @EnvironmentObject<RecentsModel> private var recents
    @EnvironmentObject<SearchModel> private var search

    @Default(.visibleSections) private var visibleSections
    var body: some View {
        TabView(selection: navigation.tabSelectionBinding) {
            if visibleSections.contains(.favorites) {
                FavoritesView()
                    .tabItem { Text("Favorites") }
                    .tag(TabSelection.favorites)
            }

            if visibleSections.contains(.subscriptions), accounts.app.supportsSubscriptions {
                SubscriptionsView()
                    .tabItem { Text("Subscriptions") }
                    .tag(TabSelection.subscriptions)
            }

            if visibleSections.contains(.popular), accounts.app.supportsPopular {
                PopularView()
                    .tabItem { Text("Popular") }
                    .tag(TabSelection.popular)
            }

            if visibleSections.contains(.trending) {
                TrendingView()
                    .tabItem { Text("Trending") }
                    .tag(TabSelection.trending)
            }

            if visibleSections.contains(.playlists), accounts.app.supportsUserPlaylists {
                PlaylistsView()
                    .tabItem { Text("Playlists") }
                    .tag(TabSelection.playlists)
            }

            NowPlayingView()
                .tabItem { Text("Now Playing") }
                .tag(TabSelection.nowPlaying)

            SearchView()
                .tabItem { Image(systemName: "magnifyingglass") }
                .tag(TabSelection.search)
        }
        .fullScreenCover(isPresented: $navigation.presentingSettings) { SettingsView() }
        .fullScreenCover(isPresented: $navigation.presentingAddToPlaylist) {
            if let video = navigation.videoToAddToPlaylist {
                AddToPlaylistView(video: video)
            }
        }
        .fullScreenCover(isPresented: $player.presentingPlayer) {
            VideoPlayerView()
        }
        .fullScreenCover(isPresented: $navigation.presentingChannel) {
            if let channel = recents.presentedChannel {
                ChannelVideosView(channel: channel)
            }
        }
        .fullScreenCover(isPresented: $navigation.presentingPlaylist) {
            if let playlist = recents.presentedPlaylist {
                ChannelPlaylistView(playlist: playlist)
            }
        }
        .onPlayPauseCommand { navigation.presentingSettings.toggle() }
    }
}

struct TVNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        TVNavigationView()
            .injectFixtureEnvironmentObjects()
    }
}
