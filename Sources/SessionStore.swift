import Foundation

final class SessionStore {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("TremorCheckMVP", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        self.fileURL = dir.appendingPathComponent("sessions.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func load() -> [SessionResult] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? decoder.decode([SessionResult].self, from: data)) ?? []
    }

    func save(_ sessions: [SessionResult]) {
        guard let data = try? encoder.encode(sessions) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
