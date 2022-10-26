import Defaults
import MediaPlayer
import PINCache
import SDWebImage
import SDWebImageWebPCoder
import Siesta
import SwiftUI

@main
struct YatteeApp: App {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    }

    static var isForPreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    static var logsDirectory: URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    #if os(macOS)
        @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(iOS)
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @State private var configured = false

    @StateObject private var accounts = AccountsModel()
    @StateObject private var comments = CommentsModel()
    @StateObject private var instances = InstancesModel()
    @StateObject private var menu = MenuModel()
    @StateObject private var navigation = NavigationModel()
    @StateObject private var networkState = NetworkStateModel()
    @StateObject private var player = PlayerModel()
    @StateObject private var playlists = PlaylistsModel()
    @StateObject private var recents = RecentsModel()
    @StateObject private var search = SearchModel()
    @StateObject private var settings = SettingsModel()
    @StateObject private var subscriptions = SubscriptionsModel()
    @StateObject private var thumbnails = ThumbnailsModel()

    let persistenceController = PersistenceController.shared

    var playerControls: PlayerControlsModel { .shared }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear(perform: configure)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(accounts)
                .environmentObject(comments)
                .environmentObject(instances)
                .environmentObject(navigation)
                .environmentObject(networkState)
                .environmentObject(player)
                .environmentObject(playerControls)
                .environmentObject(playlists)
                .environmentObject(recents)
                .environmentObject(settings)
                .environmentObject(subscriptions)
                .environmentObject(thumbnails)
                .environmentObject(menu)
                .environmentObject(search)
            #if os(macOS)
                .background(
                    HostingWindowFinder { window in
                        Windows.mainWindow = window
                    }
                )
            #else
                    .onReceive(
                        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                    ) { _ in
                        player.handleEnterForeground()
                    }
                    .onReceive(
                        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
                    ) { _ in
                        player.handleEnterBackground()
                    }
            #endif
            #if os(iOS)
            .handlesExternalEvents(preferring: Set(["*"]), allowing: Set(["*"]))
            #endif
        }
        #if os(iOS)
        .handlesExternalEvents(matching: Set(["*"]))
        #endif
        #if !os(tvOS)
        .commands {
            SidebarCommands()

            CommandGroup(replacing: .newItem, addition: {})

            MenuCommands(model: Binding<MenuModel>(get: { menu }, set: { _ in }))
        }
        #endif

        #if os(macOS)
            WindowGroup(player.windowTitle) {
                VideoPlayerView()
                    .onAppear(perform: configure)
                    .background(
                        HostingWindowFinder { window in
                            Windows.playerWindow = window

                            NotificationCenter.default.addObserver(
                                forName: NSWindow.willExitFullScreenNotification,
                                object: window,
                                queue: OperationQueue.main
                            ) { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.player.playingFullScreen = false
                                }
                            }
                        }
                    )
                    .onAppear { player.presentingPlayer = true }
                    .onDisappear { player.presentingPlayer = false }
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environment(\.navigationStyle, .sidebar)
                    .environmentObject(accounts)
                    .environmentObject(comments)
                    .environmentObject(instances)
                    .environmentObject(navigation)
                    .environmentObject(networkState)
                    .environmentObject(player)
                    .environmentObject(playerControls)
                    .environmentObject(playlists)
                    .environmentObject(recents)
                    .environmentObject(search)
                    .environmentObject(subscriptions)
                    .environmentObject(thumbnails)
                    .handlesExternalEvents(preferring: Set(["player", "*"]), allowing: Set(["player", "*"]))
            }
            .handlesExternalEvents(matching: Set(["player", "*"]))

            Settings {
                SettingsView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(accounts)
                    .environmentObject(instances)
                    .environmentObject(navigation)
                    .environmentObject(player)
                    .environmentObject(playerControls)
                    .environmentObject(settings)
            }
        #endif
    }

    func configure() {
        guard !Self.isForPreviews, !configured else {
            return
        }
        configured = true

        #if DEBUG
            SiestaLog.Category.enabled = .common
        #endif
        SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)
        SDWebImageManager.defaultImageCache = PINCache(name: "stream.yattee.app")

        migrateAccounts()

        if !Defaults[.lastAccountIsPublic] {
            accounts.configureAccount()
        }

        if let countryOfPublicInstances = Defaults[.countryOfPublicInstances] {
            InstancesManifest.shared.setPublicAccount(countryOfPublicInstances, accounts: accounts, asCurrent: accounts.current.isNil)
        }

        playlists.accounts = accounts
        search.accounts = accounts
        subscriptions.accounts = accounts

        comments.player = player

        menu.accounts = accounts
        menu.navigation = navigation
        menu.player = player

        player.accounts = accounts
        player.comments = comments
        player.navigation = navigation

        PlayerModel.shared = player
        PlayerTimeModel.shared.player = player

        if !accounts.current.isNil {
            player.restoreQueue()
        }

        if !Defaults[.saveRecents] {
            recents.clear()
        }

        var section = Defaults[.visibleSections].min()?.tabSelection

        #if os(macOS)
            if section == .playlists {
                section = .search
            }
        #endif

        navigation.tabSelection = section ?? .search

        NavigationModel.shared = navigation

        subscriptions.load()
        playlists.load()

        #if !os(macOS)
            player.updateRemoteCommandCenter()
        #endif

        if player.presentingPlayer {
            player.presentingPlayer = false
        }

        #if os(iOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if Defaults[.lockPortraitWhenBrowsing] {
                    Orientation.lockOrientation(.portrait, andRotateTo: .portrait)
                }
            }
        #endif
    }

    func migrateAccounts() {
        Defaults[.accounts].forEach { account in
            if !account.username.isEmpty || !(account.password?.isEmpty ?? true) || !(account.name?.isEmpty ?? true) {
                print("Account needs migration: \(account.description)")
                if account.app == .invidious {
                    if let name = account.name, !name.isEmpty {
                        AccountsModel.setCredentials(account, username: name, password: "")
                    }
                    if !account.username.isEmpty {
                        AccountsModel.setToken(account, account.username)
                    }
                } else if account.app == .piped,
                          !account.username.isEmpty,
                          let password = account.password,
                          !password.isEmpty
                {
                    AccountsModel.setCredentials(account, username: account.username, password: password)
                }

                AccountsModel.removeDefaultsCredentials(account)
            }
        }
    }
}
