import Foundation

@MainActor
@Observable
public final class UpdateChecker {
    public var latestVersion: String?
    public var downloadURL: URL?
    public var isChecking = false
    public var hasUpdate: Bool {
        guard let latest = latestVersion else { return false }
        return latest.compare(currentVersion, options: .numeric) == .orderedDescending
    }

    public let currentVersion: String

    private let owner: String
    private let repo: String

    public init(owner: String = "macpulse", repo: String = "MacPulse", currentVersion: String = "1.0.0") {
        self.owner = owner
        self.repo = repo
        self.currentVersion = currentVersion
    }

    /// Check for updates via GitHub API (skipped in App Store builds).
    public func check() async {
        guard !ProcessHelper.isSandboxed else { return }
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/releases/latest"
        guard let url = URL(string: urlString) else { return }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let tagName = json?["tag_name"] as? String else { return }

            let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
            latestVersion = version

            if let assets = json?["assets"] as? [[String: Any]],
               let dmgAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true }),
               let urlStr = dmgAsset["browser_download_url"] as? String {
                downloadURL = URL(string: urlStr)
            } else if let htmlURL = json?["html_url"] as? String {
                downloadURL = URL(string: htmlURL)
            }
        } catch {
            // Silently fail — update checks are best-effort
        }
    }
}
