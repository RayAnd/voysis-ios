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

    /**
      Voice Activity Detection will automatically detect when the user stops speaking and
      process the audio request.

      Note: setting this to true will cause the client to use a webSocket as opposed to a rest
      interface under the hood
      @return isVadEnabled boolean. default set to true.
     */
    var isVadEnabled : Bool { get }
}
