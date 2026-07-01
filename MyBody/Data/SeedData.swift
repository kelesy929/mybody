import Foundation
import SwiftData
import MyBodyCore

/// 内置动作种子数据（中文内容照搬自原型 `getLib()`，覆盖 胸/背/腿/肩/臂，共 12 个）。
enum SeedData {

    /// 一条种子动作的定义。
    struct Def {
        let name, nameEN, primary, equipment: String
        let group: MuscleGroup
        let difficulty: Difficulty
        let synergists: [String]
        let cues, mistakes: [String]
        let rx: String
        let eachSide: Bool
        let step: Double
    }

    static let exercises: [Def] = [
        Def(name: "杠铃卧推", nameEN: "Barbell Bench Press", primary: "胸大肌（中部）", equipment: "杠铃 / 卧推架",
            group: .chest, difficulty: .intermediate, synergists: ["三头肌", "肩前束"],
            cues: ["肩胛后缩下沉，全程锁定在凳面，建立稳定的推力平台。",
                   "下放时杠铃对准乳头线，肘部约 45°–75°，不要过度外展。",
                   "脚踩实地面发力（Leg drive），核心收紧形成自然反弓。",
                   "触胸后向斜上方推回，保持手腕中立、肩胛不外展。"],
            mistakes: ["弹胸借力、下放过快，失去张力与控制。", "肘部完全外展 90°，增加肩关节压力。"],
            rx: "4 组 × 6–8 次，最后两组留 1–2 RIR；离心 2 秒、向心爆发。组间休息 2–3 分钟。每两周尝试 +2.5kg 渐进超负荷。",
            eachSide: false, step: 2.5),

        Def(name: "上斜哑铃卧推", nameEN: "Incline DB Press", primary: "胸大肌（上束）", equipment: "哑铃 / 上斜凳",
            group: .chest, difficulty: .intermediate, synergists: ["肩前束", "三头肌"],
            cues: ["凳面调 30°，过高会过多转移到肩部。", "哑铃下放至略低于胸，获得更大牵张幅度。", "顶端不锁死、不互碰，保持持续张力。"],
            mistakes: ["角度过陡变成肩推。", "下放幅度过小，牺牲胸部牵张。"],
            rx: "3 组 × 8–10 次，RPE 8–9；专注上胸的牵张与顶峰收缩，组间 90 秒。",
            eachSide: true, step: 2.5),

        Def(name: "双杠臂屈伸", nameEN: "Chest Dips", primary: "胸大肌（下束）", equipment: "双杠 / 自重",
            group: .chest, difficulty: .intermediate, synergists: ["三头肌", "肩前束"],
            cues: ["身体前倾、含胸，强化胸部参与。", "下放到肩略低于肘，感受充分牵张。", "可负重腰带渐进加载。"],
            mistakes: ["身体过于直立变成三头主导。", "下放过浅，行程不足。"],
            rx: "3 组 × 8–12 次；力量足够后用配重腰带 +5kg 渐进。组间 2 分钟。",
            eachSide: false, step: 2.5),

        Def(name: "引体向上", nameEN: "Pull-up", primary: "背阔肌", equipment: "单杠 / 自重",
            group: .back, difficulty: .intermediate, synergists: ["肱二头肌", "中背"],
            cues: ["先沉肩下压肩胛，再启动上拉。", "想象用肘把身体拉向杠，而非用手。", "顶端胸口靠近杠，底部充分伸展但不松肩。"],
            mistakes: ["借助摆动惯性（kipping）完成。", "只做半程，不到顶或不到底。"],
            rx: "4 组 × 6–10 次；力竭后接高位下拉补量。能做 12 次以上则负重。",
            eachSide: false, step: 2.5),

        Def(name: "杠铃划船", nameEN: "Barbell Row", primary: "背阔肌 · 斜方中束 · 菱形肌", equipment: "杠铃",
            group: .back, difficulty: .intermediate, synergists: ["肱二头肌", "后束"],
            cues: ["髋铰链前倾约 45°，背部保持中立不弓。", "杠铃拉向下腹，肘贴近身体。", "顶端挤压肩胛，控制离心。"],
            mistakes: ["用腰部摆动甩起重量。", "耸肩或圆背，风险高。"],
            rx: "4 组 × 8–10 次，RPE 8；本次建议 62.5kg（较上次 +2.5kg）。组间 2 分钟。",
            eachSide: false, step: 2.5),

        Def(name: "高位下拉", nameEN: "Lat Pulldown", primary: "背阔肌", equipment: "器械 / 绳索",
            group: .back, difficulty: .beginner, synergists: ["肱二头肌", "后束"],
            cues: ["略后仰，把杠拉向上胸。", "下拉时先沉肩，肘向下后方走。", "顶端控制回放，保持背阔张力。"],
            mistakes: ["身体大幅后仰借力。", "拉到颈后，增加肩压。"],
            rx: "3 组 × 10–12 次，RPE 8–9；宽握强调背阔宽度，组间 90 秒。",
            eachSide: false, step: 5),

        Def(name: "杠铃深蹲", nameEN: "Back Squat", primary: "股四头肌 · 臀大肌", equipment: "杠铃 / 深蹲架",
            group: .legs, difficulty: .advanced, synergists: ["内收肌", "竖脊肌"],
            cues: ["杠置于斜方上部，核心绷紧如负重呼吸（Valsalva）。", "髋膝同时下沉，膝盖顺脚尖方向。", "至少蹲到大腿与地面平行，全程脚跟踩实。"],
            mistakes: ["膝盖内扣（外翻塌陷）。", "重心前移、脚跟离地。"],
            rx: "4 组 × 5–8 次，RPE 7–8 留余量；离心可控、向心发力。组间 3 分钟。",
            eachSide: false, step: 5),

        Def(name: "罗马尼亚硬拉", nameEN: "Romanian Deadlift", primary: "腘绳肌 · 臀大肌", equipment: "杠铃",
            group: .legs, difficulty: .intermediate, synergists: ["竖脊肌", "背阔"],
            cues: ["髋向后推（髋铰链），膝微屈不下蹲。", "杠贴腿下滑，感受腘绳牵张。", "背始终中立，臀部发力站起。"],
            mistakes: ["弓背拉起，腰椎风险。", "变成深蹲、膝盖过度前移。"],
            rx: "3 组 × 8–10 次，RPE 8；底部牵张 1 秒，组间 2 分钟。",
            eachSide: false, step: 5),

        Def(name: "腿举", nameEN: "Leg Press", primary: "股四头肌 · 臀大肌", equipment: "器械",
            group: .legs, difficulty: .beginner, synergists: ["腘绳肌"],
            cues: ["脚踩中部与肩同宽，膝顺脚尖。", "下放至膝约 90°，腰部贴紧靠垫。", "顶端不锁死膝关节。"],
            mistakes: ["幅度过小只动一点点。", "下放时臀部离开靠垫卷腰。"],
            rx: "3 组 × 10–15 次，RPE 9；作为深蹲后的容量补充，组间 90 秒。",
            eachSide: false, step: 10),

        Def(name: "坐姿器械肩推", nameEN: "Machine Shoulder Press", primary: "肩前束 · 中束", equipment: "器械",
            group: .shoulders, difficulty: .beginner, synergists: ["三头肌"],
            cues: ["靠垫调好，手柄起始与肩同高。", "沿垂直方向推起，不锁死。", "控制离心回到耳侧高度。"],
            mistakes: ["行程过短。", "耸肩借力。"],
            rx: "3 组 × 8–10 次，RPE 8–9；器械稳定，适合推日力竭收尾。组间 90 秒。",
            eachSide: false, step: 5),

        Def(name: "哑铃侧平举", nameEN: "Lateral Raise", primary: "肩中束", equipment: "哑铃",
            group: .shoulders, difficulty: .beginner, synergists: ["斜方上束"],
            cues: ["小臂略屈，肘领先于手向两侧抬起。", "抬到与肩平即可，想象“倒水”微内旋。", "控制离心，慢放比甩起更重要。"],
            mistakes: ["用斜方耸肩借力。", "重量过大靠摆动。"],
            rx: "4 组 × 12–15 次，RPE 9–10；轻重量高次数 + 顶峰停顿，组间 60 秒。",
            eachSide: true, step: 1),

        Def(name: "绳索下压", nameEN: "Triceps Pushdown", primary: "肱三头肌", equipment: "绳索",
            group: .arms, difficulty: .beginner, synergists: ["前臂"],
            cues: ["大臂夹紧体侧固定，只动肘关节。", "底部分绳外展并完全伸直，顶峰收缩。", "控制回放，肘不前移。"],
            mistakes: ["大臂前后摆动借力。", "身体前倾用体重压。"],
            rx: "3 组 × 10–12 次，RPE 9；推日收尾孤立动作，组间 60–90 秒。",
            eachSide: false, step: 5),
    ]

    /// 若库为空则播种：写入 12 个动作 + 一条默认设置 + 今日一节计划好的推日训练。
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        guard existing.isEmpty else { return }

        var byName: [String: Exercise] = [:]
        for def in exercises {
            let ex = Exercise(
                name: def.name, nameEN: def.nameEN, muscleGroup: def.group,
                primaryMuscle: def.primary, synergists: def.synergists, equipment: def.equipment,
                difficulty: def.difficulty, cues: def.cues, mistakes: def.mistakes,
                prescription: def.rx, isEachSide: def.eachSide, weightStep: def.step)
            context.insert(ex)
            byName[def.name] = ex
        }

        // 默认设置（单例）。
        context.insert(UserSettings())

        // 今日：一节计划好的推日训练（与原型一致的 5 个动作）。
        seedTodayPushSession(context, byName: byName)

        try? context.save()
    }

    /// 构建今日推日的计划会话（status = planned），便于直接走「开始训练」流程。
    private static func seedTodayPushSession(_ context: ModelContext, byName: [String: Exercise]) {
        struct Plan { let name: String; let sets: Int; let lo: Int; let hi: Int; let startWeight: Double; let last: String }
        let plan: [Plan] = [
            Plan(name: "杠铃卧推", sets: 4, lo: 6, hi: 8, startWeight: 80, last: "上次 80kg×8"),
            Plan(name: "上斜哑铃卧推", sets: 3, lo: 8, hi: 10, startWeight: 30, last: "上次 30kg×9"),
            Plan(name: "坐姿器械肩推", sets: 3, lo: 8, hi: 10, startWeight: 50, last: "上次 50kg×9"),
            Plan(name: "哑铃侧平举", sets: 4, lo: 12, hi: 15, startWeight: 12, last: "上次 12kg×14"),
            Plan(name: "绳索下压", sets: 3, lo: 10, hi: 12, startWeight: 30, last: "上次 30kg×11"),
        ]

        let session = WorkoutSession(date: Date(), splitType: .push, status: .planned)
        context.insert(session)

        for (i, p) in plan.enumerated() {
            guard let ex = byName[p.name] else { continue }
            let logged = LoggedExercise(
                exercise: ex, targetSets: p.sets, targetRepLow: p.lo, targetRepHigh: p.hi,
                lastSummary: p.last, orderIndex: i)
            logged.session = session
            context.insert(logged)
            // 预置目标组数的空组（未完成），起始重量取上次值。
            for s in 0..<p.sets {
                let set = SetEntry(weight: p.startWeight, reps: p.lo, rpe: 8, isDone: false, orderIndex: s)
                set.loggedExercise = logged
                context.insert(set)
            }
        }
    }
}
