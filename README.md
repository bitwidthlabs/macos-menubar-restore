# macos-menubar-restore

Save a macOS (created for 26.6.2 (25G83)) menu bar and Control Center layout, then apply it on demand or at login.

On some versions of macOS, customizations may not survive a restart. This copies the preference files into a local snapshot, writes them back, and reloads Control Center.

Optional: if [Stats](https://github.com/exelban/stats) is installed, its widget settings are included in the snapshot.

## Use

Double-click these in this folder:

- **Save Snapshot.command** — store the current menu bar and Control Center
- **Restore Now.command** — apply that snapshot immediately
- **Enable Login Restore.command** — apply the snapshot automatically at every login

To stop login restore:

```bash
./restore.sh uninstall
```

Snapshots live in `snapshots/` (not committed). A log is written to `restore.log`.

## Command line

```bash
./restore.sh save
./restore.sh restore
./restore.sh install
./restore.sh uninstall
```

`restore --login` waits for Control Center to start, then applies the snapshot. That is what the login agent runs.
