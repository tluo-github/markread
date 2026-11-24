cask "markread" do
  arch arm: "arm64", intel: "x86_64"

  version "0.1.3"
  sha256 arm:   "132228cad1ef6a381285b7693f743c9382d510142216ff5cd0f22def86e22397",
         intel: "16a5111ca04308375b2c320d8b1b3b7be79156e4a82a2bcc987a4c4663ea2c2b"

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
