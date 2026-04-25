cask "macpulse" do
  version "1.0.0"
  sha256 "" # Update with: shasum -a 256 MacPulse-1.0.0.dmg

  url "https://github.com/yourname/MacPulse/releases/download/v#{version}/MacPulse-#{version}.dmg"
  name "MacPulse"
  desc "Lightweight macOS menu bar system monitor"
  homepage "https://github.com/yourname/MacPulse"

  depends_on macos: ">= :sonoma"

  app "MacPulse.app"

  zap trash: [
    "~/Library/Application Support/MacPulse",
    "~/Library/Preferences/com.macpulse.app.plist",
    "~/Library/Caches/com.macpulse.app",
  ]
end
