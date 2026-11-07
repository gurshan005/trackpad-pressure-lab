import Foundation
import OpenMultitouchSupport

struct LiveTouchState {
    let sample: PressureSample
    let activeTouchCount: Int
}

final class PressureMonitor {
    private let manager = OMSManager.shared
    private var streamTask: Task<Void, Never>?
    private var callback: ((LiveTouchState) -> Void)?

    func start(onUpdate: @escaping (LiveTouchState) -> Void) {
        callback = onUpdate
        manager.startListening()
        streamTask = Task {
            for await touches in manager.touchDataStream {
                guard !Task.isCancelled else { return }
                let firstPressure = touches.first.map { Double($0.pressure) } ?? 0
                let state = LiveTouchState(
                    sample: PressureSample(
                        timestamp: Date(),
                        pressure: firstPressure,
                        isTouching: !touches.isEmpty
                    ),
                    activeTouchCount: touches.count
                )
                onUpdate(state)
            }
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        callback = nil
        manager.stopListening()
    }
}
