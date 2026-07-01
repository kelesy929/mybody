import SwiftUI
import MyBodyCore

/// 训练记录里的单个动作卡（卡头 + 展开的组表）。
struct ExerciseCardView: View {
    @Bindable var logged: LoggedExercise
    let index: Int
    let showRPE: Bool
    let unit: String
    let isExpanded: Bool
    let isEachSide: Bool
    let weightStep: Double

    let onExpand: () -> Void
    let onOpenDetail: () -> Void
    let onAddSet: () -> Void
    let onWeight: (SetEntry, Double) -> Void   // (set, direction ±1)
    let onReps: (SetEntry, Int) -> Void
    let onToggle: (SetEntry) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            if isExpanded {
                Divider().overlay(Theme.Palette.strokeInner)
                setTable
            }
        }
        .background(Theme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.Palette.stroke, lineWidth: 1))
    }

    // MARK: 卡头

    private var header: some View {
        Button(action: onExpand) {
            HStack(spacing: 13) {
                Text("\(index + 1)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(logged.isAllDone ? Theme.Palette.textPrimary : Theme.Palette.textPrimary.opacity(0.7))
                    .frame(width: 34, height: 34)
                    .background(logged.isAllDone ? Theme.Palette.accent : Theme.Palette.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(logged.exercise?.name ?? "")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Text("\(logged.targetLabel) · \(logged.lastSummary)")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Palette.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Text("\(logged.doneCount)/\(logged.sets.count)")
                    .font(.system(size: 13, weight: .bold))
                    .tabularNumbers()
                    .foregroundStyle(Theme.Palette.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(15)
        }
        .buttonStyle(.plain)
    }

    // MARK: 组表

    private var setTable: some View {
        VStack(spacing: 0) {
            columnHeader
            ForEach(logged.orderedSets) { set in
                SetRowView(set: set, showRPE: showRPE, weightStep: weightStep,
                           onWeight: onWeight, onReps: onReps, onToggle: onToggle)
            }
            actionRow
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 14)
        .padding(.top, 4)
    }

    private var columnHeader: some View {
        HStack(spacing: 8) {
            Text("组").frame(width: 22, alignment: .leading)
            Text("重量 (\(unit))").frame(maxWidth: .infinity)
            Text("次数").frame(maxWidth: .infinity)
            if showRPE { Text("RPE").frame(width: 38) }
            Spacer().frame(width: 32)
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(Theme.Palette.textTertiary)
        .padding(.vertical, 8)
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button(action: onAddSet) {
                Text("+ 加一组")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.Palette.textPrimary.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Theme.Palette.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onOpenDetail) {
                Text("动作说明")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.Palette.accent)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(Theme.Palette.textPrimary.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 10)
    }
}

/// 组表的一行。
private struct SetRowView: View {
    @Bindable var set: SetEntry
    let showRPE: Bool
    let weightStep: Double
    let onWeight: (SetEntry, Double) -> Void
    let onReps: (SetEntry, Int) -> Void
    let onToggle: (SetEntry) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("\(set.orderIndex + 1)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Palette.textSecondary)
                .frame(width: 22, alignment: .leading)

            stepper(value: NumberFormat.trim(set.weight),
                    onDown: { onWeight(set, -1) }, onUp: { onWeight(set, 1) })

            stepper(value: "\(set.reps)",
                    onDown: { onReps(set, -1) }, onUp: { onReps(set, 1) })

            if showRPE {
                Text(NumberFormat.trim(set.rpe))
                    .font(.system(size: 14, weight: .bold))
                    .tabularNumbers()
                    .foregroundStyle(Theme.Palette.rpeColor(set.rpe))
                    .frame(width: 38)
            }

            Button { onToggle(set) } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(set.isDone ? Theme.Palette.accent : Theme.Palette.surfaceSecondary)
                        .overlay(set.isDone ? nil : RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.Palette.textPrimary.opacity(0.16), lineWidth: 1))
                    if set.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(Theme.Palette.textPrimary)
                    }
                }
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 7)
        .opacity(set.isDone ? 1 : 0.9)
    }

    private func stepper(value: String, onDown: @escaping () -> Void, onUp: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            stepButton("−", action: onDown)
            Text(value)
                .font(.system(size: 17, weight: .heavy))
                .tabularNumbers()
                .frame(minWidth: 42)
            stepButton("+", action: onUp)
        }
        .frame(maxWidth: .infinity)
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 18))
                .foregroundStyle(Theme.Palette.textPrimary.opacity(0.8))
                .frame(width: 28, height: 28)
                .background(Theme.Palette.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
