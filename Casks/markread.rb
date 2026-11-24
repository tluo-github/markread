cask "markread" do
  arch arm: "arm64", intel: "x86_64"

  version "0.1.0"
  sha256 arm:   "89654cc3b6f00ea165c8dd9677ef22ccb94878bb80373fb6593c955cfd4ef482",
         intel: "bf8d78ac5852f1cec085c813a58a03654e8fe3c9b306de03ca44180c355e6e7c"

  url "https://github.com/tluo-github/markread/releases/download/v#{version}/MarkRead-#{version}-#{arch}.zip"
  name "MarkRead"
  desc "Minimal, free and offline Markdown reader with Highlight.js syntax highlighting and Quick Look"
  homepage "https://github.com/tluo-github/markread"

  depends_on macos: ">= :sonoma"

  app "MarkRead.app"

  uninstall quit: "com.markread.app"

  zap trash: [
    "~/Library/Application Support/MarkRead",
    "~/Library/Caches/com.markread.app",
    "~/Library/Preferences/com.markread.app.plist",
  ]
end
