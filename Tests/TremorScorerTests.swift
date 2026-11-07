import Foundation
import XCTest
@testable import TremorCheckMVP

final class TremorScorerTests: XCTestCase {
    private func samples(_ pressures: [Double]) -> [PressureSample] {
        pressures.enumerated().map { index, pressure in
            PressureSample(timestamp: Date(timeIntervalSince1970: Double(index)),
                           pressure: pressure, isTouching: pressure > 0)
        }
    }

    func testConstantPressureHasNoOscillation() {
        let features = TremorScorer.computeFeatures(samples: samples([0.5, 0.5, 0.5]))
        XCTAssertEqual(features.meanPressure, 0.5)
        XCTAssertEqual(features.pressureStdDev, 0)
        XCTAssertEqual(features.oscillationScore, 0)
    }

    func testTapIntervalsAndPressureChanges() {
        // Rising edges at 0, 2 and 6 s give intervals of 2 and 4 s.
        let features = TremorScorer.computeFeatures(samples: samples([1, 0, 1, 0, 0, 0, 1]))
        XCTAssertEqual(features.rhythmVariance, 1, accuracy: 0.0001)
        XCTAssertEqual(features.oscillationScore, 4.0 / 6.0, accuracy: 0.0001)
    }

    func testBaselineUsesOnlyTheSevenMostRecentSessions() {
        let history = (0..<9).map { index -> SessionResult in
            let features = TremorScorer.computeFeatures(samples: samples([Double(index)]))
            return SessionResult(id: UUID(), date: Date(timeIntervalSince1970: Double(index)),
                                 score: Double(index), confidence: 0.5, features: features)
        }
        XCTAssertNil(TremorScorer.baseline(from: Array(history.prefix(2))))
        XCTAssertNotNil(TremorScorer.baseline(from: Array(history.prefix(3))))
        let baseline = TremorScorer.baseline(from: history)
        XCTAssertEqual(baseline?.scoreMean, 5)
        XCTAssertEqual(baseline?.featuresMean.meanPressure, 5)
    }
}
