# Tailscale Serve LaunchAgent

Persists `tailscale serve --bg http://127.0.0.1:18789` across reboots on the Mac mini.

## Install

```bash
# Ensure log directory exists
mkdir -p /tmp/openclaw

# Copy plist to LaunchAgents
cp scripts/ai.openclaw.tailscale-serve.plist ~/Library/LaunchAgents/

# Load it (starts immediately due to RunAtLoad)
launchctl load ~/Library/LaunchAgents/ai.openclaw.tailscale-serve.plist
```

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/ai.openclaw.tailscale-serve.plist
rm ~/Library/LaunchAgents/ai.openclaw.tailscale-serve.plist
```

## Notes

- `/tmp/openclaw` is cleared on reboot — the plist will still work, but the first run's log dir needs to exist. Consider adding a wrapper script if this matters, or use `/usr/local/var/log/openclaw/` instead.
- `KeepAlive` is false because `tailscale serve --bg` daemonizes itself; launchd just needs to kick it off once.
- Uses the App Store Tailscale CLI at `/Applications/Tailscale.app/Contents/MacOS/Tailscale`.
