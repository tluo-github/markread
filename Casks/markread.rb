cask "markread" do
  arch arm: "arm64", intel: "x86_64"

  version "0.1.1"
  sha256 arm:   "220dde183be28d617a290710955442393d40e703e684b168eb607f1c9a29a42b",
         intel: "88aa2863f04a1e582cd46e27eb2e2ed03c1d13d2aa3e9a17e2a90b54743d7003"

  url "https://github.com/tluo-github/markread/releases/download/v#{version}/MarkRead-#{version}-#{arch}.zip"
  name "MarkRead"
  desc "Minimal, free and offline Markdown reader with Highlight.js syntax highlighting and Quick Look"
  homepage "https://github.com/tluo-github/markread"

  depends_on macos: :sonoma

  app "MarkRead.app"

  uninstall quit: "com.markread.app"

  zap trash: [
    "~/Library/Application Support/MarkRead",
    "~/Library/Caches/com.markread.app",
    "~/Library/Preferences/com.markread.app.plist",
  ]
end
