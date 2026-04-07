import SwiftUI

struct WorkoutRunnerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionManager: WorkoutSessionManager
    @EnvironmentObject private var store: WorkoutStore
    @EnvironmentObject private var xpManager: XPManager
    @EnvironmentObject private var historyManager: WorkoutHistoryManager
    @Binding var selectedTab: Int
    @StateObject private var viewModel: WorkoutRunnerViewModel
    var workoutImage: String? = nil
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Used to push to WorkoutDetailView when Edit is tapped
    @State private var navigateToEdit = false
    @State private var showStopConfirmation = false
    @State private var showWorkoutCompleteSheet = false
    @State private var isStopButtonPressed = false
    @State private var showConfetti = false
    @State private var xpEarnedThisSession: Int = 0
    @State private var showRankUpOverlay = false
    @State private var rankUpRank: Rank? = nil

    init(workout: Workout, selectedTab: Binding<Int>, workoutImage: String? = nil) {
        _viewModel = StateObject(wrappedValue: WorkoutRunnerViewModel(workout: workout))
        _selectedTab = selectedTab
        self.workoutImage = workoutImage
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack(alignment: .top) {
                    // ...existing background code...
                    if let workoutImage {
                        VStack(spacing: 0) {
                            Image(workoutImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: proxy.size.width, height: proxy.size.height * 0.55)
                                .clipped()
                                .overlay(
                                    LinearGradient(
                                        stops: [
                                            .init(color: .clear, location: 0.0),
                                            .init(color: .clear, location: 0.4),
                                            .init(color: Color.appBackground, location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            Color.appBackground
                        }
                        .ignoresSafeArea()
                    } else {
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.28, green: 0.16, blue: 0.72), location: 0.0),
                                .init(color: Color(red: 0.44, green: 0.29, blue: 0.95).opacity(0.6), location: 0.25),
                                .init(color: Color(red: 0.62, green: 0.50, blue: 0.98).opacity(0.15), location: 0.55),
                                .init(color: Color.white.opacity(0.0), location: 0.78),
                                .init(color: Color.white, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }

                    // ── Content ─────────────────────────────────────────
                    VStack(spacing: 0) {
                        headerOverlay
                            .padding(.top, 16)

                        Spacer().frame(height: 100)

                        // Segment name + badge — high up on screen
                        VStack(spacing: 6) {
                            Text(viewModel.currentDisplayName)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)

                            Text(viewModel.displaySegmentType)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    viewModel.displaySegmentType == "Rest"
                                        ? Color.secondaryText.opacity(0.15)
                                        : Color.purpleSurface
                                )
                                .foregroundStyle(
                                    viewModel.displaySegmentType == "Rest"
                                        ? Color.secondaryText
                                        : Color.brandPurple
                                )
                                .clipShape(Capsule())

                            if !viewModel.isRestPhase && viewModel.currentSegment.repeatCount > 1 {
                                Text("Set \(viewModel.currentRepeat) of \(viewModel.currentSegment.repeatCount)")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.white.opacity(0.8))
                            }
                        }

                        Spacer().frame(height: 12)

                        // Timer digits — large, prominent, high on screen
                        Text(formatTime(viewModel.timeRemainingInSegment))
                            .font(.system(size: 80, weight: .bold))
                            .foregroundStyle(.white)
                            .monospacedDigit()

                        Spacer().frame(height: 48)

                        // Next / Total — furtherbelow timer
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Next: \(viewModel.nextSegmentName)")
                            Text("Total remaining: \(formatMinutes(viewModel.totalRemainingSeconds))")
                        }
                        .font(.body)
                        .foregroundStyle(Color.brandPurpleLight)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                        Spacer()

                        // Buttons + Stop — plain VStack, always visible
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.isRunning ? viewModel.pause() : viewModel.start()
                                    }
                                } label: {
                                    Text(viewModel.isRunning ? "Pause" : "Resume")
                                        .appPrimaryButton()
                                }

                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) { viewModel.skip() }
                                } label: {
                                    Text("Skip")
                                        .appSecondaryButton()
                                }
                            }

                            Button {
                                selectedTab = 0
                                dismiss()
                            } label: {
                                Text("Cancel")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.white.opacity(0.18))
                                    )
                            }

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isStopButtonPressed = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        isStopButtonPressed = false
                                    }
                                    showStopConfirmation = true
                                }
                            } label: {
                                Text("Stop & Reset")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.brandPurpleLight)
                            }
                            .scaleEffect(isStopButtonPressed ? 0.93 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isStopButtonPressed)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }

                    // ── Workout Complete Overlay ──────────────────────
                    if showWorkoutCompleteSheet {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .transition(.opacity)

                        WorkoutCompletionSheet(xpEarned: xpEarnedThisSession) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.restartWorkout()
                                showWorkoutCompleteSheet = false
                            }
                        } onFinish: {
                            let streakIncremented = store.completeWorkout(id: viewModel.workout.id)
                            historyManager.recordCompletion(workout: viewModel.workout)
                            // Award XP
                            let xp = xpManager.awardXP(for: viewModel.workout)
                            _ = xp
                            let didRankUp = xpManager.didRankUp
                            let rankedUpTo = xpManager.newRank
                            xpManager.clearRankUp()

                            if streakIncremented || didRankUp {
                                showConfetti = true
                            }
                            if didRankUp, let rank = rankedUpTo {
                                rankUpRank = rank
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    showRankUpOverlay = true
                                }
                            }
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                showWorkoutCompleteSheet = false
                            }
                            let celebrationDelay = (streakIncremented || didRankUp) ? 3.0 : 0.0
                            DispatchQueue.main.asyncAfter(deadline: .now() + celebrationDelay) {
                                sessionManager.clearSession()
                                selectedTab = 1
                                showConfetti = false
                                showRankUpOverlay = false
                                rankUpRank = nil
                            }
                        }
                        .padding(.horizontal, 24)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                        .frame(maxHeight: .infinity, alignment: .center)
                    }

                    // ── Confetti Overlay ──────────────────────
                    if showConfetti {
                        ConfettiView()
                            .transition(.opacity)
                    }

                    // ── Rank Up Overlay ──────────────────────
                    if showRankUpOverlay, let rank = rankUpRank {
                        RankUpOverlay(rank: rank)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToEdit) {
                WorkoutDetailView(workoutID: viewModel.workout.id, selectedTab: $selectedTab)
            }
        }
        .sheet(isPresented: $showStopConfirmation) {
            StopConfirmationSheet {
                viewModel.stop()
                sessionManager.clearSession()
            } onCancel: {
                showStopConfirmation = false
            }
            .presentationDetents([.height(260)])
            .presentationCornerRadiusIfAvailable(28)
        }
        .onReceive(timer) { _ in
            viewModel.tick()
        }
        .onAppear {
            FeedbackManager.configureAudioSession()
        }
        .onChange(of: viewModel.isWorkoutComplete) { complete in
            if complete {
                xpEarnedThisSession = XPManager.xpForWorkout(viewModel.workout)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showWorkoutCompleteSheet = true
                }
            }
        }
        .alert("Rest Complete", isPresented: $viewModel.showRestCompleteAlert) {
            Button("Rest 30s More") {
                viewModel.addRestTime()
            }
            Button("Next Exercise") {
                viewModel.dismissRestAlertAndContinue()
            }
        } message: {
            Text("Ready to continue?")
        }
    }

    private var headerOverlay: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    selectedTab = 1
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(Color.brandPurple)
                        .frame(width: 40, height: 40)
                        .background(Color.cardBackground)
                        .clipShape(Circle())
                }
                Spacer()
                Button {
                    navigateToEdit = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandPurple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.cardBackground)
                        .clipShape(Capsule())
                }
            }
            Text(viewModel.workout.name)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }
}

extension View {
    func presentationCornerRadiusIfAvailable(_ radius: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            return self.presentationCornerRadius(radius)
        } else {
            return self
        }
    }
}

// MARK: - Stop Confirmation Sheet

struct StopConfirmationSheet: View {
    var onStop: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.secondaryText.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            VStack(spacing: 8) {
                Text("Stop Workout?")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.primaryText)

                Text("Are you sure you want to stop?\nYour current progress will be lost.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                Button {
                    onStop()
                } label: {
                    Text("Stop Workout")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [Color.brandPurple, Color.brandPurpleDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundStyle(Color.brandPurple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.purpleSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .background(Color.sheetBackground)
    }
}


