import SwiftUI

struct TOCSidebarView: View {
    let headings: [TOCItem]
    let activeHeadingID: String?
    let wordCount: Int
    let readingMinutes: Int
    let onSelect: (TOCItem) -> Void

    private var minLevel: Int {
        headings.map(\.level).min() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Outline")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if headings.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Text("No Headings")
                        .font(.system(size: 12.5))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(headings) { item in
                            let isActive = item.id == activeHeadingID
                            let indent = CGFloat(max(0, item.level - minLevel)) * 12

                            Button {
                                onSelect(item)
                            } label: {
                                HStack(spacing: 6) {
                                    Text(item.title)
                                        .font(.system(
                                            size: item.level <= 2 ? 12.5 : 12,
                                            weight: isActive ? .semibold : (item.level == 1 ? .medium : .regular)
                                        ))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundStyle(isActive ? Color.accentColor : Color.primary.opacity(0.85))
                                    Spacer(minLength: 0)
                                }
                                .padding(.leading, 10 + indent)
                                .padding(.trailing, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isActive ? Color.accentColor.opacity(0.12) : Color.clear)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 12)
                }
            }

            Divider()

            HStack {
                Text("\(wordCount) words")
                Spacer()
                Text("~\(readingMinutes) min read")
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
        .frame(width: 230)
        .background(.ultraThinMaterial)
    }
}
