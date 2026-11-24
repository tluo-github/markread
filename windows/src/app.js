(function () {
  "use strict";

  const isWindows = /Windows/i.test(navigator.userAgent);
  window.__MARKREAD_LOCAL_BASE__ = isWindows
    ? "http://markread-local.localhost/file/"
    : "markread-local://localhost/file/";

  const invoke = (cmd, args) => window.__TAURI__.core.invoke(cmd, args);
  const listen = (event, handler) => window.__TAURI__.event.listen(event, handler);

  const prefs = {
    theme: localStorage.getItem("markread.theme") || "github-auto",
    fontSize: parseInt(localStorage.getItem("markread.fontSize") || "16", 10) || 16,
    pageWidth: (() => {
      const saved = localStorage.getItem("markread.pageWidth");
      return saved !== null ? parseInt(saved, 10) : 860;
    })(),
    showFrontMatter: localStorage.getItem("markread.showFrontMatter") === "true",
  };

  let currentDoc = {
    path: null,
    title: "MarkRead",
    hasDocument: false,
    headings: [],
    activeHeadingID: null,
  };

  let isRendererReady = false;
  let pendingRenderPayload = null;
  let sidebarVisible = false;

  // DOM references
  const docTitleEl = document.getElementById("doc-title");
  const btnSidebar = document.getElementById("btn-sidebar");
  const btnOpen = document.getElementById("btn-open");
  const btnFind = document.getElementById("btn-find");
  const btnAppearance = document.getElementById("btn-appearance");
  const appearanceMenu = document.getElementById("appearance-menu");
  const tocSidebar = document.getElementById("toc-sidebar");
  const tocList = document.getElementById("toc-list");
  const statWords = document.getElementById("stat-words");
  const statTime = document.getElementById("stat-time");
  const welcomeView = document.getElementById("welcome-view");
  const readerScroll = document.getElementById("reader-scroll");
  const findBar = document.getElementById("find-bar");
  const findInput = document.getElementById("find-input");
  const findCount = document.getElementById("find-count");
  const dropOverlay = document.getElementById("drop-overlay");
  const zoomLabel = document.getElementById("zoom-label");
  const menuFrontMatter = document.getElementById("menu-frontmatter");
  const menuExportHtml = document.getElementById("menu-export-html");
  const menuPrint = document.getElementById("menu-print");
  const menuReveal = document.getElementById("menu-reveal");

  function savePrefs() {
    localStorage.setItem("markread.theme", prefs.theme);
    localStorage.setItem("markread.fontSize", String(prefs.fontSize));
    localStorage.setItem("markread.pageWidth", String(prefs.pageWidth));
    localStorage.setItem("markread.showFrontMatter", String(prefs.showFrontMatter));
  }

  function syncMenuUI() {
    document.documentElement.setAttribute("data-theme", prefs.theme);
    document.querySelectorAll("[data-theme-option]").forEach((btn) => {
      const check = btn.querySelector(".check");
      check.textContent = btn.getAttribute("data-theme-option") === prefs.theme ? "✓" : "";
    });
    document.querySelectorAll("[data-width-option]").forEach((btn) => {
      const check = btn.querySelector(".check");
      check.textContent = parseInt(btn.getAttribute("data-width-option"), 10) === prefs.pageWidth ? "✓" : "";
    });
    menuFrontMatter.querySelector(".check").textContent = prefs.showFrontMatter ? "✓" : "";
    zoomLabel.textContent = `${prefs.fontSize}px`;
  }

  function applyPrefsToRenderer() {
    savePrefs();
    syncMenuUI();
    if (window.MarkRead && isRendererReady) {
      window.MarkRead.updatePreferences({
        theme: prefs.theme,
        fontSize: prefs.fontSize,
        pageWidth: prefs.pageWidth,
        showFrontMatter: prefs.showFrontMatter,
      });
    }
  }

  function updateDocumentChrome() {
    const hasDoc = currentDoc.hasDocument;
    btnSidebar.disabled = !hasDoc;
    btnFind.disabled = !hasDoc;
    menuExportHtml.disabled = !hasDoc;
    menuPrint.disabled = !hasDoc;
    menuReveal.disabled = !currentDoc.path;
    docTitleEl.textContent = currentDoc.title;
    welcomeView.classList.toggle("hidden", hasDoc);
    readerScroll.classList.toggle("hidden", !hasDoc);
    if (!hasDoc) {
      tocSidebar.classList.add("hidden");
      sidebarVisible = false;
      btnSidebar.classList.remove("active");
    }
    invoke("set_window_title", {
      title: hasDoc ? `${currentDoc.title} — MarkRead` : "MarkRead",
    }).catch(() => {});
  }

  function renderTOC() {
    tocList.innerHTML = "";
    if (!currentDoc.headings.length) {
      tocList.innerHTML = '<div class="toc-empty">No Headings</div>';
      return;
    }
    const minLevel = Math.min(...currentDoc.headings.map((h) => h.level));
    for (const item of currentDoc.headings) {
      const btn = document.createElement("button");
      btn.className = "toc-item" + (item.id === currentDoc.activeHeadingID ? " active" : "");
      btn.textContent = item.title;
      btn.dataset.headingId = item.id;
      btn.style.paddingLeft = `${10 + Math.max(0, item.level - minLevel) * 12}px`;
      btn.addEventListener("click", () => {
        window.MarkRead && window.MarkRead.scrollToHeading(item.id);
      });
      tocList.appendChild(btn);
    }
  }

  function updateActiveTOC(id) {
    currentDoc.activeHeadingID = id;
    tocList.querySelectorAll(".toc-item").forEach((el) => {
      el.classList.toggle("active", el.dataset.headingId === id);
    });
  }

  function renderDocument(doc, preserveScroll = false) {
    currentDoc.path = doc.path || null;
    currentDoc.title = doc.title || "MarkRead";
    currentDoc.hasDocument = true;
    statWords.textContent = `${doc.wordCount} words`;
    statTime.textContent = `~${doc.readingMinutes} min read`;
    updateDocumentChrome();

    const payload = {
      markdown: doc.content,
      theme: prefs.theme,
      fontSize: prefs.fontSize,
      pageWidth: prefs.pageWidth,
      showFrontMatter: prefs.showFrontMatter,
      preserveScroll,
    };

    if (isRendererReady && window.MarkRead) {
      window.MarkRead.render(payload);
    } else {
      pendingRenderPayload = payload;
    }
  }

  async function openMarkdownPath(path, preserveScroll = false) {
    try {
      const doc = await invoke("read_markdown_file", { path });
      renderDocument(doc, preserveScroll);
    } catch (err) {
      alert(`Unable to open file:\n${err}`);
    }
  }

  async function openSample() {
    try {
      const doc = await invoke("get_sample_markdown");
      renderDocument(doc, false);
    } catch (err) {
      console.error(err);
    }
  }

  async function openFileDialog() {
    try {
      const selected = await invoke("pick_open_file");
      if (typeof selected === "string" && selected) {
        await openMarkdownPath(selected, false);
      }
    } catch (err) {
      console.error("Open dialog failed:", err);
    }
  }

  async function exportHTML() {
    if (!currentDoc.hasDocument || !window.MarkRead) return;
    try {
      const baseName = currentDoc.title.replace(/\.[^.]+$/, "") || "MarkRead";
      const dest = await invoke("pick_save_html_file", {
        defaultName: `${baseName}.html`,
      });
      if (typeof dest === "string" && dest) {
        const html = window.MarkRead.getStandaloneHTML(currentDoc.title);
        await invoke("save_text_file", { path: dest, content: html });
      }
    } catch (err) {
      console.error("Export HTML failed:", err);
    }
  }

  function toggleSidebar() {
    if (!currentDoc.hasDocument) return;
    sidebarVisible = !sidebarVisible;
    tocSidebar.classList.toggle("hidden", !sidebarVisible);
    btnSidebar.classList.toggle("active", sidebarVisible);
  }

  function openFindBar() {
    if (!currentDoc.hasDocument) return;
    findBar.classList.remove("hidden");
    findInput.focus();
    findInput.select();
  }

  function closeFindBar() {
    findBar.classList.add("hidden");
    findInput.value = "";
    findCount.textContent = "";
    window.MarkRead && window.MarkRead.clearFind();
  }

  // Register JS bridge BEFORE shared/web/renderer.js loads
  window.__MARKREAD_BRIDGE__ = (msg) => {
    if (!msg || !msg.type) return;
    switch (msg.type) {
      case "ready":
        isRendererReady = true;
        if (pendingRenderPayload && window.MarkRead) {
          const payload = pendingRenderPayload;
          pendingRenderPayload = null;
          window.MarkRead.render(payload);
        }
        break;
      case "toc":
        currentDoc.headings = msg.items || [];
        renderTOC();
        break;
      case "activeHeading":
        updateActiveTOC(msg.id);
        break;
      case "findResult":
        findCount.textContent = findInput.value
          ? `${msg.current || 0} / ${msg.total || 0}`
          : "";
        break;
      case "copyText":
        if (navigator.clipboard && msg.text) {
          navigator.clipboard.writeText(msg.text).catch(() => {});
        }
        break;
      case "openExternal":
        if (msg.url) {
          invoke("open_external_url", { url: msg.url }).catch(() => {});
        }
        break;
      case "openRelativeMarkdown":
        if (msg.path) {
          invoke("resolve_relative_markdown", { relativePath: msg.path })
            .then((resolved) => {
              if (resolved) openMarkdownPath(resolved, false);
            })
            .catch(() => {});
        }
        break;
    }
  };

  // Wire UI Events
  btnOpen.addEventListener("click", openFileDialog);
  document.getElementById("welcome-open").addEventListener("click", openFileDialog);
  document.getElementById("welcome-sample").addEventListener("click", openSample);
  btnSidebar.addEventListener("click", toggleSidebar);
  btnFind.addEventListener("click", openFindBar);

  btnAppearance.addEventListener("click", (e) => {
    e.stopPropagation();
    appearanceMenu.classList.toggle("hidden");
  });
  document.addEventListener("click", (e) => {
    if (!appearanceMenu.contains(e.target) && e.target !== btnAppearance) {
      appearanceMenu.classList.add("hidden");
    }
  });

  document.querySelectorAll("[data-theme-option]").forEach((btn) => {
    btn.addEventListener("click", () => {
      prefs.theme = btn.getAttribute("data-theme-option");
      applyPrefsToRenderer();
    });
  });

  document.querySelectorAll("[data-width-option]").forEach((btn) => {
    btn.addEventListener("click", () => {
      prefs.pageWidth = parseInt(btn.getAttribute("data-width-option"), 10);
      applyPrefsToRenderer();
    });
  });

  menuFrontMatter.addEventListener("click", () => {
    prefs.showFrontMatter = !prefs.showFrontMatter;
    applyPrefsToRenderer();
  });

  document.getElementById("menu-zoom-in").addEventListener("click", () => {
    prefs.fontSize = Math.min(28, prefs.fontSize + 1);
    applyPrefsToRenderer();
  });
  document.getElementById("menu-zoom-out").addEventListener("click", () => {
    prefs.fontSize = Math.max(12, prefs.fontSize - 1);
    applyPrefsToRenderer();
  });
  document.getElementById("menu-zoom-reset").addEventListener("click", () => {
    prefs.fontSize = 16;
    applyPrefsToRenderer();
  });

  menuExportHtml.addEventListener("click", () => {
    appearanceMenu.classList.add("hidden");
    exportHTML();
  });
  menuPrint.addEventListener("click", () => {
    appearanceMenu.classList.add("hidden");
    window.print();
  });
  menuReveal.addEventListener("click", () => {
    appearanceMenu.classList.add("hidden");
    if (currentDoc.path) {
      invoke("reveal_in_explorer", { path: currentDoc.path }).catch(() => {});
    }
  });

  // Find bar events
  findInput.addEventListener("input", () => {
    window.MarkRead && window.MarkRead.find(findInput.value);
  });
  findInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      if (e.shiftKey) window.MarkRead && window.MarkRead.findPrev();
      else window.MarkRead && window.MarkRead.findNext();
    } else if (e.key === "Escape") {
      closeFindBar();
    }
  });
  document.getElementById("find-next").addEventListener("click", () => window.MarkRead && window.MarkRead.findNext());
  document.getElementById("find-prev").addEventListener("click", () => window.MarkRead && window.MarkRead.findPrev());
  document.getElementById("find-close").addEventListener("click", closeFindBar);

  // Keyboard shortcuts (Windows Ctrl + macOS Cmd compatible)
  document.addEventListener("keydown", (e) => {
    const mod = e.ctrlKey || e.metaKey;
    if (mod && !e.shiftKey && e.key.toLowerCase() === "o") {
      e.preventDefault();
      openFileDialog();
    } else if (mod && e.shiftKey && e.key.toLowerCase() === "o") {
      e.preventDefault();
      toggleSidebar();
    } else if (mod && !e.shiftKey && e.key.toLowerCase() === "f") {
      e.preventDefault();
      openFindBar();
    } else if (e.key === "F3") {
      e.preventDefault();
      if (e.shiftKey) window.MarkRead && window.MarkRead.findPrev();
      else window.MarkRead && window.MarkRead.findNext();
    } else if (mod && e.shiftKey && e.key.toLowerCase() === "m") {
      e.preventDefault();
      prefs.showFrontMatter = !prefs.showFrontMatter;
      applyPrefsToRenderer();
    } else if (mod && e.shiftKey && e.key.toLowerCase() === "e") {
      e.preventDefault();
      exportHTML();
    } else if (mod && e.shiftKey && e.key.toLowerCase() === "r") {
      e.preventDefault();
      if (currentDoc.path) invoke("reveal_in_explorer", { path: currentDoc.path }).catch(() => {});
    } else if (mod && !e.shiftKey && e.key.toLowerCase() === "r") {
      e.preventDefault();
      if (currentDoc.path) openMarkdownPath(currentDoc.path, true);
    } else if (mod && (e.key === "=" || e.key === "+")) {
      e.preventDefault();
      prefs.fontSize = Math.min(28, prefs.fontSize + 1);
      applyPrefsToRenderer();
    } else if (mod && e.key === "-") {
      e.preventDefault();
      prefs.fontSize = Math.max(12, prefs.fontSize - 1);
      applyPrefsToRenderer();
    } else if (mod && e.key === "0") {
      e.preventDefault();
      prefs.fontSize = 16;
      applyPrefsToRenderer();
    } else if (e.key === "Escape" && !findBar.classList.contains("hidden")) {
      closeFindBar();
    }
  });

  // Initialize Tauri events & initial CLI file
  syncMenuUI();
  updateDocumentChrome();

  if (window.__TAURI__) {
    listen("file-changed", (event) => {
      if (currentDoc.path && event.payload === currentDoc.path) {
        openMarkdownPath(currentDoc.path, true);
      }
    });

    listen("tauri://drag-enter", () => dropOverlay.classList.remove("hidden"));
    listen("tauri://drag-leave", () => dropOverlay.classList.add("hidden"));
    listen("tauri://drag-drop", (event) => {
      dropOverlay.classList.add("hidden");
      const paths = event.payload && event.payload.paths;
      if (Array.isArray(paths) && paths.length > 0) {
        const mdFile = paths.find((p) => /\.(md|markdown|mdown|mkd|mkdn|txt)$/i.test(p));
        if (mdFile) openMarkdownPath(mdFile, false);
      }
    });

    invoke("get_initial_file")
      .then((filePath) => {
        if (filePath) openMarkdownPath(filePath, false);
      })
      .catch(() => {});
  }
})();
