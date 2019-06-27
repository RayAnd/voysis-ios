import UIKit
import Foundation

struct SocketRequest<E: Codable>: Codable {
    let entity: E?
    let method: String
    let requestID: String = "0"
    let headers: Headers
    let type = "request"
    let restURI: String

    enum CodingKeys: String, CodingKey {
        case entity, headers, method
        case requestID = "requestId"
        case restURI = "restUri"
        case type
    }
}

public struct RequestEntity<C: Context>: Codable {
    public let locale: String? = "en-US"
    public let audioQuery: AudioQuery?
    public let textQuery: TextQuery?
    public let queryType: String?
    public let userId: String?
    public let context: C?

    init(audioQuery: AudioQuery? = nil, textQuery: TextQuery? = nil, queryType: String? = nil, userId: String? = nil, context: C?) {
        self.audioQuery = audioQuery
        self.textQuery = textQuery
        self.queryType = queryType
        self.userId = userId
        self.context = context
    }
}

public struct AudioQuery: Codable {
    public let mimeType: String

    public init(mimeType: String) {
        self.mimeType = mimeType

    }
}

public struct TextQuery: Codable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

public struct Headers: Codable {
    var accept: String? = "application/vnd.voysisquery.v1+json"
    var audioProfileId: String? = ""
    var xVoysisIgnoreVad: Bool
    var authorization: String?
    var xVoysisClientInfo: String?

    public init(token: String, xVoysisIgnoreVad: Bool) {
        self.xVoysisIgnoreVad = xVoysisIgnoreVad
        authorization = "Bearer \(token)"
        audioProfileId = getAudioProfileId()
        xVoysisClientInfo = getClientVersionInfo()
    }

    init(accept: String?, xVoysisIgnoreVad: Bool, acceptLanguage: String?, authorization: String, audioProfileId: String?, clientVersionInfo: String?) {
        self.xVoysisIgnoreVad = xVoysisIgnoreVad
        self.audioProfileId = audioProfileId
        self.authorization = authorization
        self.xVoysisClientInfo = clientVersionInfo
        self.accept = accept
    }

    enum CodingKeys: String, CodingKey {
        case audioProfileId = "X-Voysis-Audio-Profile-Id"
        case xVoysisIgnoreVad = "X-Voysis-Ignore-Vad"
        case authorization = "Authorization"
        case xVoysisClientInfo = "X-Voysis-Client-Info"
        case accept = "Accept"
    }
}

public struct FeedbackData: Codable {
    public var durations = Duration()
    public var rating, description: String?

    public init() {

    }
}

public struct Duration: Codable {
    public var userStop, vad, complete: Int?

    public init() {

    }
}

public struct VersionInfo: Codable {
    public var id: String?
    public var version: String?

    public init(id: String?, version: String?) {
        self.id = id
        self.version = version
    }
}

public struct DeviceInfo: Codable {
    public var manufacturer: String?
    public var model: String?

    public init(manufacturer: String?, model: String?) {
        self.manufacturer = manufacturer
        self.model = model
    }
}

public struct ClientVersionInfo: Codable {
    public var os: VersionInfo
    public var sdk: VersionInfo
    public var app: VersionInfo
    public var device: DeviceInfo

    public init(os: VersionInfo, sdk: VersionInfo, app: VersionInfo, device: DeviceInfo) {
        self.os = os
        self.sdk = sdk
        self.app = app
        self.device = device
    }
}

extension Headers {

    private func getClientVersionInfo() -> String? {
        let current = UIDevice.current
        let appBundle = Bundle.main
        let libBundle = Bundle(for: VoysisWebSocketClient.self)
        let osInfo = VersionInfo(id: current.systemName, version: current.systemVersion)
        let sdkVersion = libBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let appVersion = appBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let sdkInfo = VersionInfo(id: libBundle.bundleIdentifier, version: sdkVersion as! String?)
        let appInfo = VersionInfo(id: appBundle.bundleIdentifier, version: appVersion as! String?)
        let deviceInfo = DeviceInfo(manufacturer: "Apple", model: current.model)
        let clientVersionInfo = ClientVersionInfo(os: osInfo, sdk: sdkInfo, app: appInfo, device: deviceInfo)
        return (try? String(data: JSONEncoder().encode(clientVersionInfo), encoding: .utf8)) ?? nil
    }

    public func getAudioProfileId() -> String {
        let defaults = UserDefaults.standard
        guard let id = defaults.string(forKey: "audioProfileId") else {
            let newId = UUID().uuidString
            defaults.set(newId, forKey: "audioProfileId")
            return newId
        }
        return id
    }
}
