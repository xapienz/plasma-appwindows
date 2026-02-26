#!/usr/bin/env bash
# Install the App Windows plasmoid into the current user's KDE Plasma session.
# Run from the directory that contains this script.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ID="org.kde.plasma.appwindows"

echo "Installing ${PLUGIN_ID}..."

# Remove a previous installation if present
if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -q "${PLUGIN_ID}"; then
    kpackagetool6 --type Plasma/Applet --remove "${PLUGIN_ID}"
fi

kpackagetool6 --type Plasma/Applet --install "${SCRIPT_DIR}"

echo "Done. Right-click your Plasma panel → 'Add Widgets' → search for 'App Windows'."
echo "You may need to restart plasmashell: kquitapp6 plasmashell && kstart plasmashell"
