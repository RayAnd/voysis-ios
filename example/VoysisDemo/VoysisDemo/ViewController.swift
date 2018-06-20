import UIKit
import Voysis
import AVFoundation

class ViewController: UIViewController, Callback {

    private let config = Config(url: URL(string: "ws://INSERT_URL/websocketapi")!, refreshToken: "INSERT_TOKEN")
    private lazy var voysis = Voysis.ServiceProvider.make(config: config)
    private var context: CommerceContext?

    @IBOutlet weak var response: UITextView!

    override func viewWillDisappear(_ animated: Bool) {
        voysis.cancel()
    }

    @IBAction func buttonClicked(_ sender: Any) {
        switch voysis.state {
        case .idle:
            voysis.startAudioQuery(context: self.context, callback: self)
        case .recording:
            voysis.finish()
        case .processing:
            voysis.cancel()
        }
    }

    func recordingStarted() {
        print("Recording Started")
    }

    func recordingFinished(reason: FinishedReason) {
        switch reason {
        case .vadReceived:
            print("Vad Received")
        case .manualStop:
            print("Manual Stop")
        }
    }

    func queryResponse(queryResponse: QueryResponse) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(queryResponse),
           let json = String(data: data, encoding: .utf8) {
            self.response.text = json
        }
    }

    func success(response: StreamResponse<CommerceContext, CommerceEntities>) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let context = response.context {
            self.context = context
        }
        if let data = try? encoder.encode(response),
           let json = String(data: data, encoding: .utf8) {
            self.response.text = json
        }
    }

    func failure(error: VoysisError) {
        self.response.text = error.localizedDescription
    }
}
