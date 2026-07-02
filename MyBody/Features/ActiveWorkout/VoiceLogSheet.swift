import SwiftUI
import MyBodyCore

/// 语音记一组：说出重量与次数，实时识别 + 预览解析结果，确认后写入。
struct VoiceLogSheet: View {
    let exerciseName: String
    let unit: String
    let onApply: (SpokenSet) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var recognizer = SpeechRecognizer()

    private var parsed: SpokenSet { SpeechParser.parse(recognizer.transcript) }

    var body: some View {
        VStack(spacing: 18) {
            Capsule().fill(Theme.Palette.surfaceSecondary).frame(width: 40, height: 5).padding(.top, 10)

            Text(exerciseName).font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.Palette.textPrimary)

            micCircle

            Text(hintText)
                .font(.system(size: 15))
                .foregroundStyle(recognizer.transcript.isEmpty ? Theme.Palette.textTertiary : Theme.Palette.textPrimary)
                .multilineTextAlignment(.center)
                .frame(minHeight: 44)
                .padding(.horizontal, 24)

            previewRow

            HStack(spacing: 12) {
                secondaryButton("重新说") { recognizer.stop(); recognizer.requestAuthAndStart() }
                PrimaryButton(title: "用这条", accessibilityID: "voice_apply") {
                    onApply(parsed)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .disabled(parsed.isEmpty)
                .opacity(parsed.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, 20)
            Spacer(minLength: 8)
        }
        .background(Theme.Palette.background)
        .presentationDetents([.height(380)])
        .onAppear { recognizer.requestAuthAndStart() }
        .onDisappear { recognizer.stop() }
    }

    private var micCircle: some View {
        ZStack {
            Circle()
                .fill(recognizer.state == .listening ? Theme.Palette.accent.opacity(0.18) : Theme.Palette.surfaceSecondary)
                .frame(width: 84, height: 84)
            Image(systemName: recognizer.state == .listening ? "waveform" : "mic.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(micColor)
        }
    }

    private var micColor: Color {
        switch recognizer.state {
        case .listening: return Theme.Palette.accent
        case .denied, .unavailable: return Theme.Palette.danger
        case .idle: return Theme.Palette.textSecondary
        }
    }

    private var hintText: String {
        switch recognizer.state {
        case .denied: return "未获得麦克风/语音识别权限，请在系统设置中开启"
        case .unavailable: return "当前设备暂不可用语音识别（模拟器可能无麦克风）"
        default:
            return recognizer.transcript.isEmpty
                ? "说出重量和次数，例如「八十公斤 八个」"
                : recognizer.transcript
        }
    }

    private var previewRow: some View {
        HStack(spacing: 26) {
            previewCell(parsed.weight.map { NumberFormat.trim($0) } ?? "—", unit)
            previewCell(parsed.reps.map { "\($0)" } ?? "—", "次")
        }
    }

    private func previewCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 28, weight: .heavy)).tabularNumbers()
                .foregroundStyle(value == "—" ? Theme.Palette.textTertiary : Theme.Palette.textPrimary)
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.Palette.textTertiary)
        }
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.Palette.textPrimary.opacity(0.7))
                .frame(height: Theme.Size.primaryButtonHeight)
                .padding(.horizontal, 22)
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                    .stroke(Theme.Palette.textPrimary.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
