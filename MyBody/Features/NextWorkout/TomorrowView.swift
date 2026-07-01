import SwiftUI
import SwiftData
import MyBodyCore

/// 明日训练（可编辑）。规格 §4。
struct TomorrowView: View {
    let todaySession: WorkoutSession
    @Binding var path: [WorkoutRoute]

    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @Query private var sessions: [WorkoutSession]
    @Query private var settingsList: [UserSettings]

    @State private var vm: TomorrowViewModel?
    @State private var pickerOpen = false

    var body: some View {
        Group {
            if let vm { content(vm) } else { Color.clear }
        }
        .background(Theme.Palette.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if vm == nil {
                vm = TomorrowViewModel(todaySession: todaySession, allExercises: allExercises,
                                       history: sessions, settings: settingsList.first)
            }
        }
        .sheet(isPresented: $pickerOpen) {
            if let vm { pickerSheet(vm) }
        }
    }

    private func content(_ vm: TomorrowViewModel) -> some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroCard(vm)
                    whyCard(vm).padding(.top, 14)
                    SectionLabel(text: "推荐动作").padding(.top, 22).padding(.horizontal, 4)
                    exerciseList(vm).padding(.top, 10)
                    PrimaryButton(title: "保存计划，明天见 👋") { save(vm) }
                        .padding(.top, 18)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }

    // MARK: 顶部

    private var header: some View {
        HStack {
            Button { if !path.isEmpty { path.removeLast() } } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.Palette.textPrimary.opacity(0.7))
                    .frame(width: 38, height: 38)
                    .background(Theme.Palette.surfaceTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            Spacer()
            Text("明日训练").font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.Palette.textPrimary)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    // MARK: Hero（随编辑实时更新）

    private func heroCard(_ vm: TomorrowViewModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SplitTag(text: vm.splitTag,
                         background: vm.isPull ? Theme.Palette.accentInfo : Theme.Palette.accent)
                Spacer()
                Text(dateLabel(vm.tomorrowDate))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            Text(vm.split.muscleHeadline)
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(Theme.Palette.textPrimary)
                .padding(.top, 14)
            Text(vm.metaLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.Palette.textSecondary)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(vm.isPull ? Theme.Palette.heroBlue : Theme.Palette.heroGreen)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous)
            .stroke((vm.isPull ? Theme.Palette.accentInfo : Theme.Palette.accent).opacity(0.18), lineWidth: 1))
    }

    // MARK: 为什么是这个分化

    private func whyCard(_ vm: TomorrowViewModel) -> some View {
        SurfaceCard(padding: 16, cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "为什么是\(vm.split.displayName)日")
                Text(vm.whyText)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Theme.Palette.textPrimary.opacity(0.78))
                    .lineSpacing(3)
            }
        }
    }

    // MARK: 动作列表

    private func exerciseList(_ vm: TomorrowViewModel) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(vm.items.enumerated()), id: \.element.id) { idx, item in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name).font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.Palette.textPrimary)
                        HStack(spacing: 4) {
                            Text("× \(item.repLow)–\(item.repHigh) 次")
                                .foregroundStyle(Theme.Palette.textTertiary)
                            Text("·").foregroundStyle(Theme.Palette.textTertiary)
                            Text(item.note)
                                .foregroundStyle(item.isProgression ? Theme.Palette.accent : Theme.Palette.textTertiary)
                                .fontWeight(item.isProgression ? .bold : .regular)
                        }
                        .font(.system(size: 12))
                    }
                    Spacer(minLength: 4)
                    HStack(spacing: 5) {
                        stepButton("−") { vm.decSets(item) }
                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text("\(item.sets)").font(.system(size: 16, weight: .heavy)).tabularNumbers()
                            Text("组").font(.system(size: 11)).foregroundStyle(Theme.Palette.textTertiary)
                        }
                        .frame(minWidth: 30)
                        stepButton("+") { vm.incSets(item) }
                    }
                    Button { vm.remove(item) } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.Palette.danger.opacity(0.85))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 13)
                if idx < vm.items.count - 1 { Divider().overlay(Theme.Palette.strokeInner) }
            }

            Divider().overlay(Theme.Palette.strokeInner)
            Button { pickerOpen = true } label: {
                HStack(spacing: 6) {
                    Text("+").font(.system(size: 19, weight: .bold))
                    Text("添加动作").font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(Theme.Palette.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .background(Theme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.Palette.stroke, lineWidth: 1))
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol).font(.system(size: 17))
                .foregroundStyle(Theme.Palette.textPrimary.opacity(0.8))
                .frame(width: 28, height: 28)
                .background(Theme.Palette.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: 添加动作半屏 sheet

    private func pickerSheet(_ vm: TomorrowViewModel) -> some View {
        let options = vm.availableToAdd(from: allExercises)
        return NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(options) { ex in
                        Button {
                            vm.add(ex)
                            if vm.availableToAdd(from: allExercises).isEmpty { pickerOpen = false }
                        } label: {
                            HStack(spacing: 12) {
                                Text(ex.groupTag)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.Palette.textSecondary)
                                    .frame(width: 40, height: 40)
                                    .background(Theme.Palette.surfaceSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ex.name).font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(Theme.Palette.textPrimary)
                                    Text(ex.metaLabel).font(.system(size: 12))
                                        .foregroundStyle(Theme.Palette.textTertiary)
                                }
                                Spacer()
                                Text("+").font(.system(size: 24, weight: .bold)).foregroundStyle(Theme.Palette.accent)
                            }
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.Palette.strokeInner)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Theme.Palette.background)
            .navigationTitle("添加动作")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { pickerOpen = false }
                        .foregroundStyle(Theme.Palette.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: 保存

    private func save(_ vm: TomorrowViewModel) {
        vm.save(context: context)
        path.removeAll()   // 回到今日
    }

    private func dateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M 月 d 日 · EEEE"
        return f.string(from: date)
    }
}
