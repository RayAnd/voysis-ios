import Foundation

public struct DataConfig: Config {

    public let audioRecordParams: AudioRecordParams?
    public let refreshToken: String
    public let isVadEnabled : Bool
    public let userId: String?
    public let url: URL

    public init(url: URL, refreshToken: String, userId: String? = nil, audioRecordParams: AudioRecordParams? = nil, isVadEnabled : Bool = true) {
        self.audioRecordParams = audioRecordParams
        self.isVadEnabled = isVadEnabled
        self.refreshToken = refreshToken
        self.userId = userId
        self.url = url
    }

    public init(url: URL) {
        self.init(url: url, refreshToken: "")
    }
}