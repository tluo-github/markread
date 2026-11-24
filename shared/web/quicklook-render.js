(function (global) {
  "use strict";

  function escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function markHighlightPlugin(mdInstance) {
    mdInstance.inline.ruler.before("emphasis", "mark_highlight", function (state, silent) {
      var start = state.pos;
      var src = state.src;
      if (src.charCodeAt(start) !== 0x3d || src.charCodeAt(start + 1) !== 0x3d) return false;
      var end = src.indexOf("==", start + 2);
      if (end === -1 || end === start + 2) return false;
      var inner = src.slice(start + 2, end);
      if (/^\s|\s$/.test(inner)) return false;

      if (!silent) {
        var open = state.push("mark_open", "mark", 1);
        open.attrSet("class", "md-highlight");
        var text = state.push("text", "", 0);
        text.content = inner;
        state.push("mark_close", "mark", -1);
      }
      state.pos = end + 2;
      return true;
    });
  }

  var CHECK_SVG =
    '<svg viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"><polyline points="2.2 6.4 4.8 9 9.8 3.2"/></svg>';

  var CALLOUT_META = {
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

  function taskListPlugin(mdInstance) {
    mdInstance.core.ruler.after("inline", "markread_task_lists", function (state) {
      var tokens = state.tokens;
      var listStack = [];

      for (var i = 0; i < tokens.length; i++) {
        var tok = tokens[i];
        if (tok.type === "bullet_list_open" || tok.type === "ordered_list_open") {
          listStack.push(tok);
        } else if (tok.type === "bullet_list_close" || tok.type === "ordered_list_close") {
          listStack.pop();
        } else if (
          tok.type === "list_item_open" &&
          i + 2 < tokens.length &&
          tokens[i + 1].type === "paragraph_open" &&
          tokens[i + 2].type === "inline"
        ) {
          var inlineTok = tokens[i + 2];
          var children = inlineTok.children;
          if (!children || !children.length || children[0].type !== "text") continue;

          var match = children[0].content.match(/^\[([ xX])\]\s+/);
          if (!match) continue;

          var checked = match[1].toLowerCase() === "x";
          children[0].content = children[0].content.slice(match[0].length);
          inlineTok.content = inlineTok.content.slice(match[0].length);

          var parentList = listStack[listStack.length - 1];
          if (parentList && parentList.type === "bullet_list_open") {
            parentList.attrJoin("class", "task-list");
          }
          tok.attrJoin("class", "task-list-item");

          var boxTok = new state.Token("html_inline", "", 0);
          boxTok.content =
            '<span class="task-checkbox' +
            (checked ? " checked" : "") +
            '" aria-hidden="true">' +
            (checked ? CHECK_SVG : "") +
            '</span><div class="task-content">';
          children.unshift(boxTok);

          var closeTok = new state.Token("html_inline", "", 0);
          closeTok.content = "</div>";
          children.push(closeTok);
        }
      }
    });
  }

  function calloutPlugin(mdInstance) {
    mdInstance.core.ruler.after("inline", "markread_callouts", function (state) {
      var tokens = state.tokens;
      for (var i = 0; i < tokens.length; i++) {
        if (tokens[i].type !== "blockquote_open") continue;

        // Find matching blockquote_close
        var depth = 1;
        var closeIdx = -1;
        for (var j = i + 1; j < tokens.length; j++) {
          if (tokens[j].type === "blockquote_open") depth++;
          else if (tokens[j].type === "blockquote_close") {
            depth--;
            if (depth === 0) {
              closeIdx = j;
              break;
            }
          }
        }
        if (closeIdx === -1) continue;

        if (
          i + 2 < closeIdx &&
          tokens[i + 1].type === "paragraph_open" &&
          tokens[i + 2].type === "inline"
        ) {
          var inlineTok = tokens[i + 2];
          var children = inlineTok.children;
          if (!children || !children.length || children[0].type !== "text") continue;

          var match = children[0].content.match(
            /^\s*\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\](?:[ \t]+([^\n]*))?/i
          );
          if (!match) continue;

          var kind = match[1].toUpperCase();
          var customTitle = (match[2] || "").trim();
          var meta = CALLOUT_META[kind];
          if (!meta) continue;

          children[0].content = children[0].content.slice(match[0].length);
          if (children.length > 1 && children[0].content === "" && children[1].type === "softbreak") {
            children.splice(0, 2);
          } else if (children[0].content === "") {
            children.shift();
          }

          var openHtml = new state.Token("html_block", "", 0);
          openHtml.content =
            '<div class="callout ' +
            meta.cls +
            '"><div class="callout-header">' +
            meta.icon +
            "<span>" +
            escapeHtml(customTitle || meta.label) +
            '</span></div><div class="callout-body">\n';

          var closeHtml = new state.Token("html_block", "", 0);
          closeHtml.content = "</div></div>\n";

          tokens[i] = openHtml;
          tokens[closeIdx] = closeHtml;
        }
      }
    });
  }

  var md = global.markdownit({
    html: true,
    linkify: true,
    typographer: true,
    breaks: false,
  });

  md.use(markHighlightPlugin);
  md.use(taskListPlugin);
  md.use(calloutPlugin);

  md.renderer.rules.table_open = function () {
    return '<div class="table-wrapper"><table>\n';
  };
  md.renderer.rules.table_close = function () {
    return "</table></div>\n";
  };

  md.renderer.rules.fence = function (tokens, idx) {
    var token = tokens[idx];
    var info = (token.info || "").trim();
    var lang = info ? info.split(/\s+/)[0].toLowerCase() : "";
    var code = token.content;

    var highlighted;
    if (lang && global.hljs && global.hljs.getLanguage(lang)) {
      try {
        highlighted = global.hljs.highlight(code, { language: lang, ignoreIllegals: true }).value;
      } catch (_) {
        highlighted = escapeHtml(code);
      }
    } else if (!lang && global.hljs) {
      try {
        highlighted = global.hljs.highlightAuto(code).value;
      } catch (_) {
        highlighted = escapeHtml(code);
      }
    } else {
      highlighted = escapeHtml(code);
    }

    var displayLang = escapeHtml(lang || "code");
    return (
      '<div class="code-block-wrapper">' +
      '<div class="code-block-header"><span class="code-lang">' +
      displayLang +
      "</span></div>" +
      '<pre><code class="hljs' +
      (lang ? " language-" + escapeHtml(lang) : "") +
      '">' +
      highlighted +
      "</code></pre></div>\n"
    );
  };

  function stripFrontMatter(raw) {
    var match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/);
    if (!match) return { entries: [], body: raw };
    var entries = [];
    var lines = match[1].split(/\r?\n/);
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (!line || line.charAt(0) === "#") continue;
      var colon = line.indexOf(":");
      if (colon > 0) {
        var key = line.slice(0, colon).trim();
        var val = line.slice(colon + 1).trim();
        if (
          (val.charAt(0) === '"' && val.charAt(val.length - 1) === '"') ||
          (val.charAt(0) === "'" && val.charAt(val.length - 1) === "'")
        ) {
          val = val.slice(1, -1);
        }
        entries.push({ key: key, val: val });
      }
    }
    return { entries: entries, body: raw.slice(match[0].length) };
  }

  global.renderQuickLookHTML = function (markdown, cssText, docTitle, showFrontMatter) {
    var parsed = stripFrontMatter(markdown || "");
    var fmHtml = "";
    if (showFrontMatter && parsed.entries.length > 0) {
      var rows = parsed.entries
        .map(function (item) {
          return (
            '<div class="front-matter-key">' +
            escapeHtml(item.key) +
            '</div><div class="front-matter-val">' +
            escapeHtml(item.val) +
            "</div>"
          );
        })
        .join("");
      fmHtml =
        '<section class="front-matter"><div class="front-matter-title">Front Matter</div><div class="front-matter-grid">' +
        rows +
        "</div></section>";
    }

    var bodyHtml = md.render(parsed.body);

    var qlOverrides =
      "html { color-scheme: light dark; }\n" +
      ".page-container { max-width: 820px; padding: 28px 36px 64px; }\n" +
      ".markdown-body img { cursor: default; }\n";

    return (
      '<!DOCTYPE html>\n<html lang="en" data-theme="github-auto">\n<head>\n' +
      '  <meta charset="UTF-8" />\n' +
      '  <meta name="viewport" content="width=device-width, initial-scale=1.0" />\n' +
      "  <title>" +
      escapeHtml(docTitle || "MarkRead Preview") +
      "</title>\n  <style>\n" +
      cssText +
      "\n" +
      qlOverrides +
      "  </style>\n</head>\n<body>\n" +
      '  <main class="page-container">\n' +
      fmHtml +
      '    <article class="markdown-body">\n' +
      bodyHtml +
      "\n    </article>\n  </main>\n</body>\n</html>"
    );
  };
})(this);
