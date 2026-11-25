cask "markread" do
  arch arm: "arm64", intel: "x86_64"

  version "0.1.4"
  sha256 arm:   "ad1d97bf415dd55dfaaa65245256bee98da583568cef28ee2dec3eaa1e35e321",
         intel: "9373084d4e226ad8252abf58e979b4ab8b721b013594ad2034cfb41a9474f3f1"

  url "https://github.com/tluo-github/markread/releases/download/v#{version}/MarkRead-#{version}-#{arch}.zip"
  name "MarkRead"
  desc "Minimal, free and offline Markdown reader with Highlight.js syntax highlighting and Quick Look"
  homepage "https://github.com/tluo-github/markread"

  depends_on macos: ">= :ventura"

  app "MarkRead.app"

  uninstall quit: "com.markread.app"

  zap trash: [
    "~/Library/Application Support/MarkRead",
    "~/Library/Caches/com.markread.app",
    "~/Library/Preferences/com.markread.app.plist",
  ]
end
