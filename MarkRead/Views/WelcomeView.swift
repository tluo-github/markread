import SwiftUI

struct WelcomeView: View {
    let l10n: L10n
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

                Text(l10n.welcomeSubtitle)
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button(action: onOpenFile) {
                    Label(l10n.welcomeOpenButton, systemImage: "folder")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: onOpenSample) {
                    Text(l10n.welcomeSampleButton)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.top, 4)

            Text(l10n.welcomeHint)
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .padding(.top, 6)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
