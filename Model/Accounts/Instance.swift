import Defaults
import Foundation

struct Instance: Defaults.Serializable, Hashable, Identifiable {
    static var bridge = InstancesBridge()

    let app: VideosApp
    let id: String
    let name: String
    let apiURL: String
    var frontendURL: String?
    var proxiesVideos: Bool

    init(app: VideosApp, id: String? = nil, name: String, apiURL: String, frontendURL: String? = nil, proxiesVideos: Bool = false) {
        self.app = app
        self.id = id ?? UUID().uuidString
        self.name = name
        self.apiURL = apiURL
        self.frontendURL = frontendURL
        self.proxiesVideos = proxiesVideos
    }

    var anonymous: VideosAPI {
        switch app {
        case .invidious:
            return InvidiousAPI(account: anonymousAccount)
        case .piped:
            return PipedAPI(account: anonymousAccount)
        case .demoApp:
            return DemoAppAPI()
        }
    }

    var description: String {
        "\(app.name) - \(shortDescription)"
    }

    var longDescription: String {
        guard app != .demoApp else { return "Demo" }

        return name.isEmpty ? "\(app.name) - \(apiURL)" : "\(app.name) - \(name) (\(apiURL))"
    }

    var shortDescription: String {
        name.isEmpty ? apiURL : name
    }

    var anonymousAccount: Account {
        Account(instanceID: id, name: "Anonymous".localized(), url: apiURL, anonymous: true)
    }

    var urlComponents: URLComponents {
        URLComponents(string: apiURL)!
    }

    var frontendHost: String? {
        guard let url = app == .invidious ? apiURL : frontendURL else {
            return nil
        }

        return URLComponents(string: url)?.host
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(apiURL)
    }
}
