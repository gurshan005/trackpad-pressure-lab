import Foundation
import Combine

@MainActor
final class AssessmentViewModel: ObservableObject {
    enum Stage: Equatable {
        case idle
        case waitingForContact
        case countdown(secondsLeft: Int)
        case recording(task: AssessmentTask, secondsLeft: Int, pausedForContact: Bool)
        case complete
    }

    @Published var stage: Stage = .idle
    @Published var currentTask: AssessmentTask?
    @Published var livePressure: Double = 0
    @Published var contactText: String = "Place a finger to begin"
    @Published var latestScore: Double?
    @Published var latestConfidence: Double?
    @Published var sessions: [SessionResult] = []

    private let tasks = AssessmentTask.allCases
    private let monitor = PressureMonitor()
    private let store = SessionStore()

    private var taskIndex = 0
    private var taskSamples: [PressureSample] = []
    private var allSamples: [PressureSample] = []
    private var isTouching = false
    private var contactStableSince: Date?
    private var secondsRemaining = 0
    private var timerTask: Task<Void, Never>?

    init() {
        sessions = store.load().sorted { $0.date < $1.date }
    }

    func startAssessment() {
        resetRunState()
        taskIndex = 0
        stage = .waitingForContact
        contactText = "Touch and hold for 0.5s"
        monitor.start { [weak self] state in
            Task { @MainActor in
                self?.handleLiveState(state)
            }
        }
        startTimer()
    }

    func stopAssessment() {
        timerTask?.cancel()
        timerTask = nil
        monitor.stop()
        stage = .idle
        currentTask = nil
        contactText = "Assessment stopped"
    }

    private func startTimer() {
        timerTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
                self.tick()
            }
        }
    }

    private func handleLiveState(_ state: LiveTouchState) {
        livePressure = state.sample.pressure
        isTouching = state.sample.isTouching
        if isTouching {
            contactStableSince = contactStableSince ?? state.sample.timestamp
        } else {
            contactStableSince = nil
        }

        if case .recording(_, _, let pausedForContact) = stage, !pausedForContact, isTouching {
            taskSamples.append(state.sample)
            allSamples.append(state.sample)
        }
    }

    private func tick() {
        switch stage {
        case .idle, .complete:
            return
        case .waitingForContact:
            if hasStableContact(minSeconds: 0.5) {
                stage = .countdown(secondsLeft: 3)
                secondsRemaining = 3
                contactText = "Starting..."
            } else {
                contactText = "Touch and hold for 0.5s"
            }
        case .countdown:
            secondsRemaining -= 1
            if secondsRemaining <= 0 {
                startTask(index: taskIndex)
            } else {
                stage = .countdown(secondsLeft: secondsRemaining)
            }
        case .recording(let task, _, _):
            if !isTouching {
                stage = .recording(task: task, secondsLeft: secondsRemaining, pausedForContact: true)
                contactText = "Paused: place finger back"
                return
            }
            if hasStableContact(minSeconds: 0.5) {
                stage = .recording(task: task, secondsLeft: secondsRemaining, pausedForContact: false)
                contactText = "Recording"
                secondsRemaining -= 1
                if secondsRemaining <= 0 {
                    finishTask()
                } else {
                    stage = .recording(task: task, secondsLeft: secondsRemaining, pausedForContact: false)
                }
            } else {
                stage = .recording(task: task, secondsLeft: secondsRemaining, pausedForContact: true)
                contactText = "Stabilizing touch..."
            }
        }
    }

    private func startTask(index: Int) {
        let task = tasks[index]
        currentTask = task
        taskSamples = []
        secondsRemaining = Int(task.durationSeconds)
        stage = .recording(task: task, secondsLeft: secondsRemaining, pausedForContact: false)
        contactText = instructions(for: task)
    }

    private func finishTask() {
        taskIndex += 1
        if taskIndex >= tasks.count {
            completeAssessment()
        } else {
            stage = .waitingForContact
            contactText = "Task done. Re-touch to continue"
        }
    }

    private func completeAssessment() {
        monitor.stop()
        timerTask?.cancel()
        timerTask = nil

        let features = TremorScorer.computeFeatures(samples: allSamples)
        let baseline = TremorScorer.baseline(from: sessions)
        let scored = TremorScorer.score(features: features, baseline: baseline)
        latestScore = scored.score
        latestConfidence = scored.confidence

        let result = SessionResult(
            id: UUID(),
            date: Date(),
            score: scored.score,
            confidence: scored.confidence,
            features: features
        )
        sessions.append(result)
        sessions.sort { $0.date < $1.date }
        store.save(sessions)
        stage = .complete
        currentTask = nil
        contactText = "Complete"
    }

    private func hasStableContact(minSeconds: Double) -> Bool {
        guard isTouching, let since = contactStableSince else { return false }
        return Date().timeIntervalSince(since) >= minSeconds
    }

    private func instructions(for task: AssessmentTask) -> String {
        switch task {
        case .hold:
            return "Hold a light steady pressure"
        case .control:
            return "Gently vary pressure, stay controlled"
        case .taps:
            return "Tap and release at a steady rhythm"
        }
    }

    private func resetRunState() {
        timerTask?.cancel()
        timerTask = nil
        monitor.stop()
        currentTask = nil
        latestScore = nil
        latestConfidence = nil
        taskSamples = []
        allSamples = []
        contactStableSince = nil
        secondsRemaining = 0
        isTouching = false
        livePressure = 0
    }
}
