import Foundation

public struct AppUpdateInfo: Sendable {
    public let latestVersion: String
    public let hasUpdate: Bool
    public let releaseNotes: String
    public let downloadURL: String?

    public init(latestVersion: String, hasUpdate: Bool, releaseNotes: String, downloadURL: String?) {
        self.latestVersion = latestVersion
        self.hasUpdate = hasUpdate
        self.releaseNotes = releaseNotes
        self.downloadURL = downloadURL
    }
}

public final class UpdateChecker: Sendable {
    public static let shared = UpdateChecker()

    private init() {}

    public func checkForUpdates() async -> AppUpdateInfo? {
        guard let url = URL(string: "https://api.github.com/repos/meowvia/MacAegis/releases/latest") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        request.setValue("MacAegis/\(AppConfig.appVersion)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                return nil
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else {
                return nil
            }

            let latestVer = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let currentVer = AppConfig.appVersion.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let body = json["body"] as? String ?? ""
            let htmlURL = json["html_url"] as? String

            let hasUpdate = latestVer.compare(currentVer, options: .numeric) == .orderedDescending

            return AppUpdateInfo(
                latestVersion: tagName,
                hasUpdate: hasUpdate,
                releaseNotes: body,
                downloadURL: htmlURL
            )
        } catch {
            return nil
        }
    }
}
