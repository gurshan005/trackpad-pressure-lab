import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: AssessmentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tremor Check MVP")
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Text(stageTitle(vm.stage))
                .font(.headline)

            if let task = vm.currentTask {
                Text("Task: \(task.rawValue)")
                    .font(.subheadline)
            }

            HStack {
                Text("Live pressure")
                Spacer()
                Text(String(format: "%.3f", vm.livePressure))
                    .monospacedDigit()
            }

            Text(vm.contactText)
                .foregroundStyle(.secondary)

            if let score = vm.latestScore, let confidence = vm.latestConfidence {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest Index: \(Int(score))/100")
                        .font(.title3.weight(.semibold))
                    Text("Confidence: \(Int(confidence * 100))%")
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Button("Start session") {
                    vm.startAssessment()
                }
                .buttonStyle(.borderedProminent)

                Button("Stop") {
                    vm.stopAssessment()
                }
                .buttonStyle(.bordered)
            }

            Divider()

            Text("Recent Sessions")
                .font(.headline)

            List(Array(vm.sessions.suffix(10).reversed())) { session in
                HStack {
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    Spacer()
                    Text("Score \(Int(session.score))")
                        .monospacedDigit()
                }
            }
            .frame(minHeight: 180)

            Text("Not a diagnosis tool. Experimental pressure features only.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }

    private func stageTitle(_ stage: AssessmentViewModel.Stage) -> String {
        switch stage {
        case .idle:
            return "Idle"
        case .waitingForContact:
            return "Waiting for contact"
        case .countdown(let seconds):
            return "Starting in \(seconds)s"
        case .recording(_, let seconds, let paused):
            return paused ? "Paused (\(seconds)s left)" : "Recording (\(seconds)s left)"
        case .complete:
            return "Assessment complete"
        }
    }
}
