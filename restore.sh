#!/bin/bash
# Save and restore macOS menu bar + Control Center prefs, then reload
# the processes that read them.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SNAP="$ROOT/snapshots"
LOG="$ROOT/restore.log"
PREFS="$HOME/Library/Preferences"
BYHOST="$PREFS/ByHost"
GROUP_CC="$HOME/Library/Group Containers/group.com.apple.controlcenter"
HOST="$(ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/{print $4}')"

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG"
}

copy_if_exists() {
  local src="$1"
  local dest="$2"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    return 0
  fi
  return 1
}

save() {
  mkdir -p "$SNAP/ByHost" "$SNAP/group.com.apple.controlcenter"

  copy_if_exists "$PREFS/com.apple.controlcenter.plist" \
    "$SNAP/com.apple.controlcenter.plist" || true
  copy_if_exists "$BYHOST/com.apple.controlcenter.${HOST}.plist" \
    "$SNAP/ByHost/com.apple.controlcenter.HOST.plist" || true
  copy_if_exists "$BYHOST/com.apple.controlcenter.bentoboxes.${HOST}.plist" \
    "$SNAP/ByHost/com.apple.controlcenter.bentoboxes.HOST.plist" || true
  copy_if_exists "$BYHOST/com.apple.controlcenter.displayablemenuextras.${HOST}.plist" \
    "$SNAP/ByHost/com.apple.controlcenter.displayablemenuextras.HOST.plist" || true
  copy_if_exists "$PREFS/com.apple.systemuiserver.plist" \
    "$SNAP/com.apple.systemuiserver.plist" || true

  defaults export eu.exelban.Stats "$SNAP/eu.exelban.Stats.plist" 2>/dev/null || true

  if [[ -d "$GROUP_CC" ]]; then
    mkdir -p "$SNAP/group.com.apple.controlcenter"
    rsync -a --delete "$GROUP_CC/" "$SNAP/group.com.apple.controlcenter/" 2>/dev/null || true
  fi

  log "saved snapshot to $SNAP"
}

wait_for_session() {
  local waited=0
  while [[ "$waited" -lt 60 ]]; do
    if pgrep -x ControlCenter >/dev/null 2>&1; then
      break
    fi
    sleep 1
    waited=$((waited + 1))
  done
  # Let Control Center finish writing defaults before we overwrite them.
  sleep 15
}

restore() {
  if [[ ! -d "$SNAP" ]]; then
    log "no snapshot at $SNAP — run: $ROOT/restore.sh save"
    exit 1
  fi

  if [[ "${1:-}" == "--login" ]]; then
    wait_for_session
  fi

  killall ControlCenter 2>/dev/null || true
  sleep 1

  copy_if_exists "$SNAP/com.apple.controlcenter.plist" \
    "$PREFS/com.apple.controlcenter.plist" || true
  copy_if_exists "$SNAP/ByHost/com.apple.controlcenter.HOST.plist" \
    "$BYHOST/com.apple.controlcenter.${HOST}.plist" || true
  copy_if_exists "$SNAP/ByHost/com.apple.controlcenter.bentoboxes.HOST.plist" \
    "$BYHOST/com.apple.controlcenter.bentoboxes.${HOST}.plist" || true
  copy_if_exists "$SNAP/ByHost/com.apple.controlcenter.displayablemenuextras.HOST.plist" \
    "$BYHOST/com.apple.controlcenter.displayablemenuextras.${HOST}.plist" || true
  copy_if_exists "$SNAP/com.apple.systemuiserver.plist" \
    "$PREFS/com.apple.systemuiserver.plist" || true

  if [[ -f "$SNAP/eu.exelban.Stats.plist" ]]; then
    defaults import eu.exelban.Stats "$SNAP/eu.exelban.Stats.plist" 2>/dev/null || true
  fi

  if [[ -d "$SNAP/group.com.apple.controlcenter" ]]; then
    mkdir -p "$GROUP_CC"
    rsync -a "$SNAP/group.com.apple.controlcenter/" "$GROUP_CC/" 2>/dev/null || true
  fi

  killall cfprefsd 2>/dev/null || true
  sleep 1
  open /System/Library/CoreServices/ControlCenter.app >/dev/null 2>&1 || true
  open -ga Stats >/dev/null 2>&1 || true

  log "restored snapshot and reloaded Control Center"
}

install_agent() {
  local dest="$HOME/Library/LaunchAgents/local.menubar-restore.plist"
  mkdir -p "$HOME/Library/LaunchAgents"
  sed "s|__ROOT__|$ROOT|g" "$ROOT/launchd/local.menubar-restore.plist" > "$dest"
  launchctl bootout "gui/$(id -u)/local.menubar-restore" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$dest"
  launchctl enable "gui/$(id -u)/local.menubar-restore"
  log "installed login agent $dest"
}

uninstall_agent() {
  local dest="$HOME/Library/LaunchAgents/local.menubar-restore.plist"
  launchctl bootout "gui/$(id -u)/local.menubar-restore" 2>/dev/null || true
  rm -f "$dest"
  log "removed login agent"
}

usage() {
  cat <<EOF
usage: $0 save | restore [--login] | install | uninstall

  save       snapshot current menu bar / Control Center prefs
  restore    write snapshot back and reload Control Center
  install    snapshot (if needed) and run restore at every login
  uninstall  stop running restore at login
EOF
}

cmd="${1:-}"
shift || true
case "$cmd" in
  save) save ;;
  restore) restore "${1:-}" ;;
  install)
    if [[ ! -d "$SNAP" ]]; then
      save
    fi
    install_agent
    ;;
  uninstall) uninstall_agent ;;
  *) usage; exit 1 ;;
esac
