#!/bin/bash
# Double-click in Finder to run the restore automatically at every login.
cd "$(dirname "$0")"
./restore.sh install
status=$?
if [[ $status -eq 0 ]]; then
  echo
  echo "Login restore is on. After you log in, the last snapshot will be applied."
else
  echo
  echo "Could not enable login restore (exit $status)."
fi
echo
read -r -p "Press Return to close."
exit $status
