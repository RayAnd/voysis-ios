import Foundation

public protocol Config {

    /**
     * @return refreshToken
     */
    var refreshToken: String { get }

    var userId: String? { get }

    /**
     * @return url used by client for making audio requests.
     */
    var url: URL { get }

    var audioRecordParams: AudioRecordParams? { get }
}
