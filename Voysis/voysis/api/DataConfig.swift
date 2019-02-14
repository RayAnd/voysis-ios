import Foundation

public struct DataConfig: Config {

    public let audioRecordParams: AudioRecordParams?
    public let refreshToken: String
    public let userId: String?
    public let url: URL

    public init(url: URL, refreshToken: String, userId: String? = nil, audioRecordParams: AudioRecordParams? = nil) {
        self.audioRecordParams = audioRecordParams
        self.refreshToken = refreshToken
        self.userId = userId
        self.url = url
    }

    public init(url: URL) {
        self.init(url: url, refreshToken: "")
    }
}