import Foundation

enum TremorScorer {
    static func computeFeatures(samples: [PressureSample]) -> TaskFeatures {
        let pressureValues = samples.map(\.pressure)
        let mean = pressureValues.mean
        let stdDev = pressureValues.stdDev
        let cv = mean > 0 ? stdDev / mean : 1

        // Simple tremor proxy: derivative energy between adjacent pressure samples.
        let deltas = zip(pressureValues.dropFirst(), pressureValues).map { current, previous in
            current - previous
        }
        let oscillation = deltas.map { $0 * $0 }.mean

        let tapTimes = detectTapTimestamps(samples: samples)
        let intervals = zip(tapTimes.dropFirst(), tapTimes).map { $0.timeIntervalSince($1) }
        let rhythmVar = intervals.stdDev

        return TaskFeatures(
            meanPressure: mean,
            pressureStdDev: stdDev,
            pressureCV: cv,
            oscillationScore: oscillation,
            rhythmVariance: rhythmVar
        )
    }

    static func score(features: TaskFeatures, baseline: BaselineStats?) -> (score: Double, confidence: Double) {
        if let baseline {
            let zScore = abs(features.meanPressure - baseline.featuresMean.meanPressure) / max(0.001, baseline.featuresMean.meanPressure)
            let zCV = abs(features.pressureCV - baseline.featuresMean.pressureCV) / max(0.001, baseline.featuresMean.pressureCV)
            let zOsc = abs(features.oscillationScore - baseline.featuresMean.oscillationScore) / max(0.001, baseline.featuresMean.oscillationScore)
            let zRhythm = abs(features.rhythmVariance - baseline.featuresMean.rhythmVariance) / max(0.001, baseline.featuresMean.rhythmVariance)
            let weighted = (0.20 * zScore) + (0.25 * zCV) + (0.35 * zOsc) + (0.20 * zRhythm)
            let index = max(0, min(100, 100 - (weighted * 25)))
            let confidence = min(1, max(0.3, 1.0 - (baseline.scoreStdDev / 20.0)))
            return (index, confidence)
        } else {
            // Until we have baseline, keep a neutral score band.
            let raw = 100 - min(100, (features.pressureCV * 120) + (features.oscillationScore * 90) + (features.rhythmVariance * 40))
            return (max(0, raw), 0.5)
        }
    }

    static func baseline(from sessions: [SessionResult]) -> BaselineStats? {
        guard sessions.count >= 3 else { return nil }
        let recent = Array(sessions.suffix(7))
        let meanScore = recent.map(\.score).mean
        let stdScore = recent.map(\.score).stdDev
        let means = recent.map(\.features)
        let aggregate = TaskFeatures(
            meanPressure: means.map(\.meanPressure).mean,
            pressureStdDev: means.map(\.pressureStdDev).mean,
            pressureCV: means.map(\.pressureCV).mean,
            oscillationScore: means.map(\.oscillationScore).mean,
            rhythmVariance: means.map(\.rhythmVariance).mean
        )
        return BaselineStats(scoreMean: meanScore, scoreStdDev: stdScore, featuresMean: aggregate)
    }

    private static func detectTapTimestamps(samples: [PressureSample]) -> [Date] {
        guard !samples.isEmpty else { return [] }
        var taps: [Date] = []
        var wasDown = false
        let threshold = max(0.04, samples.map(\.pressure).mean * 0.4)
        for s in samples {
            let isDown = s.pressure > threshold
            if isDown && !wasDown { taps.append(s.timestamp) }
            wasDown = isDown
        }
        return taps
    }
}

private extension Array where Element == Double {
    var mean: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }

    var stdDev: Double {
        guard count > 1 else { return 0 }
        let m = mean
        let variance = reduce(0) { $0 + (($1 - m) * ($1 - m)) } / Double(count)
        return sqrt(variance)
    }
}
