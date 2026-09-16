#!/bin/bash
# Double-click in Finder. Starts the backend (sibling guidy-backend-main folder) on port 8000.
cd "$(dirname "$0")" || exit 1
for d in ../guidy-backend-main ../guidy-backend; do
  [ -f "$d/run_backend.sh" ] && exec bash "$d/run_backend.sh"
done
echo "Backend folder not found next to this one (expected ../guidy-backend-main)."
read -r -p "Press Return to close..." _
