#!/bin/bash
# Double-click in Finder to apply the saved menu bar and Control Center snapshot now.
cd "$(dirname "$0")"
./restore.sh restore
status=$?
if [[ $status -eq 0 ]]; then
  echo
  echo "Restored. The menu bar and Control Center should match the last snapshot."
else
  echo
  echo "Restore failed (exit $status)."
fi
echo
read -r -p "Press Return to close."
exit $status
