import Foundation

enum AssessmentTask: String, CaseIterable, Codable {
    case hold = "Hold Steady"
    case control = "Pressure Control"
    case taps = "Rhythm Taps"

    var durationSeconds: Double { 20 }
}

struct PressureSample: Codable {
    let timestamp: Date
    let pressure: Double
    let isTouching: Bool
}

struct TaskFeatures: Codable {
    let meanPressure: Double
    let pressureStdDev: Double
    let pressureCV: Double
    let oscillationScore: Double
    let rhythmVariance: Double
}

struct SessionResult: Codable, Identifiable {
    let id: UUID
    let date: Date
    let score: Double
    let confidence: Double
    let features: TaskFeatures
}

struct BaselineStats: Codable {
    let scoreMean: Double
    let scoreStdDev: Double
    let featuresMean: TaskFeatures
}
