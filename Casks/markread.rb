cask "markread" do
  arch arm: "arm64", intel: "x86_64"

  version "0.1.2"
  sha256 arm:   "3f8d68aedf884341c7918df018ed9e024948534449ad3b60c02360f705dcf782",
         intel: "8451d7cc3383963e60141d1c9dce991dc61575f9f3d3953efe1d862a80d9577f"

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
