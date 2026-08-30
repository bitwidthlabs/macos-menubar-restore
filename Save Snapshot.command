#!/bin/bash
# Double-click in Finder to snapshot the current menu bar and Control Center.
cd "$(dirname "$0")"
./restore.sh save
status=$?
if [[ $status -eq 0 ]]; then
  echo
  echo "Snapshot saved. Double-click Restore Now.command to apply it, or Enable Login Restore.command to apply it at login."
else
  echo
  echo "Save failed (exit $status)."
fi
echo
read -r -p "Press Return to close."
exit $status
