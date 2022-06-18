import Defaults
import Foundation
import SDWebImageSwiftUI
import SwiftUI
import SwiftUIPager

struct VideoDetails: View {
    enum DetailsPage: CaseIterable {
        case info, chapters, comments, related, queue

        var index: Int {
            switch self {
            case .info:
                return 0
            case .chapters:
                return 1
            case .comments:
                return 2
            case .related:
                return 3
            case .queue:
                return 4
            }
        }
    }

    var sidebarQueue: Bool
    var fullScreen: Bool

    @State private var subscribed = false
    @State private var subscriptionToggleButtonDisabled = false
    @State private var presentingUnsubscribeAlert = false
    @State private var presentingAddToPlaylist = false
    @State private var presentingShareSheet = false
    @State private var shareURL: URL?

    @StateObject private var page: Page = .first()

    @Environment(\.navigationStyle) private var navigationStyle

    @EnvironmentObject<AccountsModel> private var accounts
    @EnvironmentObject<CommentsModel> private var comments
    @EnvironmentObject<NavigationModel> private var navigation
    @EnvironmentObject<PlayerModel> private var player
    @EnvironmentObject<RecentsModel> private var recents
    @EnvironmentObject<SubscriptionsModel> private var subscriptions

    @Default(.showKeywords) private var showKeywords
    @Default(.playerDetailsPageButtonLabelStyle) private var playerDetailsPageButtonLabelStyle
    @Default(.controlsBarInPlayer) private var controlsBarInPlayer

    var currentPage: DetailsPage {
        DetailsPage.allCases.first { $0.index == page.index } ?? .info
    }

    var video: Video? {
        player.currentVideo
    }

    func pageButton(
        _ label: String,
        _ symbolName: String,
        _ destination: DetailsPage,
        pageChangeAction: (() -> Void)? = nil
    ) -> some View {
        Button(action: {
            page.update(.new(index: destination.index))
            pageChangeAction?()
        }) {
            HStack {
                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: symbolName)

                    if playerDetailsPageButtonLabelStyle.text {
                        Text(label)
                    }
                }
                .frame(minHeight: 15)
                .lineLimit(1)
                .padding(.vertical, 4)
                .foregroundColor(currentPage == destination ? .white : .accentColor)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .background(currentPage == destination ? Color.accentColor : .clear)
        .buttonStyle(.plain)
        .font(.system(size: 10).bold())
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.accentColor, lineWidth: 2)
                .foregroundColor(.clear)
        )
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder func detailsByPage(_ page: DetailsPage) -> some View {
        Group {
            switch page {
            case .info:
                ScrollView(.vertical, showsIndicators: false) {
                    detailsPage
                }
            case .chapters:
                ChaptersView()
                    .edgesIgnoringSafeArea(.horizontal)

            case .queue:
                PlayerQueueView(sidebarQueue: sidebarQueue, fullScreen: fullScreen)
                    .edgesIgnoringSafeArea(.horizontal)

            case .related:
                RelatedView()
                    .edgesIgnoringSafeArea(.horizontal)
            case .comments:
                CommentsView(embedInScrollView: true)
                    .edgesIgnoringSafeArea(.horizontal)
            }
        }
        .contentShape(Rectangle())
    }

    var body: some View {
        VStack(alignment: .leading) {
            Group {
//                Group {
//                    subscriptionsSection
//                        .border(.red, width: 4)
//
//                        .onChange(of: video) { video in
//                            if let video = video {
//                                subscribed = subscriptions.isSubscribing(video.channel.id)
//                            }
//                        }
//                }
//                .padding(.top, 4)
//                .padding(.horizontal)

                HStack(spacing: 4) {
                    pageButton("Info", "info.circle", .info)
                    pageButton("Chapters", "bookmark", .chapters)
                    pageButton("Comments", "text.bubble", .comments) { comments.load() }
                    pageButton("Related", "rectangle.stack.fill", .related)
                    pageButton("Queue", "list.number", .queue)
                }
                .onChange(of: player.currentItem) { _ in
                    page.update(.moveToFirst)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .contentShape(Rectangle())

            Pager(page: page, data: DetailsPage.allCases, id: \.self) {
                detailsByPage($0)
            }
            .onPageWillChange { pageIndex in
                if pageIndex == DetailsPage.comments.index {
                    comments.load()
                } else {
                    print("comments not loading")
                }
            }
        }
        .onAppear {
            if video.isNil && !sidebarQueue {
                page.update(.new(index: DetailsPage.queue.index))
            }

            guard video != nil, accounts.app.supportsSubscriptions else {
                subscribed = false
                return
            }
        }
        .onChange(of: sidebarQueue) { queue in
            if queue {
                if currentPage == .related || currentPage == .queue {
                    page.update(.moveToFirst)
                }
            } else if video.isNil {
                page.update(.moveToLast)
            }
        }
        .edgesIgnoringSafeArea(.horizontal)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
    }

    var showAddToPlaylistButton: Bool {
        accounts.app.supportsUserPlaylists && accounts.signedIn
    }

    var subscriptionsSection: some View {
        Group {
            if let video = video {
                HStack(alignment: .center) {
                    HStack(spacing: 10) {
                        Group {
//                            ZStack(alignment: .bottomTrailing) {
//                                authorAvatar
//
//                                if subscribed {
//                                    Image(systemName: "star.circle.fill")
//                                        .background(Color.background)
//                                        .clipShape(Circle())
//                                        .foregroundColor(.secondary)
//                                }
//                            }

//                            VStack(alignment: .leading, spacing: 4) {
//                                Text(video.title)
//                                    .font(.system(size: 11))
//                                    .fontWeight(.bold)
//
//                                HStack(spacing: 4) {
//                                    Text(video.channel.name)
//
//                                    if let subscribers = video.channel.subscriptionsString {
//                                        Text("•")
//                                            .foregroundColor(.secondary)
//                                            .opacity(0.3)
//
//                                        Text("\(subscribers) subscribers")
//                                    }
//                                }
//                                .foregroundColor(.secondary)
//                                .font(.caption2)
//                            }
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 12))
                    .contextMenu {
                        if let video = video {
                            Button(action: {
                                NavigationModel.openChannel(
                                    video.channel,
                                    player: player,
                                    recents: recents,
                                    navigation: navigation,
                                    navigationStyle: navigationStyle
                                )
                            }) {
                                Label("\(video.channel.name) Channel", systemImage: "rectangle.stack.fill.badge.person.crop")
                            }
                        }
                    }
                }
            }
        }
    }

    var publishedDateSection: some View {
        Group {
            if let video = player.currentVideo {
                HStack(spacing: 4) {
                    if let published = video.publishedDate {
                        Text(published)
                    }
                }
            }
        }
    }

    var countsSection: some View {
        Group {
            if let video = player.currentVideo {
                HStack {
                    ShareButton(
                        contentItem: contentItem,
                        presentingShareSheet: $presentingShareSheet,
                        shareURL: $shareURL
                    )

                    Spacer()

                    if let views = video.viewsCount {
                        videoDetail(label: "Views", value: views, symbol: "eye")
                    }

                    if let likes = video.likesCount {
                        Divider()
                            .frame(minHeight: 35)

                        videoDetail(label: "Likes", value: likes, symbol: "hand.thumbsup")
                    }

                    if let dislikes = video.dislikesCount {
                        Divider()
                            .frame(minHeight: 35)

                        videoDetail(label: "Dislikes", value: dislikes, symbol: "hand.thumbsdown")
                    }

                    Spacer()

                    Button {
                        presentingAddToPlaylist = true
                    } label: {
                        Label("Add to Playlist", systemImage: "text.badge.plus")
                            .labelStyle(.iconOnly)
                            .help("Add to Playlist...")
                    }
                    .buttonStyle(.plain)
                    .opacity(accounts.app.supportsUserPlaylists ? 1 : 0)
                    #if os(macOS)
                        .frame(minWidth: 35, alignment: .trailing)
                    #endif
                }
                .frame(maxHeight: 35)
                .foregroundColor(.secondary)
            }
        }
        #if os(iOS)
        .background(
            EmptyView().sheet(isPresented: $presentingShareSheet) {
                if let shareURL = shareURL {
                    ShareSheet(activityItems: [shareURL])
                }
            }
        )
        #endif
    }

    private var contentItem: ContentItem {
        ContentItem(video: player.currentVideo!)
    }

    private var authorAvatar: some View {
        Group {
            if let video = video, let url = video.channel.thumbnailURL {
                WebImage(url: url)
                    .resizable()
                    .placeholder {
                        Rectangle().fill(Color("PlaceholderColor"))
                    }
                    .retryOnAppear(true)
                    .indicator(.activity)
                    .clipShape(Circle())
                    .frame(width: 35, height: 35, alignment: .leading)
            }
        }
    }

    var videoProperties: some View {
        HStack(spacing: 2) {
            publishedDateSection
            Spacer()

            HStack(spacing: 4) {
                if let views = video?.viewsCount {
                    Image(systemName: "eye")

                    Text(views)
                }

                if let likes = video?.likesCount {
                    Image(systemName: "hand.thumbsup")

                    Text(likes)
                }

                if let likes = video?.dislikesCount {
                    Image(systemName: "hand.thumbsdown")

                    Text(likes)
                }
            }
        }
        .font(.system(size: 12))
        .foregroundColor(.secondary)
    }

    var detailsPage: some View {
        Group {
            VStack(alignment: .leading, spacing: 0) {
                if let video = player.currentVideo {
                    VStack(spacing: 6) {
                        videoProperties

                        Divider()
                    }
                    .padding(.bottom, 6)

                    VStack(alignment: .leading, spacing: 10) {
                        if !player.videoBeingOpened.isNil && (video.description.isNil || video.description!.isEmpty) {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(1 ... Int.random(in: 3 ... 5), id: \.self) { _ in
                                    Text(String(repeating: Video.fixture.description!, count: Int.random(in: 1 ... 4)))
                                        .redacted(reason: .placeholder)
                                }
                            }
                        } else if let description = video.description {
                            Group {
                                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, *) {
                                    Text(description)
                                        .textSelection(.enabled)
                                } else {
                                    Text(description)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(size: 14))
                            .lineSpacing(3)
                        } else {
                            Text("No description")
                                .foregroundColor(.secondary)
                        }

                        if showKeywords {
                            ScrollView(.horizontal, showsIndicators: showScrollIndicators) {
                                HStack {
                                    ForEach(video.keywords, id: \.self) { keyword in
                                        HStack(alignment: .center, spacing: 0) {
                                            Text("#")
                                                .font(.system(size: 11).bold())

                                            Text(keyword)
                                                .frame(maxWidth: 500)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(Color("KeywordBackgroundColor"))
                                        .mask(RoundedRectangle(cornerRadius: 3))
                                    }
                                }
                                .padding(.bottom, 10)
                            }
                        }
                    }
                }

                if !video.isNil, CommentsModel.placement == .info {
                    Divider()
                    #if os(macOS)
                        .padding(.bottom, 20)
                    #else
                        .padding(.vertical, 10)
                    #endif
                }
            }
            .padding(.horizontal)

            LazyVStack {
                if !video.isNil, CommentsModel.placement == .info {
                    CommentsView()
                }
            }
        }
    }

    func videoDetail(label: String, value: String, symbol: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Image(systemName: symbol)

                Text(label.uppercased())
            }
            .font(.system(size: 9))
            .opacity(0.6)

            Text(value)
        }

        .frame(maxWidth: 100)
    }

    var showScrollIndicators: Bool {
        #if os(macOS)
            false
        #else
            true
        #endif
    }
}

struct VideoDetails_Previews: PreviewProvider {
    static var previews: some View {
        VideoDetails(sidebarQueue: true, fullScreen: false)
            .injectFixtureEnvironmentObjects()
    }
}
