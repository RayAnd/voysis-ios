import UIKit
import Voysis
import AVFoundation

class ViewController: UIViewController, Callback {

    private let config = DataConfig(url: URL(string: "ws://INSERT_URL")!, refreshToken: "INSERT_TOKEN")
    private lazy var voysis = Voysis.ServiceProvider.make(config: config)
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var response: UITextView!
    private var context: CommerceContext?

    override func viewWillDisappear(_ animated: Bool) {
        voysis.cancel()
    }

    @IBAction func startClicked(_ sender: Any) {
        if voysis.state == .idle {
            voysis.startAudioQuery(context: self.context, callback: self)
        }
    }

    @IBAction func sendClicked(_ sender: Any) {
        if voysis.state == .idle {
            voysis.sendTextQuery(text: textField.text!, context: self.context, callback: self)
        }
    }

    @IBAction func stopClicked(_ sender: Any) {
        voysis.finish()
    }

    @IBAction func cancelClicked(_ sender: Any) {
        voysis.cancel()
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
