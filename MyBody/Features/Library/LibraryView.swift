import SwiftUI
import SwiftData
import MyBodyCore

/// 动作库（Library）。规格 §5。搜索 + 肌群筛选 → 详情。
struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query private var sessions: [WorkoutSession]
    @Query private var settingsList: [UserSettings]

    @State private var searchText = ""
    @State private var selectedGroup: MuscleGroup?   // nil = 全部

    private let filters: [(label: String, group: MuscleGroup?)] = [
        ("全部", nil), ("胸", .chest), ("背", .back), ("腿", .legs), ("肩", .shoulders), ("臂", .arms),
    ]

    private var filtered: [Exercise] {
        exercises.filter { ex in
            let matchGroup = selectedGroup == nil || ex.muscleGroup == selectedGroup
            let q = searchText.trimmingCharacters(in: .whitespaces)
            let matchSearch = q.isEmpty
                || ex.name.localizedCaseInsensitiveContains(q)
                || ex.nameEN.localizedCaseInsensitiveContains(q)
                || ex.muscleGroup.displayName.contains(q)
                || ex.primaryMuscle.contains(q)
                || ex.equipment.contains(q)
            return matchGroup && matchSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("动作库").font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(Theme.Palette.textPrimary)
                    searchBar
                    filterChips
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { ex in
                            NavigationLink(value: ex) { row(ex) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .background(Theme.Palette.background)
            .navigationDestination(for: Exercise.self) { ex in
                ExerciseDetailView(exercise: ex, primaryTitle: "加入今日训练",
                                   onPrimary: { addToToday(ex) })
            }
        }
    }

    // MARK: 搜索框

    private var searchBar: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15)).foregroundStyle(Theme.Palette.textTertiary)
            TextField("搜索动作、肌群或器械", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(Theme.Palette.textPrimary)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.Palette.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(Theme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.Palette.stroke, lineWidth: 1))
    }

    // MARK: 筛选 chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.label) { f in
                    let selected = selectedGroup == f.group
                    Button { selectedGroup = f.group } label: {
                        Text(f.label)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(selected ? Theme.Palette.textPrimary : Theme.Palette.textSecondary)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(selected ? Theme.Palette.accent : Theme.Palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(selected ? .clear : Theme.Palette.stroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: 列表行

    private func row(_ ex: Exercise) -> some View {
        HStack(spacing: 13) {
            Text(ex.groupTag)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.Palette.textSecondary)
                .frame(width: 46, height: 46)
                .background(Theme.Palette.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(ex.name).font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text(ex.metaLabel).font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.textTertiary)
            }
            Spacer(minLength: 4)
            Text(ex.difficulty.displayName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(difficultyColor(ex.difficulty))
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.Palette.textTertiary.opacity(0.7))
        }
        .padding(14)
        .background(Theme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.Palette.stroke, lineWidth: 1))
    }

    private func difficultyColor(_ d: Difficulty) -> Color {
        switch d {
        case .advanced: return Theme.Palette.danger
        case .intermediate: return Theme.Palette.warning
        case .beginner: return Theme.Palette.textSecondary
        }
    }

    // MARK: 加入今日训练

    private func addToToday(_ ex: Exercise) {
        let cal = Calendar.current
        let today = sessions.first { cal.isDateInToday($0.date) && $0.status != .done }
            ?? {
                let s = WorkoutSession(date: Date(), splitType: settingsList.first?.split ?? .push, status: .planned)
                context.insert(s)
                return s
            }()

        // 已在今日计划里则不重复添加。
        guard !today.loggedExercises.contains(where: { $0.exercise?.name == ex.name }) else { return }

        let order = today.loggedExercises.count
        let logged = LoggedExercise(exercise: ex, targetSets: 3, targetRepLow: 8, targetRepHigh: 12,
                                    lastSummary: "", orderIndex: order)
        logged.session = today
        context.insert(logged)
        for s in 0..<3 {
            let set = SetEntry(weight: 0, reps: 8, rpe: 8, isDone: false, orderIndex: s)
            set.loggedExercise = logged
            context.insert(set)
        }
        try? context.save()
        Haptics.success()
    }
}
