use notify::{Config, EventKind, RecommendedWatcher, RecursiveMode, Watcher};
use percent_encoding::percent_decode_str;
use serde::Serialize;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};
use tauri::{AppHandle, Emitter, Manager, State};
use tauri_plugin_dialog::DialogExt;
use tauri_plugin_opener::OpenerExt;

const SAMPLE_MD: &str = include_str!("../../../shared/Sample.md");

struct AppState {
    current_dir: Arc<Mutex<Option<PathBuf>>>,
    watcher: Mutex<Option<RecommendedWatcher>>,
    initial_file: Mutex<Option<String>>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct DocumentPayload {
    path: Option<String>,
    title: String,
    content: String,
    word_count: usize,
    reading_minutes: usize,
    is_sample: bool,
}

fn compute_stats(text: &str) -> (usize, usize) {
    let mut cjk = 0usize;
    let mut non_cjk = String::with_capacity(text.len());
    for ch in text.chars() {
        let code = ch as u32;
        if (0x4E00..=0x9FFF).contains(&code) || (0x3400..=0x4DBF).contains(&code) {
            cjk += 1;
            non_cjk.push(' ');
        } else {
            non_cjk.push(ch);
        }
    }
    let latin_words = non_cjk.split_whitespace().count();
    let total = cjk + latin_words;
    let minutes = ((total as f64) / 240.0).ceil().max(1.0) as usize;
    (total, minutes)
}

fn start_file_watcher(app: &AppHandle, state: &State<'_, AppState>, target_path: PathBuf) {
    let mut guard = state.watcher.lock().unwrap();
    *guard = None;

    let watch_dir = match target_path.parent() {
        Some(dir) => dir.to_path_buf(),
        None => return,
    };
    let target_name = target_path.file_name().map(|n| n.to_os_string());
    let target_str = target_path.to_string_lossy().to_string();
    let app_handle = app.clone();
    let last_emit = Arc::new(Mutex::new(Instant::now() - Duration::from_secs(5)));

    let watcher_res = RecommendedWatcher::new(
        move |res: notify::Result<notify::Event>| {
            let Ok(event) = res else { return };
            match event.kind {
                EventKind::Modify(_) | EventKind::Create(_) => {}
                _ => return,
            }
            let matches_file = event
                .paths
                .iter()
                .any(|p| p.file_name().map(|n| n.to_os_string()) == target_name);
            if !matches_file {
                return;
            }
            let mut last = last_emit.lock().unwrap();
            if last.elapsed() < Duration::from_millis(180) {
                return;
            }
            *last = Instant::now();
            let _ = app_handle.emit("file-changed", target_str.clone());
        },
        Config::default(),
    );

    if let Ok(mut watcher) = watcher_res {
        if watcher.watch(&watch_dir, RecursiveMode::NonRecursive).is_ok() {
            *guard = Some(watcher);
        }
    }
}

#[tauri::command]
fn get_initial_file(state: State<'_, AppState>) -> Option<String> {
    state.initial_file.lock().unwrap().take()
}

#[tauri::command]
fn get_sample_markdown(state: State<'_, AppState>) -> DocumentPayload {
    *state.current_dir.lock().unwrap() = None;
    *state.watcher.lock().unwrap() = None;
    let (word_count, reading_minutes) = compute_stats(SAMPLE_MD);
    DocumentPayload {
        path: None,
        title: "Sample.md".to_string(),
        content: SAMPLE_MD.to_string(),
        word_count,
        reading_minutes,
        is_sample: true,
    }
}

#[tauri::command]
fn read_markdown_file(
    app: AppHandle,
    state: State<'_, AppState>,
    path: String,
) -> Result<DocumentPayload, String> {
    let raw_path = PathBuf::from(&path);
    let canonical = fs::canonicalize(&raw_path).unwrap_or(raw_path);
    let bytes = fs::read(&canonical).map_err(|e| format!("Failed to read file: {e}"))?;
    let content = String::from_utf8(bytes)
        .unwrap_or_else(|e| String::from_utf8_lossy(e.as_bytes()).into_owned());

    if let Some(parent) = canonical.parent() {
        *state.current_dir.lock().unwrap() = Some(parent.to_path_buf());
    }
    start_file_watcher(&app, &state, canonical.clone());

    let title = canonical
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("MarkRead")
        .to_string();
    let (word_count, reading_minutes) = compute_stats(&content);

    Ok(DocumentPayload {
        path: Some(canonical.to_string_lossy().to_string()),
        title,
        content,
        word_count,
        reading_minutes,
        is_sample: false,
    })
}

#[tauri::command]
fn resolve_relative_markdown(
    state: State<'_, AppState>,
    relative_path: String,
) -> Option<String> {
    let base = state.current_dir.lock().unwrap().clone()?;
    let target = base.join(relative_path);
    let canonical = fs::canonicalize(target).ok()?;
    if canonical.is_file() {
        Some(canonical.to_string_lossy().to_string())
    } else {
        None
    }
}

#[tauri::command]
async fn pick_open_file(app: AppHandle) -> Option<String> {
    let picked = app
        .dialog()
        .file()
        .add_filter(
            "Markdown",
            &["md", "markdown", "mdown", "mkd", "mkdn", "txt"],
        )
        .blocking_pick_file();
    picked.and_then(|fp| fp.into_path().ok()).map(|p| p.to_string_lossy().to_string())
}

#[tauri::command]
async fn pick_save_html_file(app: AppHandle, default_name: String) -> Option<String> {
    let picked = app
        .dialog()
        .file()
        .set_file_name(&default_name)
        .add_filter("HTML Document", &["html"])
        .blocking_save_file();
    picked.and_then(|fp| fp.into_path().ok()).map(|p| p.to_string_lossy().to_string())
}

#[tauri::command]
fn save_text_file(path: String, content: String) -> Result<(), String> {
    fs::write(Path::new(&path), content.as_bytes()).map_err(|e| format!("Failed to save file: {e}"))
}

#[tauri::command]
fn open_external_url(app: AppHandle, url: String) -> Result<(), String> {
    app.opener()
        .open_url(url, None::<&str>)
        .map_err(|e| e.to_string())
}

#[tauri::command]
fn reveal_in_explorer(path: String) -> Result<(), String> {
    #[cfg(target_os = "windows")]
    {
        std::process::Command::new("explorer")
            .arg(format!("/select,{}", path))
            .spawn()
            .map_err(|e| e.to_string())?;
    }
    #[cfg(target_os = "macos")]
    {
        std::process::Command::new("open")
            .args(["-R", &path])
            .spawn()
            .map_err(|e| e.to_string())?;
    }
    #[cfg(all(not(target_os = "windows"), not(target_os = "macos")))]
    {
        let _ = path;
    }
    Ok(())
}

#[tauri::command]
fn set_window_title(window: tauri::Window, title: String) -> Result<(), String> {
    window.set_title(&title).map_err(|e| e.to_string())
}

fn find_initial_cli_file() -> Option<String> {
    for arg in std::env::args().skip(1) {
        if arg.starts_with('-') {
            continue;
        }
        let path = PathBuf::from(&arg);
        if path.is_file() {
            let resolved = fs::canonicalize(&path).unwrap_or(path);
            return Some(resolved.to_string_lossy().to_string());
        }
    }
    None
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let current_dir = Arc::new(Mutex::new(None::<PathBuf>));
    let protocol_dir = Arc::clone(&current_dir);

    let app_state = AppState {
        current_dir,
        watcher: Mutex::new(None),
        initial_file: Mutex::new(find_initial_cli_file()),
    };

    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_opener::init())
        .manage(app_state)
        .register_uri_scheme_protocol("markread-local", move |_ctx, request| {
            let raw_path = request.uri().path();
            let stripped = raw_path
                .strip_prefix("/file/")
                .or_else(|| raw_path.strip_prefix('/'))
                .unwrap_or(raw_path);
            let decoded = percent_decode_str(stripped).decode_utf8_lossy().to_string();

            let target = {
                let candidate = PathBuf::from(&decoded);
                if candidate.is_absolute() && candidate.is_file() {
                    Some(candidate)
                } else {
                    protocol_dir
                        .lock()
                        .unwrap()
                        .as_ref()
                        .map(|base| base.join(&decoded))
                }
            };

            if let Some(file_path) = target {
                if let Ok(bytes) = fs::read(&file_path) {
                    let mime = mime_guess::from_path(&file_path)
                        .first_or_octet_stream()
                        .to_string();
                    return tauri::http::Response::builder()
                        .status(200)
                        .header("Content-Type", mime)
                        .header("Access-Control-Allow-Origin", "*")
                        .body(bytes)
                        .unwrap();
                }
            }

            tauri::http::Response::builder()
                .status(404)
                .header("Content-Type", "text/plain")
                .body(b"Not Found".to_vec())
                .unwrap()
        })
        .invoke_handler(tauri::generate_handler![
            get_initial_file,
            get_sample_markdown,
            read_markdown_file,
            resolve_relative_markdown,
            pick_open_file,
            pick_save_html_file,
            save_text_file,
            open_external_url,
            reveal_in_explorer,
            set_window_title,
        ])
        .setup(|app| {
            if let Some(window) = app.get_webview_window("main") {
                let _ = window.set_title("MarkRead");
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running MarkRead");
}
