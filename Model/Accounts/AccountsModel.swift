import Combine
import Defaults
import Foundation

final class AccountsModel: ObservableObject {
    @Published private(set) var current: Account!

    @Published private var invidious = InvidiousAPI()
    @Published private var piped = PipedAPI()
    @Published private var demo = DemoAppAPI()

    @Published var publicAccount: Account?

    private var cancellables = [AnyCancellable]()

    var all: [Account] {
        Defaults[.accounts]
    }

    var lastUsed: Account? {
        guard let id = Defaults[.lastAccountID] else {
            return nil
        }

        return AccountsModel.find(id)
    }

    var any: Account? {
        lastUsed ?? all.randomElement()
    }

    var app: VideosApp {
        current?.instance?.app ?? .invidious
    }

    var api: VideosAPI {
        switch app {
        case .piped:
            return piped
        case .invidious:
            return invidious
        case .demoApp:
            return demo
        }
    }

    var isEmpty: Bool {
        current.isNil
    }

    var signedIn: Bool {
        !isEmpty && !current.anonymous && api.signedIn
    }

    var isDemo: Bool {
        current?.app == .demoApp
    }

    init() {
        cancellables.append(
            invidious.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        )

        cancellables.append(
            piped.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        )
    }

    func configureAccount() {
        if let account = lastUsed ??
            InstancesModel.lastUsed?.anonymousAccount ??
            InstancesModel.all.first?.anonymousAccount
        {
            setCurrent(account)
        }
    }

    func setCurrent(_ account: Account! = nil) {
        guard account != current else {
            return
        }

        current = account

        guard !account.isNil else {
            return
        }

        switch account.instance.app {
        case .invidious:
            invidious.setAccount(account)
        case .piped:
            piped.setAccount(account)
        case .demoApp:
            break
        }

        Defaults[.lastAccountIsPublic] = account.isPublic

        if !account.isPublic {
            Defaults[.lastAccountID] = account.anonymous ? nil : account.id
            Defaults[.lastInstanceID] = account.instanceID
        }
    }

    static func find(_ id: Account.ID) -> Account? {
        Defaults[.accounts].first { $0.id == id }
    }

    static func add(instance: Instance, name: String, username: String, password: String) -> Account {
        let account = Account(instanceID: instance.id, name: name, url: instance.apiURL)
        Defaults[.accounts].append(account)

        setCredentials(account, username: username, password: password)

        return account
    }

    static func remove(_ account: Account) {
        if let accountIndex = Defaults[.accounts].firstIndex(where: { $0.id == account.id }) {
            let account = Defaults[.accounts][accountIndex]
            KeychainModel.shared.removeAccountKeys(account)
            Defaults[.accounts].remove(at: accountIndex)
        }
    }

    static func setToken(_ account: Account, _ token: String) {
        KeychainModel.shared.updateAccountKey(account, "token", token)
    }

    static func setCredentials(_ account: Account, username: String, password: String) {
        KeychainModel.shared.updateAccountKey(account, "username", username)
        KeychainModel.shared.updateAccountKey(account, "password", password)
    }

    static func getCredentials(_ account: Account) -> (String?, String?) {
        (
            KeychainModel.shared.getAccountKey(account, "username"),
            KeychainModel.shared.getAccountKey(account, "password")
        )
    }

    static func removeDefaultsCredentials(_ account: Account) {
        if let accountIndex = Defaults[.accounts].firstIndex(where: { $0.id == account.id }) {
            var account = Defaults[.accounts][accountIndex]
            account.name = ""
            account.username = ""
            account.password = nil

            Defaults[.accounts][accountIndex] = account
        }
    }
}
