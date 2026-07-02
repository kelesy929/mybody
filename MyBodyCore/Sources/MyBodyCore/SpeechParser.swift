import Foundation

/// 语音识别文本 → 一组的重量/次数。纯逻辑，可在 Windows 单测。
public struct SpokenSet: Equatable, Sendable {
    public let weight: Double?
    public let reps: Int?
    public init(weight: Double?, reps: Int?) {
        self.weight = weight
        self.reps = reps
    }
    public var isEmpty: Bool { weight == nil && reps == nil }
}

/// 把中文口述（"八十公斤八个" / "80公斤8次" / "80 8"）解析成重量与次数。
public enum SpeechParser {

    private static let weightUnits = ["公斤", "千克", "kg", "KG", "Kg", "kilos", "kilo", "k"]
    private static let repUnits = ["个", "次", "下", "reps", "rep"]

    public static func parse(_ raw: String) -> SpokenSet {
        // 1. 中文数字转阿拉伯数字，统一小写，去多余空白。
        let text = convertChineseNumerals(raw).lowercased()

        // 2. 扫描「数字 + 紧随的可选单位」。
        var weight: Double?
        var reps: Int?
        var bares: [Double] = []

        let ns = text as NSString
        let pattern = #"([0-9]+(?:[.。][0-9]+)?)\s*([^0-9\s]*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return SpokenSet(weight: nil, reps: nil) }
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))

        for m in matches {
            let numStr = ns.substring(with: m.range(at: 1)).replacingOccurrences(of: "。", with: ".")
            guard let val = Double(numStr) else { continue }
            let tail = ns.substring(with: m.range(at: 2))

            if weight == nil, weightUnits.contains(where: { tail.hasPrefix($0.lowercased()) }) {
                weight = val
            } else if reps == nil, repUnits.contains(where: { tail.hasPrefix($0.lowercased()) }) {
                reps = Int(val.rounded())
            } else {
                bares.append(val)
            }
        }

        // 3. 无单位的裸数字：按「先重量后次数」补位。
        for b in bares {
            if weight == nil { weight = b }
            else if reps == nil { reps = Int(b.rounded()) }
        }
        return SpokenSet(weight: weight, reps: reps)
    }

    // MARK: 中文数字 → 阿拉伯数字

    /// 把字符串中连续的中文数字片段替换为阿拉伯数字（支持 十/百、点 小数）。
    static func convertChineseNumerals(_ s: String) -> String {
        let numeralChars = Set("零一二两三四五六七八九十百点")
        var result = ""
        var run = ""
        for ch in s {
            if numeralChars.contains(ch) {
                run.append(ch)
            } else {
                if !run.isEmpty { result += convertRun(run); run = "" }
                result.append(ch)
            }
        }
        if !run.isEmpty { result += convertRun(run) }
        return result
    }

    private static func convertRun(_ run: String) -> String {
        // 以「点」分割整数与小数。
        let parts = run.split(separator: "点", maxSplits: 1, omittingEmptySubsequences: false)
        guard let intVal = chineseInt(String(parts[0])) else { return run }  // 解析失败原样返回
        if parts.count == 2 {
            let frac = parts[1].compactMap { digit(for: $0) }.map(String.init).joined()
            if !frac.isEmpty, let d = Double("\(intVal).\(frac)") { return NumberFormat.trim(d) }
        }
        return String(intVal)
    }

    private static func digit(for c: Character) -> Int? {
        switch c {
        case "零": return 0; case "一": return 1; case "二", "两": return 2
        case "三": return 3; case "四": return 4; case "五": return 5
        case "六": return 6; case "七": return 7; case "八": return 8; case "九": return 9
        default: return nil
        }
    }

    /// 解析 0–999 的中文整数（十/百）。空串按 0。
    private static func chineseInt(_ run: String) -> Int? {
        if run.isEmpty { return nil }
        var total = 0
        var current = 0
        for c in run {
            if let d = digit(for: c) {
                current = d
            } else if c == "十" {
                total += (current == 0 ? 1 : current) * 10
                current = 0
            } else if c == "百" {
                total += (current == 0 ? 1 : current) * 100
                current = 0
            } else {
                return nil
            }
        }
        return total + current
    }
}
