---
title: MarkRead Showcase
version: 0.1.0
license: Free & Offline
author: MarkRead
---

# Welcome to MarkRead

**MarkRead 0.1** — A minimal, native macOS Markdown reader inspired by Typora's typography aesthetics.

Open any `.md` file from Finder, drag and drop it onto this window, or press `⌘O` to start reading immediately.

| Feature | Status | Shortcut |
| :--- | :--- | :--- |
| GitHub Flavored Markdown | Supported | — |
| Syntax highlighting (Highlight.js) | 35+ languages offline | — |
| Typora-inspired themes | GitHub / Night / Newsprint / Vue | Toolbar / View Menu |
| Collapsible Table of Contents | Synced while scrolling | `⌘⇧O` |
| In-document Find | Highlight & jump | `⌘F` |
| Live File Reload | Preserves scroll position | `⌘R` |
| Front Matter toggle | Shown or hidden | `⌘⇧M` |
| PDF & HTML Export | From File menu | `⌘⇧P` / `⌘⇧E` |

## Task Lists & Inline Formatting

- [x] Tables, task lists, ~~strikethrough~~, and autolinks
- [x] YAML front matter shown or hidden cleanly
- [x] Local relative image resolution
- [x] One-click code block copy
- [ ] Nothing else to configure

> Everything renders locally on your Mac. Free, no network, no account.

> [!TIP]
> 支持 GitHub / Obsidian 风格的提示卡片（`NOTE`、`TIP`、`IMPORTANT`、`WARNING`、`CAUTION`），以及 ==文本荧光笔高亮== 与中英文混排优化。

## Syntax Highlighting

### Swift

```swift
import SwiftUI

struct ReaderHeader: View {
    let title: String
    let wordCount: Int

    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            Text("\(wordCount) words")
                .foregroundStyle(.secondary)
        }
    }
}
```

### TypeScript

```typescript
interface MarkdownDocument {
  path: string;
  title: string;
  headings: Array<{ id: string; level: number; title: string }>;
}

export function estimateReadingMinutes(text: string): number {
  const words = text.trim().split(/\s+/).filter(Boolean).length;
  return Math.max(1, Math.ceil(words / 220));
}
```

### Python

```python
from pathlib import Path

def find_markdown_files(root: Path) -> list[Path]:
    """Recursively collect local Markdown files."""
    return sorted(p for p in root.rglob("*.md") if not p.name.startswith("."))
```

### Shell

```bash
# Build and launch MarkRead locally
./scripts/build.sh --run
```

## Typography & Hierarchy

Good typography gets out of the way so you can focus on ideas. Try switching between **GitHub (Auto)**, **Night**, **Newsprint**, and **Vue** in the toolbar to experience different reading moods, or press `⌘+` / `⌘-` to adjust reading scale.
