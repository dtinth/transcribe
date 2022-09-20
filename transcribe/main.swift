import Foundation
import Speech
import AppKit

let app = NSApplication.shared

class AppDelegate: NSObject, NSApplicationDelegate {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // get language from command line
        let args = CommandLine.arguments
        var locale = Locale(identifier: "en-US")
        if args.count > 1 {
            locale = Locale(identifier: args[1])
        }

        let speechRecognizer = SFSpeechRecognizer(locale: locale)

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        SFSpeechRecognizer.requestAuthorization({ (authStatus: SFSpeechRecognizerAuthorizationStatus) in
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let guardedSpeechRecognizer = speechRecognizer else { fatalError("Unable to create a SpeechRecognizer object") }
            guard let recognitionRequest = self.recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
            recognitionRequest.shouldReportPartialResults = true
            self.recognitionTask = guardedSpeechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                var isFinal = false
                if let result = result {
                    isFinal = result.isFinal
                    let notification: [String: Any] = [
                        "text": result.bestTranscription.formattedString,
                        "isFinal": result.isFinal,
                    ]
                    let jsonData = try! JSONSerialization.data(withJSONObject: notification)
                    if let jsonString = String(data: jsonData, encoding: String.Encoding.utf8) {
                       print(jsonString)
                    }
                }
                if error != nil || isFinal {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    app.terminate(self)
                }
            }
        })
        audioEngine.prepare()
        try! audioEngine.start()
    }
}

let delegate = AppDelegate()
app.delegate = delegate
app.run()
