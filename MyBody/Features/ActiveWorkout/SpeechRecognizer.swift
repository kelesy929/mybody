import Foundation
import Speech
import AVFoundation

/// 中文语音识别（麦克风 → 实时文字）。仅 iOS，运行在 App 层。
@Observable
@MainActor
final class SpeechRecognizer {
    enum State: Equatable { case idle, listening, denied, unavailable }

    var state: State = .idle
    var transcript: String = ""

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_CN"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let engine = AVAudioEngine()

    /// 请求权限并开始识别。
    func requestAuthAndStart() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                guard status == .authorized else { self.state = .denied; return }
                self.start()
            }
        }
    }

    private func start() {
        guard let recognizer, recognizer.isAvailable else { state = .unavailable; return }
        transcript = ""
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            request = req

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                req.append(buffer)
            }
            engine.prepare()
            try engine.start()
            state = .listening

            task = recognizer.recognitionTask(with: req) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let result { self.transcript = result.bestTranscription.formattedString }
                    if error != nil || (result?.isFinal ?? false) { self.stop() }
                }
            }
        } catch {
            state = .unavailable
        }
    }

    func stop() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        if state == .listening { state = .idle }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
