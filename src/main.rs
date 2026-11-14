use std::time::Duration;
use libcec::{
    callbacks::channel,
    enums::{
        LogicalAddress,
        LogLevel,
        UserControlCode
    },
    CecEvent,
    Connection,
    ConnectionBuilder,
};
use mouse_keyboard_input::{
    VirtualDevice,
    key_codes::*
};
use tracing::info;
use tracing_subscriber::fmt::format::FmtSpan;

fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_ansi(true)
        .with_span_events(FmtSpan::CLOSE)
        .init();

    for adapter in Connection::detect_adapters(true)? {
        info!("{adapter}");
    }

    let (handler, events) = channel();

    let _cec = ConnectionBuilder::new("HTPC")
        .hdmi_port(1)
        .base_device(LogicalAddress::PlaybackDevice1)
        .callbacks(handler)
        .open(None, Duration::from_secs(10))?;

    let mut device = VirtualDevice::default().unwrap();

    for event in &events {
        match event {
            CecEvent::KeyPress(key) => {
                info!("{key:?}");
                if key.duration.is_zero() {
                    let key_simulate = match key.keycode {
                        UserControlCode::Up => Some(KEY_UP),
                        UserControlCode::Down => Some(KEY_DOWN),
                        UserControlCode::Left => Some(KEY_LEFT),
                        UserControlCode::Right => Some(KEY_RIGHT),
                        UserControlCode::Select => Some(KEY_ENTER),
                        UserControlCode::Exit => Some(KEY_ESC),
                        UserControlCode::SubPicture => Some(KEY_J),  // next subtitle track
                        UserControlCode::Pause => Some(KEY_K),  // next audio track
                        UserControlCode::Record => Some(KEY_S),  // screenshot
                        UserControlCode::Play => Some(KEY_PLAY),
                        UserControlCode::Rewind => Some(KEY_PREVIOUSSONG),
                        UserControlCode::FastForward => Some(KEY_NEXTSONG),
                        _ => None,
                    };
                    if let Some(key_simulate) = key_simulate {
                        let _ = device.click(key_simulate);
                    }
                }
            },
            CecEvent::Command(command) => {
                info!("{command:?}");
            },
            CecEvent::LogMessage(message) => {
                if message.level.raw() <= LogLevel::Notice.raw() {
                    info!("[{:?}] {}", message.level, message.message)
                }
            },
            CecEvent::Alert(alert) => info!("alert: {alert:?}"),
            CecEvent::SourceActivated { address, activated } => {
                info!("source {address:?} {}", if activated { "activated" } else { "deactivated" })
            },
            CecEvent::ConfigurationChanged(config) => info!("configuration changed: {config:?}"),
            CecEvent::MenuStateChanged(state) => info!("menu state changed: {state:?}"),
        }
    }

    Ok(())
}
