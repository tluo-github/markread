(function () {
  "use strict";

  const postToHost = (payload) => {
    try {
      if (typeof window.__MARKREAD_BRIDGE__ === "function") {
        window.__MARKREAD_BRIDGE__(payload);
        return;
      }
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.markread) {
        window.webkit.messageHandlers.markread.postMessage(payload);
      }
    } catch (err) {
      console.error("MarkRead bridge error:", err);
    }
  };

  const getScrollContainer = () => document.getElementById("reader-scroll") || null;

  const getScrollY = () => {
    const el = getScrollContainer();
    return el ? el.scrollTop : window.scrollY;
  };

  const setScrollY = (y) => {
    const el = getScrollContainer();
    if (el) {
      el.scrollTop = y;
    } else {
      window.scrollTo({ top: y, behavior: "instant" });
    }
  };

  const escapeHtml = (str) =>
    str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");

  // Inline ==highlight== plugin for markdown-it
  function markHighlightPlugin(mdInstance) {
    mdInstance.inline.ruler.before("emphasis", "mark_highlight", (state, silent) => {
      const start = state.pos;
      const src = state.src;
      if (src.charCodeAt(start) !== 0x3d || src.charCodeAt(start + 1) !== 0x3d) return false;
      const end = src.indexOf("==", start + 2);
      if (end === -1 || end === start + 2) return false;
      const inner = src.slice(start + 2, end);
      if (/^\s|\s$/.test(inner)) return false;

      if (!silent) {
        const open = state.push("mark_open", "mark", 1);
        open.attrSet("class", "md-highlight");
        const text = state.push("text", "", 0);
        text.content = inner;
        state.push("mark_close", "mark", -1);
      }
      state.pos = end + 2;
      return true;
    });
  }

  // Initialize markdown-it with Highlight.js
  const md = window.markdownit({
    html: true,
    linkify: true,
    typographer: true,
    breaks: false,
    highlight(str, lang) {
      const normalized = (lang || "").trim().toLowerCase();
      if (normalized && window.hljs && window.hljs.getLanguage(normalized)) {
        try {
          return window.hljs.highlight(str, { language: normalized, ignoreIllegals: true }).value;
        } catch (_) {
          // fall through
        }
      }
      if (!normalized && window.hljs) {
        try {
          return window.hljs.highlightAuto(str).value;
        } catch (_) {
          // fall through
        }
      }
      return escapeHtml(str);
    },
  });
  md.use(markHighlightPlugin);

  const COPY_ICON =
    '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="5.5" y="5.5" width="8" height="8" rx="1.6"/><path d="M10.5 5.5V3.6A1.6 1.6 0 0 0 8.9 2H3.6A1.6 1.6 0 0 0 2 3.6v5.3a1.6 1.6 0 0 0 1.6 1.6h1.9"/></svg>';
  const CHECK_ICON =
    '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><polyline points="3.5 8.5 6.8 11.8 12.8 4.6"/></svg>';

  const CALLOUT_META = {
    NOTE: {
      cls: "callout-note",
      label: "Note",
      icon: '<svg class="callout-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><circle cx="8" cy="8" r="6.2"/><line x1="8" y1="7.2" x2="8" y2="11"/><circle cx="8" cy="4.8" r="0.6" fill="currentColor" stroke="none"/></svg>',
    },
    TIP: {
      cls: "callout-tip",
      label: "Tip",
      icon: '<svg class="callout-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M5.8 12.5h4.4M6.5 14.2h3M8 1.8a4.3 4.3 0 0 0-2.5 7.8c.5.4.8 1 .9 1.6h3.2c.1-.6.4-1.2.9-1.6A4.3 4.3 0 0 0 8 1.8Z"/></svg>',
    },
    IMPORTANT: {
      cls: "callout-important",
      label: "Important",
      icon: '<svg class="callout-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M2.6 3.5h10.8a1 1 0 0 1 1 1v6.2a1 1 0 0 1-1 1H6.6L3.6 14v-2.3H2.6a1 1 0 0 1-1-1V4.5a1 1 0 0 1 1-1Z"/><line x1="8" y1="5.7" x2="8" y2="8.4"/><circle cx="8" cy="10.2" r="0.6" fill="currentColor" stroke="none"/></svg>',
    },
    WARNING: {
      cls: "callout-warning",
      label: "Warning",
      icon: '<svg class="callout-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M7.1 2.6 1.8 12a1 1 0 0 0 .9 1.5h10.6a1 1 0 0 0 .9-1.5L8.9 2.6a1 1 0 0 0-1.8 0Z"/><line x1="8" y1="6.2" x2="8" y2="9.3"/><circle cx="8" cy="11.3" r="0.6" fill="currentColor" stroke="none"/></svg>',
    },
    CAUTION: {
      cls: "callout-caution",
      label: "Caution",
      icon: '<svg class="callout-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><polygon points="5.2 2 10.8 2 14 5.2 14 10.8 10.8 14 5.2 14 2 10.8 2 5.2"/><line x1="8" y1="5.4" x2="8" y2="8.8"/><circle cx="8" cy="11.1" r="0.6" fill="currentColor" stroke="none"/></svg>',
    },
  };

  let state = {
    markdown: "",
    theme: "github-auto",
    fontSize: 16,
    pageWidth: 860,
    showFrontMatter: false,
    headings: [],
    findQuery: "",
    findMatches: [],
    findIndex: -1,
  };

  function parseFrontMatter(raw) {
    const match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/);
    if (!match) {
      return { entries: [], body: raw };
    }
    const yamlBlock = match[1];
    const body = raw.slice(match[0].length);
    const entries = [];
    for (const line of yamlBlock.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) continue;
      const idx = trimmed.indexOf(":");
      if (idx > 0) {
        const key = trimmed.slice(0, idx).trim();
        let val = trimmed.slice(idx + 1).trim();
        if (
          (val.startsWith('"') && val.endsWith('"')) ||
          (val.startsWith("'") && val.endsWith("'"))
        ) {
          val = val.slice(1, -1);
        }
        entries.push({ key, val });
      }
    }
    return { entries, body };
  }

  function renderFrontMatter(entries) {
    const container = document.getElementById("front-matter");
    if (!entries.length || !state.showFrontMatter) {
      container.classList.add("hidden");
      container.innerHTML = "";
      return;
    }
    const rows = entries
      .map(
        (item) =>
          `<div class="front-matter-key">${escapeHtml(item.key)}</div>` +
          `<div class="front-matter-val">${escapeHtml(item.val)}</div>`
      )
      .join("");
    container.innerHTML = `<div class="front-matter-title">Front Matter</div><div class="front-matter-grid">${rows}</div>`;
    container.classList.remove("hidden");
  }

  function slugify(text, usedSlugs) {
    let base = text
      .toLowerCase()
      .trim()
      .replace(/[^\p{L}\p{N}\s-]/gu, "")
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-");
    if (!base) base = "section";
    let slug = base;
    let count = 1;
    while (usedSlugs.has(slug)) {
      slug = `${base}-${count++}`;
    }
    usedSlugs.add(slug);
    return slug;
  }

  function enhanceCallouts(root) {
    root.querySelectorAll("blockquote").forEach((bq) => {
      const firstP = bq.firstElementChild;
      if (!firstP || firstP.tagName !== "P") return;
      const firstNode = firstP.firstChild;
      if (!firstNode || firstNode.nodeType !== Node.TEXT_NODE) return;

      const match = firstNode.nodeValue.match(/^\s*\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\](?:[ \t]+([^\n]*))?(?:\r?\n)?/i);
      if (!match) return;

      const kind = match[1].toUpperCase();
      const customTitle = (match[2] || "").trim();
      const meta = CALLOUT_META[kind];
      if (!meta) return;

      firstNode.nodeValue = firstNode.nodeValue.slice(match[0].length);
      if (firstP.firstChild && firstP.firstChild.nodeType === Node.TEXT_NODE && firstP.firstChild.nodeValue === "") {
        firstP.removeChild(firstP.firstChild);
      }
      if (firstP.firstChild && firstP.firstChild.nodeName === "BR") {
        firstP.removeChild(firstP.firstChild);
      }
      if (!firstP.textContent.trim() && firstP.children.length === 0) {
        firstP.remove();
      }

      const card = document.createElement("div");
      card.className = `callout ${meta.cls}`;

      const header = document.createElement("div");
      header.className = "callout-header";
      header.innerHTML = `${meta.icon}<span>${escapeHtml(customTitle || meta.label)}</span>`;

      const body = document.createElement("div");
      body.className = "callout-body";
      while (bq.firstChild) {
        body.appendChild(bq.firstChild);
      }

      card.appendChild(header);
      if (body.childNodes.length > 0) {
        card.appendChild(body);
      }
      bq.replaceWith(card);
    });
  }

  function enhanceTaskLists(root) {
    const listItems = root.querySelectorAll("li");
    listItems.forEach((li) => {
      const firstChild = li.firstChild;
      let targetNode = null;
      if (firstChild && firstChild.nodeType === Node.TEXT_NODE) {
        targetNode = firstChild;
      } else if (
        firstChild &&
        firstChild.nodeType === Node.ELEMENT_NODE &&
        firstChild.tagName === "P" &&
        firstChild.firstChild &&
        firstChild.firstChild.nodeType === Node.TEXT_NODE
      ) {
        targetNode = firstChild.firstChild;
      }
      if (!targetNode) return;

      const match = targetNode.nodeValue.match(/^\[([ xX])\]\s+/);
      if (!match) return;

      const isChecked = match[1].toLowerCase() === "x";
      targetNode.nodeValue = targetNode.nodeValue.slice(match[0].length);

      const parentUl = li.parentElement;
      if (parentUl && parentUl.tagName === "UL") {
        parentUl.classList.add("task-list");
      }
      li.classList.add("task-list-item");

      const contentWrapper = document.createElement("div");
      contentWrapper.className = "task-content";
      while (li.firstChild) {
        contentWrapper.appendChild(li.firstChild);
      }

      const checkbox = document.createElement("span");
      checkbox.className = isChecked ? "task-checkbox checked" : "task-checkbox";
      checkbox.setAttribute("aria-hidden", "true");
      if (isChecked) {
        checkbox.innerHTML =
          '<svg viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"><polyline points="2.2 6.4 4.8 9 9.8 3.2"/></svg>';
      }

      li.appendChild(checkbox);
      li.appendChild(contentWrapper);
    });
  }

  function enhanceTables(root) {
    root.querySelectorAll("table").forEach((table) => {
      if (table.parentElement && table.parentElement.classList.contains("table-wrapper")) return;
      const wrapper = document.createElement("div");
      wrapper.className = "table-wrapper";
      table.parentNode.insertBefore(wrapper, table);
      wrapper.appendChild(table);
    });
  }

  function enhanceCodeBlocks(root) {
    root.querySelectorAll("pre").forEach((pre) => {
      const code = pre.querySelector("code");
      if (!code) return;

      let lang = "";
      for (const cls of code.classList) {
        if (cls.startsWith("language-")) {
          lang = cls.replace("language-", "");
          break;
        }
      }
      code.classList.add("hljs");

      const wrapper = document.createElement("div");
      wrapper.className = "code-block-wrapper";

      const header = document.createElement("div");
      header.className = "code-block-header";

      const langLabel = document.createElement("span");
      langLabel.className = "code-lang";
      langLabel.textContent = lang || "code";

      const copyBtn = document.createElement("button");
      copyBtn.type = "button";
      copyBtn.className = "code-copy-btn";
      copyBtn.innerHTML = `${COPY_ICON}<span>Copy</span>`;
      copyBtn.addEventListener("click", () => {
        const rawText = code.innerText;
        postToHost({ type: "copyText", text: rawText });
        copyBtn.innerHTML = `${CHECK_ICON}<span>Copied</span>`;
        copyBtn.classList.add("copied");
        setTimeout(() => {
          copyBtn.innerHTML = `${COPY_ICON}<span>Copy</span>`;
          copyBtn.classList.remove("copied");
        }, 1500);
      });

      header.appendChild(langLabel);
      header.appendChild(copyBtn);

      pre.parentNode.insertBefore(wrapper, pre);
      wrapper.appendChild(header);
      wrapper.appendChild(pre);
    });
  }

  function enhanceImages(root) {
    root.querySelectorAll("img").forEach((img) => {
      const src = img.getAttribute("src");
      if (src) {
        const trimmed = src.trim();
        if (!/^(https?:|data:|markread-local:|markread-asset:|blob:)/i.test(trimmed)) {
          const cleanPath = trimmed.replace(/^\.\//, "");
          const base = window.__MARKREAD_LOCAL_BASE__ || "markread-local://file/";
          img.setAttribute("src", `${base}${encodeURI(cleanPath)}`);
        }
      }

      // Wrap standalone images with descriptive alt text in figure + figcaption
      const parent = img.parentElement;
      const alt = (img.getAttribute("alt") || "").trim();
      if (
        parent &&
        parent.tagName === "P" &&
        parent.childNodes.length === 1 &&
        alt &&
        !/\.(png|jpe?g|gif|webp|svg)$/i.test(alt)
      ) {
        const fig = document.createElement("figure");
        fig.className = "md-figure";
        const cap = document.createElement("figcaption");
        cap.textContent = alt;
        parent.replaceWith(fig);
        fig.appendChild(img);
        fig.appendChild(cap);
      }
    });
  }

  function extractHeadings(root) {
    const usedSlugs = new Set();
    const headings = [];
    root.querySelectorAll("h1, h2, h3, h4, h5, h6").forEach((el) => {
      const level = parseInt(el.tagName.slice(1), 10);
      const title = (el.textContent || "").trim();
      const id = slugify(title, usedSlugs);
      el.id = id;
      headings.push({ id, level, title });
    });
    state.headings = headings;
    postToHost({ type: "toc", items: headings });
  }

  // Lightbox image zoom
  const lightbox = document.getElementById("image-lightbox");
  const lightboxImg = document.getElementById("lightbox-img");
  const lightboxCaption = document.getElementById("lightbox-caption");

  function openLightbox(img) {
    lightboxImg.src = img.src;
    lightboxImg.alt = img.alt || "";
    lightboxCaption.textContent = img.alt || "";
    lightbox.classList.remove("hidden");
  }

  function closeLightbox() {
    lightbox.classList.add("hidden");
    lightboxImg.removeAttribute("src");
  }

  lightbox.addEventListener("click", closeLightbox);
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && !lightbox.classList.contains("hidden")) {
      closeLightbox();
    }
  });

  // Intercept link & image clicks cleanly
  document.addEventListener("click", (event) => {
    if (event.target.tagName === "IMG" && event.target.closest("#content")) {
      openLightbox(event.target);
      return;
    }

    const anchor = event.target.closest("a");
    if (!anchor) return;
    const href = anchor.getAttribute("href");
    if (!href) return;

    event.preventDefault();

    if (href.startsWith("#")) {
      const targetId = decodeURIComponent(href.slice(1));
      const target = document.getElementById(targetId);
      if (target) {
        target.scrollIntoView({ behavior: "smooth", block: "start" });
      }
      return;
    }

    if (/^(https?:|mailto:)/i.test(href)) {
      postToHost({ type: "openExternal", url: href });
      return;
    }

    if (/\.(md|markdown|mdown|mkd|mkdn|mdtxt|mdtext)(#.*)?$/i.test(href)) {
      const cleanPath = href.split("#")[0];
      postToHost({ type: "openRelativeMarkdown", path: decodeURIComponent(cleanPath) });
      return;
    }

    postToHost({ type: "openExternal", url: href });
  });

  // Scroll spy + subtle top reading progress bar
  const progressBar = document.getElementById("reading-progress");
  let scrollRaf = null;

  function onScrollFrame() {
    scrollRaf = null;

    const scroller = getScrollContainer();
    const scrollY = scroller ? scroller.scrollTop : window.scrollY;
    const maxScroll = scroller
      ? scroller.scrollHeight - scroller.clientHeight
      : document.documentElement.scrollHeight - window.innerHeight;
    const containerTop = scroller ? scroller.getBoundingClientRect().top : 0;

    // Update reading progress bar
    if (progressBar) {
      if (maxScroll > 120 && scrollY > 24) {
        const ratio = Math.min(1, Math.max(0, scrollY / maxScroll));
        progressBar.style.width = `${(ratio * 100).toFixed(2)}%`;
        progressBar.classList.add("visible");
      } else {
        progressBar.classList.remove("visible");
        progressBar.style.width = "0%";
      }
    }

    // Active heading spy
    if (!state.headings.length) return;
    let activeId = state.headings[0].id;
    const offset = containerTop + 96;
    for (const h of state.headings) {
      const el = document.getElementById(h.id);
      if (!el) continue;
      if (el.getBoundingClientRect().top <= offset) {
        activeId = h.id;
      } else {
        break;
      }
    }
    postToHost({ type: "activeHeading", id: activeId });
  }

  const scrollTarget = getScrollContainer() || window;
  scrollTarget.addEventListener(
    "scroll",
    () => {
      if (scrollRaf === null) {
        scrollRaf = requestAnimationFrame(onScrollFrame);
      }
    },
    { passive: true }
  );

  // In-page Find helpers
  function clearFindHighlights() {
    const marks = document.querySelectorAll("mark.mr-find-match");
    marks.forEach((mark) => {
      const parent = mark.parentNode;
      if (!parent) return;
      parent.replaceChild(document.createTextNode(mark.textContent || ""), mark);
      parent.normalize();
    });
    state.findMatches = [];
    state.findIndex = -1;
  }

  function highlightMatches(query) {
    clearFindHighlights();
    state.findQuery = query || "";
    if (!state.findQuery) {
      postToHost({ type: "findResult", current: 0, total: 0 });
      return;
    }

    const content = document.getElementById("content");
    const lowerQuery = state.findQuery.toLowerCase();
    const walker = document.createTreeWalker(content, NodeFilter.SHOW_TEXT, {
      acceptNode(node) {
        if (!node.nodeValue || !node.nodeValue.trim()) return NodeFilter.FILTER_REJECT;
        const parent = node.parentElement;
        if (!parent) return NodeFilter.FILTER_REJECT;
        if (parent.closest(".code-block-header, script, style")) {
          return NodeFilter.FILTER_REJECT;
        }
        return NodeFilter.FILTER_ACCEPT;
      },
    });

    const textNodes = [];
    let current;
    while ((current = walker.nextNode())) {
      textNodes.push(current);
    }

    const marks = [];
    for (const textNode of textNodes) {
      const text = textNode.nodeValue;
      const lower = text.toLowerCase();
      let idx = lower.indexOf(lowerQuery);
      if (idx === -1) continue;

      const frag = document.createDocumentFragment();
      let lastIdx = 0;
      while (idx !== -1) {
        if (idx > lastIdx) {
          frag.appendChild(document.createTextNode(text.slice(lastIdx, idx)));
        }
        const mark = document.createElement("mark");
        mark.className = "mr-find-match";
        mark.textContent = text.slice(idx, idx + state.findQuery.length);
        frag.appendChild(mark);
        marks.push(mark);

        lastIdx = idx + state.findQuery.length;
        idx = lower.indexOf(lowerQuery, lastIdx);
      }
      if (lastIdx < text.length) {
        frag.appendChild(document.createTextNode(text.slice(lastIdx)));
      }
      textNode.parentNode.replaceChild(frag, textNode);
    }

    state.findMatches = marks;
    if (marks.length > 0) {
      state.findIndex = 0;
      activateFindMatch(0);
    } else {
      postToHost({ type: "findResult", current: 0, total: 0 });
    }
  }

  function activateFindMatch(index) {
    const total = state.findMatches.length;
    if (!total) {
      postToHost({ type: "findResult", current: 0, total: 0 });
      return;
    }
    state.findMatches.forEach((m) => m.classList.remove("current"));
    state.findIndex = ((index % total) + total) % total;
    const active = state.findMatches[state.findIndex];
    active.classList.add("current");
    active.scrollIntoView({ behavior: "smooth", block: "center" });
    postToHost({ type: "findResult", current: state.findIndex + 1, total });
  }

  function applyPreferences() {
    document.documentElement.setAttribute("data-theme", state.theme);
    document.documentElement.style.setProperty("--font-size", `${state.fontSize}px`);
    const widthVal = state.pageWidth > 0 ? `${state.pageWidth}px` : "100%";
    document.documentElement.style.setProperty("--page-max-width", widthVal);
  }

  // Public API invoked from Host (Swift WKWebView or Windows Tauri)
  window.MarkRead = {
    render(payload) {
      const savedScrollY = payload.preserveScroll ? getScrollY() : 0;

      state.markdown = payload.markdown ?? "";
      if (payload.theme) state.theme = payload.theme;
      if (payload.fontSize) state.fontSize = payload.fontSize;
      if (typeof payload.pageWidth === "number") state.pageWidth = payload.pageWidth;
      if (typeof payload.showFrontMatter === "boolean") {
        state.showFrontMatter = payload.showFrontMatter;
      }

      applyPreferences();

      const { entries, body } = parseFrontMatter(state.markdown);
      renderFrontMatter(entries);

      const content = document.getElementById("content");
      content.innerHTML = md.render(body);

      enhanceCallouts(content);
      enhanceTaskLists(content);
      enhanceTables(content);
      enhanceCodeBlocks(content);
      enhanceImages(content);
      extractHeadings(content);

      if (state.findQuery) {
        highlightMatches(state.findQuery);
      }

      if (payload.preserveScroll) {
        setScrollY(savedScrollY);
      } else {
        setScrollY(0);
      }

      onScrollFrame();
    },

    updatePreferences(prefs) {
      const fmChanged =
        typeof prefs.showFrontMatter === "boolean" &&
        prefs.showFrontMatter !== state.showFrontMatter;

      if (prefs.theme) state.theme = prefs.theme;
      if (prefs.fontSize) state.fontSize = prefs.fontSize;
      if (typeof prefs.pageWidth === "number") state.pageWidth = prefs.pageWidth;
      if (typeof prefs.showFrontMatter === "boolean") {
        state.showFrontMatter = prefs.showFrontMatter;
      }

      applyPreferences();

      if (fmChanged) {
        const { entries } = parseFrontMatter(state.markdown);
        renderFrontMatter(entries);
      }
    },

    scrollToHeading(id) {
      const target = document.getElementById(id);
      if (target) {
        target.scrollIntoView({ behavior: "smooth", block: "start" });
      }
    },

    find(query) {
      highlightMatches(query);
    },

    findNext() {
      if (state.findMatches.length) {
        activateFindMatch(state.findIndex + 1);
      }
    },

    findPrev() {
      if (state.findMatches.length) {
        activateFindMatch(state.findIndex - 1);
      }
    },

    clearFind() {
      state.findQuery = "";
      clearFindHighlights();
      postToHost({ type: "findResult", current: 0, total: 0 });
    },

    getStandaloneHTML(docTitle) {
      let cssText = "";
      for (const sheet of Array.from(document.styleSheets)) {
        try {
          for (const rule of Array.from(sheet.cssRules)) {
            cssText += rule.cssText + "\n";
          }
        } catch (_) {
          // ignore cross-origin rules
        }
      }
      const clone = document.getElementById("page").cloneNode(true);
      clone.querySelectorAll(".code-copy-btn").forEach((b) => b.remove());
      clone.querySelectorAll("mark.mr-find-match").forEach((m) => {
        m.replaceWith(document.createTextNode(m.textContent || ""));
      });

      return `<!DOCTYPE html>
<html lang="en" data-theme="${escapeHtml(state.theme)}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${escapeHtml(docTitle || "MarkRead Export")}</title>
  <style>
${cssText}
  </style>
</head>
<body>
${clone.outerHTML}
</body>
</html>`;
    },
  };

  postToHost({ type: "ready" });
})();
