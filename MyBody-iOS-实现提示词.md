# MyBody — iOS App 实现提示词（交给 Claude Code）

> 把下面整段作为任务说明发给 Claude Code。如果能把 HTML 原型 `MyBody.dc.html` 一并提供作为视觉参考更好（它已实现全部界面与交互，可直接对照）。

---

## 角色与目标

你是一名资深 iOS 工程师。请用 **SwiftUI** 从零实现一个名为 **MyBody** 的健身记录 App，面向 **iPhone（iOS 17+）**。核心价值：记录每组动作的重量/次数、训练结束后科学评估"今天是否练够了"、并推荐明日训练；同时内置动作指导库。

不要做 Web、不要用 React Native / Flutter。纯原生 SwiftUI + Swift。

## 技术栈与工程要求

- **UI**：SwiftUI（iOS 17 起，可用 `Observable`、`@Bindable`）。
- **持久化**：**SwiftData**（`@Model`）。所有训练记录、计划、设置本地落库。
- **架构**：MVVM 轻量化。每个主界面一个 View + 一个 `@Observable` ViewModel；纯逻辑（评估、推荐、容量计算）抽到独立、可单元测试的 struct/enum，不依赖 UI。
- **依赖**：零第三方库，全部系统框架。
- **本地化**：界面中文，代码与类型英文。预留 `LocalizedStringKey`。
- **单位**：默认 **公斤 kg**（设置里预留 lb 切换接口，先不做完整换算 UI）。
- **测试**：为评估算法 `TrainingEvaluator` 和推荐算法 `NextWorkoutPlanner` 写 XCTest 单元测试。
- **强制浅色**（`preferredColorScheme(.light)`，不跟随系统深色）、Dynamic Type、安全区、Haptics（完成一组时轻触反馈）。

## 设计系统（严格遵守）

**浅色、明亮干净、青柠点缀**的运动风（不要深色/黑底）。整体是温暖米白底 + 白卡片 + 深墨文字，强调色克制使用。

- **背景** `#F4F2EC`（温暖米白）；**卡片面** `#FFFFFF`；**次级面/控件** `#EDECE4`（步进/筛选未选中）/ `#E9E7DF`（头像、返回按钮等）
- **主文字** `#1C1D1A`（暖墨黑）；次级 `rgba(28,29,26,0.55)`；三级 `rgba(28,29,26,0.4)`
- **强调色（草绿）** `#82B43C`，其上的文字用深墨 `#1C1D1A`（不用纯白）
- **次强调（拉日/信息）** `#7FC9E8`；**警示/超量** `#E04D38`；**RPE 偏高黄** `#C68A12`
- **分隔线/描边** `rgba(0,0,0,0.08)`（卡片边）、`rgba(0,0,0,0.06)`（行内分隔）
- **彩色 tint 卡**：推日 Hero 用淡绿渐变 `linear-gradient(155deg,#E7F0C6,#FFFFFF)`；拉日 Hero 用淡蓝 `linear-gradient(155deg,#DCEEF7,#FFFFFF)`；评估「建议」卡/动作「进阶处方」卡用淡青柠底 + 青柠细描边。
- **状态栏**：浅色主题 → 用**深色图标**（`.dark` content / `preferredColorScheme(.light)`）。
- **字体**：数字与大标题用粗重无衬线（系统 `SF Pro` Rounded/Bold 即可，原型用 Hanken Grotesk 风格——粗、紧字距）。数字一律 `tabular-nums` 等宽对齐。
- **圆角**：卡片 20–26、控件 9–14。**间距** 以 4 的倍数为节奏。
- **阴影**：白卡片在米白底上用极淡阴影（如 `color: black.opacity(0.05), radius 12, y 4`）或 1px 描边做分层，不要重投影。
- 大量留白、卡片化分组；青柠**只**用于主操作按钮、关键数据/数字、进度环与激活态。避免渐变滥用、避免表情符号堆砌（仅 🔥/👋 等点缀，可去）。
- 主按钮：高 54、圆角 16、青柠底 + 深墨字、加粗 17pt。

## 信息架构

底部 TabBar 三个 Tab：**今日** / **动作库** / **数据**。

训练流程是从「今日」推入的全屏流：
**今日 →（开始训练）训练记录 →（完成训练）今日评估 →（查看明日）明日训练**。
动作详情从「动作库」或「训练记录里的动作说明」推入。

## 数据模型（SwiftData `@Model`）

```
Exercise            // 动作库条目（内置种子数据）
  name, nameEN, muscleGroup(枚举: chest/back/legs/shoulders/arms/core),
  primaryMuscle, synergists, equipment, difficulty(入门/进阶/高级),
  cues:[String], mistakes:[String], prescription:String, isEachSide:Bool, weightStep:Double

WorkoutSession      // 一次训练
  date, splitType(枚举: push/pull/legs), status(planned/active/done),
  loggedExercises:[LoggedExercise], durationSec

LoggedExercise
  exercise:Exercise(关系), targetSets:Int, targetRepLow:Int, targetRepHigh:Int,
  lastSummary:String, sets:[SetEntry]

SetEntry
  weight:Double, reps:Int, rpe:Double, isDone:Bool

WorkoutPlan         // 明日/未来计划，可编辑
  date, splitType, items:[PlanItem]
PlanItem
  exercise(或 name), sets:Int, repLow:Int, repHigh:Int, note:String, isProgression:Bool

UserSettings
  unit(kg/lb), restDurationSec:Int(默认90), weeklyVolumeTargetKg:Double(默认7000),
  showRPE:Bool(默认true), split(默认 PPL)
```

种子数据：至少内置 12 个动作（覆盖 胸/背/腿/肩/臂），含完整 cues / mistakes / prescription（可从原型 `getLib()` 直接照搬中文内容）。

## 界面与交互细节

### 1. 今日总览（Home）
- 顶部：星期+日期、问候语、右上角头像。
- **训练计划 Hero 卡**：分化标签（推/拉/腿）、周期进度（如 3/6）、目标肌群大标题、`N 个动作 · M 组 · 约 X 分钟`、青柠「开始训练」主按钮。
- **本周条**：周一~周日 7 个圆点，已完成=青柠对勾、今天=青柠描边+分化字、休息=灰、未来=暗；显示连续天数。
- **本周训练容量**：按肌群的进度条（当前组数/周目标组数），达标或超出用黄色提示。
- **上次同分化摘要**：日期、总容量、组数、PR。

### 2. 训练记录（Active Workout）
- 顶部：关闭 X（回今日）、标题、**运行中的计时器**（mm:ss，从开始递增）、进度 `x/y 动作 · n 组完成`。
- 动作卡列表，点卡头展开/收起。展开后是组表：列 = 组号 / 重量(kg，带 −/+ 步进) / 次数(带 −/+ 步进) / RPE(可在设置隐藏) / 完成勾选框。
  - 步进重量按动作的 `weightStep`（卧推2.5、哑铃2.5、肩推5、侧平举1…）。
  - 勾选"完成"→ 触发 Haptic + **自动开始组间休息倒计时**（时长取设置 `restDurationSec`）。
  - RPE 颜色：≥9.5 红、≥9 黄、否则灰。
  - 「+ 加一组」复制上一组、「动作说明」推入详情。
- 底部固定：休息倒计时条（含 +15s / 跳过）+「完成训练」主按钮 → 评估页。

### 3. 今日评估（核心：今天练够了吗）
- 顶部进度环：**计划完成度 %**（已完成组/计划组）。
- 大判定文字：「今天练够了」/「还可以再练」。
- 2×2 数据格：总容量(kg)、完成/计划组、平均 RPE、周容量目标达成%。
- **评估依据**列表（3 条，基于真实计算的数字，引用训练科学概念：有效组数区间、RIR、MRV）。
- **建议卡**（青柠描边）：标题 + 一段解释（结束训练 / 再补 1–2 组）。
- 「查看明日训练 →」按钮。

### 4. 明日训练（可编辑）
- Hero：明日分化标签（拉/腿…）、目标肌群、`N 动作 · M 组 · 约 X 分钟`（**随编辑实时更新**）。
- 「为什么是这个分化」解释卡（基于恢复与分化逻辑）。
- 推荐动作列表，每行可：**± 调整组数**、**删除**；底部「+ 添加动作」弹出动作库选择表（半屏 sheet，点选即加入，已加入的不重复出现）。
- 渐进超负荷的动作行用青柠标注（如 `↑ 62.5kg +2.5`）。
- 「保存计划」→ 写入 `WorkoutPlan(date: 明天)`，回到今日。

### 5. 动作库（Library）
- 搜索框（按名称/肌群/器械过滤）+ 肌群筛选 chips（全部/胸/背/腿/肩/臂）。
- 列表行：占位缩略、名称、`主肌群 · 器械`、难度色标、箭头。点入详情。

### 6. 动作详情（Detail）
- 动作示范视频占位（先用条纹占位 + `[ 动作示范视频 ]`，预留 `AVPlayer` 接口）。
- 标签：主肌群 / 器械 / 难度。
- 主要肌群 / 协同肌群。
- **动作要点**（编号列表）、**常见错误**（红色 ✕）、**进阶处方**（青柠卡）。
- 「加入今日训练」按钮。

### 7. 数据（Stats）
- 本周容量按肌群进度条；每周总容量趋势柱状（近 4 周）；力量进步/PR 列表（带本周涨幅标注）。

## 训练科学算法（请实现为可测试的纯逻辑）

### A. 容量与有效组数
- 一次训练某肌群"有效组数" = 该肌群所有 `isDone` 且 `rpe >= 7`（RIR ≤ 3）的工作组数。
- 单组容量 = `weight * reps * (isEachSide ? 2 : 1)`；会话总容量 = 求和。
- 周容量按肌群累加，对照 `weeklyVolumeTarget` 与肌群组数区间（MEV≈10 / MAV≈16–20 / MRV≈22 组每周，作为常量可调）。

### B. `TrainingEvaluator`（今天练够了吗）
输入：本次会话的 完成组数 `done`、计划组数 `planned`、平均 RPE `avgRPE`、会话容量 `vol`、周目标 `target`。
```
compPct  = done / planned
achieve  = vol / target
enough   = (compPct >= 0.85) && (avgRPE >= 8.3)
```
- `enough == true` → 判定「今天练够了」，建议结束：理由强调已接近 MRV、边际收益低、优先恢复（蛋白质+睡眠）。
- `enough == false` →「还可以再练」，建议挑一个未力竭动作再补 1–2 组、把 RPE 推到 ~9。
- 生成 3 条"依据"字符串，内嵌真实数字（完成 done/planned、平均 RPE、容量与达成%）。
- 进度环数值 = `min(compPct,1)*100`。

> 阈值（0.85 / 8.3 / MEV-MAV-MRV）放在一个 `EvaluationConfig` 常量结构里，便于以后调参。

### C. `NextWorkoutPlanner`（明日推荐）
- **分化轮换**：Push → Pull → Legs → Push…（按 `UserSettings.split`，默认 PPL）。今日 push 则明日 pull。
- **恢复约束**：同一肌群两次训练间隔 ≥ 48h；推荐的明日分化不得与今日重叠主肌群。
- **渐进超负荷**：对某动作，如果"上次该动作最后一个工作组达到目标次数上限且 RPE ≤ 9"，则建议下次 `+1 档 weightStep`，并打 `isProgression = true`（UI 青柠标注）。否则维持重量、可加次数。
- 输出一份默认 `WorkoutPlan`（动作、组数、次数区间、note），用户可在明日页编辑。

## 验收标准
1. 能完整走通：今日 →开始训练→记录(增删组/调重量次数/勾完成/组间休息)→完成→评估(数字正确)→明日(可增删/调组数/加动作/保存)→回今日。
2. App 重启后训练记录、计划、设置仍在（SwiftData 落库）。
3. 评估与推荐结果与输入数据一致，且算法有单元测试覆盖典型用例（练够 / 没练够 / 触发渐进超负荷 / 分化轮换 / 48h 约束）。
4. 视觉符合上面的设计 token；浅色米白底、青柠点缀、等宽数字、44pt 以上点击区。
5. 动作库≥12 个动作含完整指导内容。

先给出工程结构与数据模型，再实现各界面，最后补算法单元测试。遇到不明确处，按训练科学常识与原型表现做合理默认，并在代码注释中标注假设。
```
```
