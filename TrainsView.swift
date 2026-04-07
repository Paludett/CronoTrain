import SwiftUI

// MARK: - TrainsView

struct TrainsView: View {
    @EnvironmentObject private var store: WorkoutStore
    @EnvironmentObject private var sessionManager: WorkoutSessionManager
    @State private var showCreateSheet = false
    @Binding var selectedTab: Int

    private var activeWorkout: Workout? {
        guard sessionManager.isRunning, let active = sessionManager.activeWorkout else { return nil }
        return store.workouts.first(where: { $0.id == active.id })
    }

    private var inactiveWorkouts: [Workout] {
        guard let active = sessionManager.activeWorkout, sessionManager.isRunning else {
            return store.workouts
        }
        return store.workouts.filter { $0.id != active.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let nowWorkout = activeWorkout {
                        sectionHeader("Now Playing")
                        NavigationLink {
                            WorkoutDetailView(workoutID: nowWorkout.id, selectedTab: $selectedTab)
                        } label: {
                            WorkoutCard(workout: nowWorkout)
                        }
                        .buttonStyle(.plain)
                    }

                    sectionHeader(activeWorkout != nil ? "Your Workouts" : "Workouts")

                    VStack(spacing: 10) {
                        if inactiveWorkouts.isEmpty {
                            EmptyStateCard(message: "No workouts yet")
                        } else {
                            ForEach(inactiveWorkouts) { workout in
                                NavigationLink {
                                    WorkoutDetailView(workoutID: workout.id, selectedTab: $selectedTab)
                                } label: {
                                    WorkoutCard(workout: workout)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground)
            .navigationTitle("Trains")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.brandPurple)
                    }
                    .accessibilityLabel("Add workout")
                }
            }
        }
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(isPresented: $showCreateSheet) {
            CreateWorkoutSheet()
                .presentationDetents([.large])
        }
        .animation(.easeInOut(duration: 0.2), value: store.workouts)
        .animation(.easeInOut(duration: 0.3), value: sessionManager.isRunning)
        .animation(.easeInOut(duration: 0.3), value: sessionManager.activeWorkout?.id)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.secondaryText)
            .textCase(.uppercase)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
    }
}

// MARK: - WorkoutCard

struct WorkoutCard: View {
    var workout: Workout

    var body: some View {
        HStack(spacing: 14) {
            // Activity icon
            ZStack {
                Circle()
                    .fill(Color.purpleSurface)
                    .frame(width: 44, height: 44)

                Image(systemName: workout.activityType.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.brandPurple)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(workout.activityType.rawValue)
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)

                    Text("·")
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText.opacity(0.6))

                    Text(totalMinutes)
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)

                    if workout.streakCount > 0 {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText.opacity(0.6))

                        HStack(spacing: 2) {
                            Text("🔥")
                                .font(.caption2)
                            Text("\(workout.streakCount)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.brandPurple)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondaryText.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .appCardBackground()
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var totalMinutes: String {
        let minutes = max(1, Int(ceil(Double(workout.totalDurationSeconds) / 60.0)))
        return "\(minutes) min"
    }
}

// MARK: - EmptyStateCard

struct EmptyStateCard: View {
    var message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title3)
                .foregroundStyle(Color.secondaryText.opacity(0.5))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .appCardBackground()
    }
}

// MARK: - CreateWorkoutSheet

struct CreateWorkoutSheet: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var activityType: ActivityType = .run
    @State private var scheduledDays: Set<Int> = []
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            VStack(alignment: .leading, spacing: 10) {
                Text("Workout Name")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)
                TextField("Workout name", text: $name)
                    .focused($isNameFocused)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isNameFocused ? Color.brandPurple.opacity(0.4) : Color.brandPurple.opacity(0.2), lineWidth: 1)
                    )
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Activity")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)
                Picker("Activity", selection: $activityType) {
                    ForEach(ActivityType.allCases) { type in
                        Label(type.rawValue, systemImage: type.iconName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Color.brandPurple)
            }

            WeekdayPicker(selectedDays: $scheduledDays)

            Button {
                let workout = Workout(name: name.trimmingCharacters(in: .whitespacesAndNewlines), activityType: activityType, segments: [], scheduledDays: scheduledDays)
                store.addWorkout(workout)
                dismiss()
            } label: {
                Text("Create Workout")
                    .appPrimaryButton()
            }
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(Color.sheetBackground)
    }

    private var header: some View {
        ZStack {
            Text("New Workout")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.primaryText)
                .frame(maxWidth: .infinity)
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(Color.brandPurple)
                        .padding(10)
                        .background(Color.cardBackground)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close")
            }
        }
        .padding(.bottom, 6)
    }
}

// MARK: - WorkoutDetailView

struct WorkoutDetailView: View {
    @EnvironmentObject private var store: WorkoutStore
    @EnvironmentObject private var sessionManager: WorkoutSessionManager
    @Environment(\.dismiss) private var dismiss
    var workoutID: UUID
    @Binding var selectedTab: Int

    @State private var showAddTimerSheet = false
    @State private var isEditing = false
    @State private var editingWorkout: Workout? = nil
    @State private var editingSegment: TimerSegment? = nil
    @State private var pendingDeleteSegment: TimerSegment? = nil
    @State private var showDeleteAlert = false
    @State private var draggingSegment: TimerSegment? = nil
    @FocusState private var isWorkoutNameFocused: Bool

    // Local mutable copy used while editing
    private var draftWorkout: Workout {
        editingWorkout ?? (store.workouts.first(where: { $0.id == workoutID }) ?? Workout(name: "", activityType: .gym, segments: []))
    }

    private var segmentsBinding: Binding<[TimerSegment]> {
        Binding(
            get: { editingWorkout?.segments ?? [] },
            set: { editingWorkout?.segments = $0 }
        )
    }

    var body: some View {
        Group {
            if let storeWorkout = store.workouts.first(where: { $0.id == workoutID }) {
                let workout = isEditing ? draftWorkout : storeWorkout
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Editable name & activity
                        if isEditing {
                            VStack(alignment: .leading, spacing: 12) {
                                TextField("Workout name", text: Binding(
                                    get: { editingWorkout?.name ?? storeWorkout.name },
                                    set: { editingWorkout?.name = $0 }
                                ))
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color.primaryText)
                                .focused($isWorkoutNameFocused)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(isWorkoutNameFocused ? Color.brandPurple.opacity(0.4) : Color.brandPurple.opacity(0.2), lineWidth: 1)
                                )

                                Picker("Activity", selection: Binding(
                                    get: { editingWorkout?.activityType ?? storeWorkout.activityType },
                                    set: { editingWorkout?.activityType = $0 }
                                )) {
                                    ForEach(ActivityType.allCases) { type in
                                        Label(type.rawValue, systemImage: type.iconName).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .tint(Color.brandPurple)

                                WeekdayPicker(selectedDays: Binding(
                                    get: { editingWorkout?.scheduledDays ?? storeWorkout.scheduledDays },
                                    set: { editingWorkout?.scheduledDays = $0 }
                                ))
                            }
                            .padding(.bottom, 4)
                        } else {
                            // Non-editing info header
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.purpleSurface)
                                        .frame(width: 48, height: 48)

                                    Image(systemName: storeWorkout.activityType.iconName)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(Color.brandPurple)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(storeWorkout.activityType.rawValue)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.primaryText)

                                    if !storeWorkout.scheduledDays.isEmpty {
                                        Text(WeekdayPicker.displayString(for: storeWorkout.scheduledDays))
                                            .font(.caption)
                                            .foregroundStyle(Color.secondaryText)
                                    }
                                }

                                Spacer()

                                if storeWorkout.streakCount > 0 {
                                    HStack(spacing: 4) {
                                        Text("🔥")
                                            .font(.subheadline)
                                        Text("\(storeWorkout.streakCount)")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(Color.brandPurple)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.purpleSurface))
                                }
                            }
                            .padding(16)
                            .appCardBackground()
                        }

                        sectionHeader("Timers")

                        VStack(spacing: 10) {
                            if workout.segments.isEmpty {
                                EmptyStateCard(message: "No timers added yet")
                            } else {
                                ForEach(Array(workout.segments.enumerated()), id: \.element.id) { _, segment in
                                    EditableSegmentRow(
                                        segment: segment,
                                        isEditing: isEditing,
                                        isDragging: draggingSegment?.id == segment.id,
                                        onRequestDelete: {
                                            pendingDeleteSegment = segment
                                            showDeleteAlert = true
                                        },
                                        onTap: {
                                            if isEditing {
                                                editingSegment = segment
                                            }
                                        }
                                    )
                                    .onDrag {
                                        guard isEditing else { return NSItemProvider() }
                                        draggingSegment = segment
                                        return NSItemProvider(object: segment.id.uuidString as NSString)
                                    }
                                    .onDrop(
                                        of: [.text],
                                        delegate: SegmentDropDelegate(
                                            item: segment,
                                            segments: segmentsBinding,
                                            dragging: $draggingSegment
                                        )
                                    )
                                }
                            }
                        }

                        // Reorder hint when editing
                        if isEditing && workout.segments.count > 1 {
                            Text("Long-press and drag to reorder")
                                .font(.caption)
                                .foregroundStyle(Color.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        Button {
                            showAddTimerSheet = true
                        } label: {
                            Label("Add Timer", systemImage: "plus")
                                .appSecondaryButton()
                        }

                        if !isEditing {
                            VStack(spacing: 16) {
                                Text("Total: \(formatMinutes(workout.totalDurationSeconds))")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Button {
                                    sessionManager.startSession(workout: storeWorkout)
                                    dismiss()
                                    selectedTab = 0
                                } label: {
                                    Text("Start Workout")
                                        .appPrimaryButton()
                                }
                                .disabled(workout.segments.isEmpty)
                                .opacity(workout.segments.isEmpty ? 0.5 : 1)
                            }
                        } else {
                            VStack(spacing: 16) {
                                Text("Total: \(formatMinutes(draftWorkout.totalDurationSeconds))")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Button {
                                    // Save current edits first
                                    if let draft = editingWorkout {
                                        store.updateWorkout(draft)
                                    }
                                    isEditing = false
                                    editingWorkout = nil
                                    // Start the session with the saved workout
                                    let saved = store.workouts.first(where: { $0.id == workoutID }) ?? draftWorkout
                                    sessionManager.startSession(workout: saved)
                                    dismiss()
                                    selectedTab = 0
                                } label: {
                                    Text("Start Workout")
                                        .appPrimaryButton()
                                }
                                .disabled(draftWorkout.segments.isEmpty)
                                .opacity(draftWorkout.segments.isEmpty ? 0.5 : 1)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isEditing)
                }
                .background(Color.appBackground)
                .navigationTitle(isEditing ? "" : storeWorkout.name)
                .toolbar {
                    if isEditing {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isEditing = false; editingWorkout = nil }
                            }
                            .foregroundStyle(Color.brandPurple)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                if let draft = editingWorkout {
                                    store.updateWorkout(draft)
                                }
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isEditing = false; editingWorkout = nil }
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.brandPurple)
                        }
                    } else {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Edit") {
                                editingWorkout = storeWorkout
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isEditing = true }
                            }
                            .foregroundStyle(Color.brandPurple)
                        }
                    }
                }
                .toolbarBackground(Color.appBackground, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
                .sheet(isPresented: $showAddTimerSheet) {
                    AddTimerSheet(
                        activityType: draftWorkout.activityType,
                        onAdd: { segment in
                            if isEditing {
                                editingWorkout?.segments.append(segment)
                            } else {
                                store.addSegment(to: workoutID, segment: segment)
                            }
                        }
                    )
                    .presentationDetents([.large])
                }
                .sheet(item: $editingSegment) { seg in
                    EditTimerSheet(
                        segment: seg,
                        activityType: draftWorkout.activityType,
                        onSave: { updated in
                            if let idx = editingWorkout?.segments.firstIndex(where: { $0.id == seg.id }) {
                                editingWorkout?.segments[idx] = updated
                            }
                        }
                    )
                    .presentationDetents([.large])
                }
                .alert("Remove Exercise?", isPresented: $showDeleteAlert, presenting: pendingDeleteSegment) { segment in
                    Button("Remove", role: .destructive) {
                        editingWorkout?.segments.removeAll { $0.id == segment.id }
                        pendingDeleteSegment = nil
                    }
                    Button("Cancel", role: .cancel) {
                        pendingDeleteSegment = nil
                    }
                } message: { _ in
                    Text("This exercise will be removed from your workout.")
                }
            } else {
                Text("Workout not found")
                    .foregroundStyle(Color.secondaryText)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.secondaryText)
            .textCase(.uppercase)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
    }
}

// MARK: - SegmentDropDelegate

private struct SegmentDropDelegate: DropDelegate {
    let item: TimerSegment
    @Binding var segments: [TimerSegment]
    @Binding var dragging: TimerSegment?
    private let animation = Animation.spring(response: 0.4, dampingFraction: 0.7)

    func dropEntered(info: DropInfo) {
        guard let dragging = dragging, dragging.id != item.id else { return }
        guard let fromIndex = segments.firstIndex(where: { $0.id == dragging.id }),
              let toIndex = segments.firstIndex(where: { $0.id == item.id }) else { return }
        withAnimation(animation) {
            segments.move(fromOffsets: IndexSet(integer: fromIndex),
                          toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }

    func dropExited(info: DropInfo) {
        dragging = nil
    }
}

// MARK: - EditableSegmentRow

struct EditableSegmentRow: View {
    var segment: TimerSegment
    var isEditing: Bool
    var isDragging: Bool
    var onRequestDelete: () -> Void
    var onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            TimerSegmentRow(segment: segment)
                .onTapGesture { onTap() }

            if isEditing {
                Button(action: onRequestDelete) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 22, height: 22)
                        Image(systemName: "minus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.white)
                    }
                }
                .buttonStyle(.plain)
                .offset(x: -6, y: -6)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect((isDragging || isPressed) ? 1.03 : 1.0)
        .shadow(color: Color.black.opacity((isDragging || isPressed) ? 0.18 : 0.08),
                radius: (isDragging || isPressed) ? 14 : 8,
                x: 0,
                y: (isDragging || isPressed) ? 10 : 6)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isEditing)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.15, pressing: { pressing in
            if isEditing {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - TimerSegmentRow

struct TimerSegmentRow: View {
    var segment: TimerSegment

    var body: some View {
        HStack(spacing: 12) {
            // Type indicator
            Circle()
                .fill(Color.brandPurple)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(segment.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(1)
                    Spacer()
                    Text(formatDuration(segment.durationSeconds))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.brandPurple)
                }

                HStack(spacing: 6) {
                    Text(segment.type.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.brandPurple)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color.purpleSurface))

                    if segment.repeatCount > 1 {
                        Text("×\(segment.repeatCount)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.secondaryText)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(Color.purpleSurface.opacity(0.6)))
                    }

                    Spacer()

                    // Rest between sets info
                    if segment.restBetweenRepeats > 0 && segment.repeatCount > 1 {
                        Text("\(formatDuration(segment.restBetweenRepeats)) rest")
                            .font(.caption2)
                            .foregroundStyle(Color.secondaryText)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .appCardBackground()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shared timer form fields

private struct TimerFormFields: View {
    var activityType: ActivityType
    @Binding var name: String
    @Binding var segmentType: TimerSegmentType
    @Binding var minutes: Int
    @Binding var seconds: Int
    @Binding var repeatCount: Int
    @Binding var restEnabled: Bool
    @Binding var restMinutes: Int
    @Binding var restSeconds: Int
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Timer Name")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)
                TextField("e.g. Bench Press", text: $name)
                    .focused($isNameFocused)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isNameFocused ? Color.brandPurple.opacity(0.4) : Color.brandPurple.opacity(0.2), lineWidth: 1)
                    )
            }

            if activityType.allowedSegmentTypes.count > 1 {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Segment Type")
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)
                    Picker("Segment Type", selection: $segmentType) {
                        ForEach(activityType.allowedSegmentTypes) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.brandPurple)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Duration")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)
                HStack {
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<60, id: \.self) { Text("\($0)m").tag($0) }
                    }
                    Picker("Seconds", selection: $seconds) {
                        ForEach(0..<60, id: \.self) { Text("\($0)s").tag($0) }
                    }
                }
                .pickerStyle(.wheel)
                .tint(Color.brandPurple)
                .frame(height: 120)
            }

            VStack(alignment: .leading, spacing: 8) {
                Stepper("Repeat: \(repeatCount) times", value: $repeatCount, in: 1...20)
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)
                    .tint(Color.brandPurple)
                Text("This segment will repeat \(repeatCount) times in sequence")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
            }

            VStack(alignment: .leading, spacing: 10) {
                Toggle("Rest between sets", isOn: $restEnabled)
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)
                    .tint(Color.brandPurple)

                if restEnabled {
                    HStack {
                        Picker("Minutes", selection: $restMinutes) {
                            ForEach(0..<60, id: \.self) { Text("\($0)m").tag($0) }
                        }
                        Picker("Seconds", selection: $restSeconds) {
                            ForEach(0..<60, id: \.self) { Text("\($0)s").tag($0) }
                        }
                    }
                    .pickerStyle(.wheel)
                    .tint(Color.brandPurple)
                    .frame(height: 120)
                }

                Text("A rest period will be added automatically between each set")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
            }
            .opacity(repeatCount == 1 ? 0.4 : 1.0)
            .disabled(repeatCount == 1)
            .onChange(of: repeatCount) { _, newValue in
                if newValue <= 1 { restEnabled = false }
            }

            if repeatCount == 1 {
                Text("Increase sets to enable rest between them")
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)
                    .opacity(0.6)
            }
        }
    }
}

// MARK: - AddTimerSheet

struct AddTimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    var activityType: ActivityType
    var onAdd: (TimerSegment) -> Void

    @State private var name = ""
    @State private var segmentType: TimerSegmentType = .run
    @State private var minutes = 0
    @State private var seconds = 0
    @State private var repeatCount = 1
    @State private var restEnabled = false
    @State private var restMinutes = 0
    @State private var restSeconds = 30

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                TimerFormFields(
                    activityType: activityType,
                    name: $name,
                    segmentType: $segmentType,
                    minutes: $minutes,
                    seconds: $seconds,
                    repeatCount: $repeatCount,
                    restEnabled: $restEnabled,
                    restMinutes: $restMinutes,
                    restSeconds: $restSeconds
                )

                Button {
                    let duration = (minutes * 60) + seconds
                    let rest = restEnabled && repeatCount > 1 ? (restMinutes * 60) + restSeconds : 0
                    let segment = TimerSegment(
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        type: segmentType,
                        durationSeconds: duration,
                        repeatCount: repeatCount,
                        restBetweenRepeats: rest
                    )
                    onAdd(segment)
                    dismiss()
                } label: {
                    Text("Add Timer")
                        .appPrimaryButton()
                }
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.5 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.sheetBackground)
        .onAppear {
            segmentType = activityType.allowedSegmentTypes.first ?? .exercise
        }
    }

    private var isDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (minutes == 0 && seconds == 0)
    }

    private var header: some View {
        ZStack {
            Text("Add Timer")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.primaryText)
                .frame(maxWidth: .infinity)
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(Color.brandPurple)
                        .padding(10)
                        .background(Color.cardBackground)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close")
            }
        }
        .padding(.bottom, 6)
    }
}

// MARK: - EditTimerSheet

struct EditTimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    var segment: TimerSegment
    var activityType: ActivityType
    var onSave: (TimerSegment) -> Void

    @State private var name: String
    @State private var segmentType: TimerSegmentType
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var repeatCount: Int
    @State private var restEnabled: Bool
    @State private var restMinutes: Int
    @State private var restSeconds: Int

    init(segment: TimerSegment, activityType: ActivityType, onSave: @escaping (TimerSegment) -> Void) {
        self.segment = segment
        self.activityType = activityType
        self.onSave = onSave
        _name = State(initialValue: segment.name)
        _segmentType = State(initialValue: segment.type)
        _minutes = State(initialValue: segment.durationSeconds / 60)
        _seconds = State(initialValue: segment.durationSeconds % 60)
        _repeatCount = State(initialValue: segment.repeatCount)
        _restEnabled = State(initialValue: segment.restBetweenRepeats > 0)
        _restMinutes = State(initialValue: segment.restBetweenRepeats / 60)
        _restSeconds = State(initialValue: segment.restBetweenRepeats % 60)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                TimerFormFields(
                    activityType: activityType,
                    name: $name,
                    segmentType: $segmentType,
                    minutes: $minutes,
                    seconds: $seconds,
                    repeatCount: $repeatCount,
                    restEnabled: $restEnabled,
                    restMinutes: $restMinutes,
                    restSeconds: $restSeconds
                )

                Button {
                    let duration = (minutes * 60) + seconds
                    let rest = restEnabled && repeatCount > 1 ? (restMinutes * 60) + restSeconds : 0
                    var updated = segment
                    updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    updated.type = segmentType
                    updated.durationSeconds = duration
                    updated.repeatCount = repeatCount
                    updated.restBetweenRepeats = rest
                    onSave(updated)
                    dismiss()
                } label: {
                    Text("Save")
                        .appPrimaryButton()
                }
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.5 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.sheetBackground)
    }

    private var isDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (minutes == 0 && seconds == 0)
    }

    private var header: some View {
        ZStack {
            Text("Edit Timer")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.primaryText)
                .frame(maxWidth: .infinity)
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(Color.brandPurple)
                        .padding(10)
                        .background(Color.cardBackground)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close")
            }
        }
        .padding(.bottom, 6)
    }
}
