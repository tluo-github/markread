import SwiftUI

struct WelcomeView: View {
    let onOpenFile: () -> Void
    let onOpenSample: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "doc.richtext")
                .font(.system(size: 46, weight: .ultraLight))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("MarkRead")
                    .font(.system(size: 26, weight: .semibold, design: .default))
                    .tracking(-0.4)

                Text("Minimal, free & offline Markdown reader for macOS")
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button(action: onOpenFile) {
                    Label("Open Markdown File…", systemImage: "folder")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: onOpenSample) {
                    Text("Open Showcase")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.top, 4)

            Text("Or drag & drop any .md file onto this window  ·  ⌘O to open")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .padding(.top, 6)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
