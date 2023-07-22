import Foundation
import Speech
import AppKit

let app = NSApplication.shared

class AppDelegate: NSObject, NSApplicationDelegate {
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
        SFSpeechRecognizer.requestAuthorization({ (authStatus: SFSpeechRecognizerAuthorizationStatus) in
            if authStatus != .authorized {
                fatalError("Speech recognition authorization not granted.")
            }
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

            guard let guardedSpeechRecognizer = speechRecognizer else { fatalError("Unable to create a SpeechRecognizer object") }
            guard let recognitionRequest = self.recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.addsPunctuation = true
            if let onDeviceOnly = ProcessInfo.processInfo.environment["TRANSCRIBE_ON_DEVICE_ONLY"] {
                if onDeviceOnly == "1" {
                    recognitionRequest.requiresOnDeviceRecognition = true
                }
            }
            self.recognitionTask = guardedSpeechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                var isFinal = false
                if let result = result {
                    isFinal = result.isFinal
                    var segmentsArray: [[Any]] = []
                    for segment in result.bestTranscription.segments {
                        let segmentDict: [Any] = [
                            segment.substringRange.location,
                            segment.substringRange.length,
                            segment.confidence,
                            segment.timestamp,
                            segment.duration,
                        ]
                        segmentsArray.append(segmentDict)
                    }
                    let notification: [String: Any] = [
                        "text": result.bestTranscription.formattedString,
                        "segments": segmentsArray,
                        "isFinal": result.isFinal,
                    ]
                    let jsonData = try! JSONSerialization.data(withJSONObject: notification)
                    if let jsonString = String(data: jsonData, encoding: String.Encoding.utf8) {
                        print(jsonString)
                        fflush(stdout)
                    }
                }
                if error != nil || isFinal {
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    if let error = error {
                        fatalError(String(describing: error))
                    }
                    app.terminate(self)
                }
            }
            self.readAudioFromStandardInput()
        })
    }
    
    func readAudioFromStandardInput() {
        let stdinFileDescriptor = FileHandle.standardInput.fileDescriptor
        let ioChannel = DispatchIO(type: .stream, fileDescriptor: stdinFileDescriptor, queue: DispatchQueue.main) { (error) in
            if error != 0 {
                print("Error reading audio from standard input: \(error)")
            }
        }
        ioChannel.setLimit(lowWater: 1)
        ioChannel.setInterval(interval: .milliseconds(100))
        ioChannel.read(offset: 0, length: Int.max, queue: DispatchQueue.main) { (done, data, error) in
            if let data = data, !data.isEmpty {
                let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: false)
                let audioBuffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(data.count / 2))!
                audioBuffer.frameLength = audioBuffer.frameCapacity
                let audioBufferPointer = audioBuffer.int16ChannelData![0]
                data.withUnsafeBytes { bufferPointer in
                    audioBufferPointer.initialize(from: bufferPointer, count: data.count / 2)
                }
                self.recognitionRequest?.append(audioBuffer)
            }
            
            if done {
                // Mark the end of the audio stream.
                self.recognitionRequest?.endAudio()
            }
        }
        ioChannel.resume()
    }
}

let delegate = AppDelegate()
app.delegate = delegate
app.run()
