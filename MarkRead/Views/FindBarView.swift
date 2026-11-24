import SwiftUI

struct FindBarView: View {
    @Binding var query: String
    let currentMatch: Int
    let totalMatches: Int
    let onSearchChanged: (String) -> Void
    let onNext: () -> Void
    let onPrev: () -> Void
    let onClose: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            TextField("Find in document…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .frame(width: 190)
                .focused($isFocused)
                .onChange(of: query) { _, newValue in
                    onSearchChanged(newValue)
                }
                .onSubmit {
                    onNext()
                }
                .onExitCommand {
                    onClose()
                }

            if !query.isEmpty {
                Text(totalMatches > 0 ? "\(currentMatch) / \(totalMatches)" : "0 / 0")
                    .font(.system(size: 11.5).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 38, alignment: .trailing)
            }

            Divider()
                .frame(height: 14)

            Button(action: onPrev) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .disabled(totalMatches == 0)
            .help("Previous Match (⇧⌘G)")

            Button(action: onNext) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .disabled(totalMatches == 0)
            .help("Next Match (⌘G)")

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10.5, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .help("Close Find (Esc)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
        .onAppear {
            isFocused = true
        }
    }
}
