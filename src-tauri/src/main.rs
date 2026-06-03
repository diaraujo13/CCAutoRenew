#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use std::process::Command;
use tauri::{
    CustomMenuItem, Manager, SystemTray, SystemTrayEvent, SystemTrayMenu, SystemTrayMenuItem,
};

#[derive(Serialize, Deserialize, Debug)]
pub struct DaemonStatus {
    pub running: bool,
    pub pid: Option<i32>,
    pub start_time: Option<String>,
    pub stop_time: Option<String>,
    pub custom_message: Option<String>,
    pub ccusage_enabled: bool,
    pub minutes_until_reset: Option<i32>,
    pub renewal_progress: Option<i32>,
    pub next_renewal_time: Option<String>,
    pub last_activity: Option<String>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct DaemonLogs {
    pub logs: Vec<String>,
}

fn get_home_dir() -> PathBuf {
    dirs::home_dir().unwrap_or_else(|| PathBuf::from("."))
}

fn get_pid_file() -> PathBuf {
    get_home_dir().join(".claude-auto-renew-daemon.pid")
}

fn get_log_file() -> PathBuf {
    get_home_dir().join(".claude-auto-renew-daemon.log")
}

fn is_daemon_running() -> bool {
    let pid_file = get_pid_file();
    if let Ok(pid_str) = fs::read_to_string(&pid_file) {
        if let Ok(pid) = pid_str.trim().parse::<i32>() {
            // Try to send signal 0 to check if process exists
            let status = Command::new("kill").arg("-0").arg(pid.to_string()).status();
            return status.is_ok() && status.unwrap().success();
        }
    }
    false
}

fn get_daemon_pid() -> Option<i32> {
    let pid_file = get_pid_file();
    if let Ok(pid_str) = fs::read_to_string(&pid_file) {
        pid_str.trim().parse::<i32>().ok()
    } else {
        None
    }
}

fn read_status_file(filename: &str) -> Option<String> {
    let home = get_home_dir();
    if let Ok(content) = fs::read_to_string(home.join(filename)) {
        Some(content.trim().to_string())
    } else {
        None
    }
}

#[tauri::command]
fn get_daemon_status() -> DaemonStatus {
    let running = is_daemon_running();
    let pid = if running { get_daemon_pid() } else { None };

    DaemonStatus {
        running,
        pid,
        start_time: read_status_file(".claude-auto-renew-start-time"),
        stop_time: read_status_file(".claude-auto-renew-stop-time"),
        custom_message: read_status_file(".claude-auto-renew-message"),
        ccusage_enabled: true,          // TODO: read from config
        minutes_until_reset: Some(120), // TODO: calculate from logs
        renewal_progress: Some(40),
        next_renewal_time: Some("18:53".to_string()), // TODO: calculate
        last_activity: read_status_file(".claude-last-activity"),
    }
}

#[tauri::command]
fn start_daemon() -> Result<String, String> {
    let script_path = std::env::current_dir()
        .map_err(|e| format!("Error getting current dir: {}", e))?
        .join("manage-launchd.sh");

    let output = Command::new("bash")
        .arg(&script_path)
        .arg("start")
        .output()
        .map_err(|e| format!("Failed to start daemon: {}", e))?;

    if output.status.success() {
        Ok("Daemon started successfully".to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).to_string())
    }
}

#[tauri::command]
fn stop_daemon() -> Result<String, String> {
    let script_path = std::env::current_dir()
        .map_err(|e| format!("Error getting current dir: {}", e))?
        .join("manage-launchd.sh");

    let output = Command::new("bash")
        .arg(&script_path)
        .arg("stop")
        .output()
        .map_err(|e| format!("Failed to stop daemon: {}", e))?;

    if output.status.success() {
        Ok("Daemon stopped successfully".to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).to_string())
    }
}

#[tauri::command]
fn restart_daemon() -> Result<String, String> {
    let script_path = std::env::current_dir()
        .map_err(|e| format!("Error getting current dir: {}", e))?
        .join("manage-launchd.sh");

    let output = Command::new("bash")
        .arg(&script_path)
        .arg("restart")
        .output()
        .map_err(|e| format!("Failed to restart daemon: {}", e))?;

    if output.status.success() {
        Ok("Daemon restarted successfully".to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).to_string())
    }
}

#[tauri::command]
fn get_daemon_logs(lines: usize) -> Result<Vec<String>, String> {
    let log_file = get_log_file();

    match fs::read_to_string(&log_file) {
        Ok(content) => {
            let log_lines: Vec<String> = content.lines().map(|s| s.to_string()).collect::<Vec<_>>();

            let start = if log_lines.len() > lines {
                log_lines.len() - lines
            } else {
                0
            };

            Ok(log_lines[start..].to_vec())
        }
        Err(_) => Ok(vec!["No logs available yet".to_string()]),
    }
}

#[tauri::command]
fn clear_daemon_logs() -> Result<String, String> {
    let log_file = get_log_file();
    fs::write(&log_file, "").map_err(|e| e.to_string())?;
    Ok("Logs cleared".to_string())
}

#[tauri::command]
fn save_settings(
    start_time: Option<String>,
    stop_time: Option<String>,
    custom_message: Option<String>,
) -> Result<String, String> {
    let home = get_home_dir();

    if let Some(time) = start_time {
        fs::write(home.join(".claude-auto-renew-start-time"), time).map_err(|e| e.to_string())?;
    }

    if let Some(time) = stop_time {
        fs::write(home.join(".claude-auto-renew-stop-time"), time).map_err(|e| e.to_string())?;
    }

    if let Some(msg) = custom_message {
        fs::write(home.join(".claude-auto-renew-message"), msg).map_err(|e| e.to_string())?;
    }

    Ok("Settings saved".to_string())
}

fn main() {
    let show = CustomMenuItem::new("show".to_string(), "Mostrar");
    let start = CustomMenuItem::new("start".to_string(), "Iniciar Daemon");
    let stop = CustomMenuItem::new("stop".to_string(), "Parar Daemon");
    let quit = CustomMenuItem::new("quit".to_string(), "Sair");

    let tray_menu = SystemTrayMenu::new()
        .add_item(show)
        .add_item(start)
        .add_item(stop)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(quit);

    let system_tray = SystemTray::new().with_menu(tray_menu);

    tauri::Builder::default()
        .system_tray(system_tray)
        .on_system_tray_event(|app, event| match event {
            SystemTrayEvent::LeftClick { .. } => {
                let window = app.get_window("main");
                if let Some(window) = window {
                    if window.is_visible().unwrap_or(false) {
                        let _ = window.hide();
                    } else {
                        let _ = window.show();
                        let _ = window.set_focus();
                    }
                }
            }
            SystemTrayEvent::MenuItemClick { id, .. } => match id.as_str() {
                "show" => {
                    if let Some(window) = app.get_window("main") {
                        let _ = window.show();
                        let _ = window.set_focus();
                    }
                }
                "start" => {
                    if let Some(window) = app.get_window("main") {
                        let _ = window.emit("tray_action", "start_daemon");
                    }
                }
                "stop" => {
                    if let Some(window) = app.get_window("main") {
                        let _ = window.emit("tray_action", "stop_daemon");
                    }
                }
                "quit" => {
                    std::process::exit(0);
                }
                _ => {}
            },
            _ => {}
        })
        .invoke_handler(tauri::generate_handler![
            get_daemon_status,
            start_daemon,
            stop_daemon,
            restart_daemon,
            get_daemon_logs,
            clear_daemon_logs,
            save_settings,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
