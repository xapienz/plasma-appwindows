# App Windows

A KDE Plasma 6 applet that shows the windows of the **currently active
application**, and switches between them with a click.

Unlike the standard Task Manager, which lists every window on the panel, this
applet shows only the windows belonging to whichever application currently has
focus — and follows along as you switch applications. It is meant for a small,
always-relevant window switcher rather than a full task bar.

## Features

- Lists all windows of the active application, on the current activity and
  across all virtual desktops
- Highlights the focused window, dims minimized ones, and shows windows
  demanding attention in bold
- Click a window to raise it; click the focused window to minimize it
- Configurable alignment and single-window behaviour

## Requirements

KDE Plasma **6.0 or later** (`X-Plasma-API-Minimum-Version: 6.0`).

## Installation

### NixOS (flake)

Add the input and install the package:

```nix
# flake.nix
inputs.plasma-appwindows.url = "github:xapienz/plasma-appwindows";
inputs.plasma-appwindows.inputs.nixpkgs.follows = "nixpkgs";

# configuration.nix
environment.systemPackages = [
  inputs.plasma-appwindows.packages.x86_64-linux.default
];
```

An `overlays.default` is also exported, if you prefer adding
`pkgs.plasma-appwindows` to your package set.

To try it without installing:

```sh
nix build github:xapienz/plasma-appwindows
```

### Other distributions

```sh
git clone https://github.com/xapienz/plasma-appwindows
cd plasma-appwindows
./install.sh
```

This runs `kpackagetool6 --install`, placing the applet in
`~/.local/share/plasma/plasmoids/`.

### Adding it to a panel

Right-click your panel → **Add Widgets…** → search for **App Windows**.

If it does not appear, restart plasmashell so it rescans for new applets:

```sh
kquitapp6 plasmashell && kstart plasmashell
```

> **Note for Nix users:** a copy previously installed via `install.sh` lives in
> `~/.local/share` and takes precedence over the packaged one. Remove it with
> `kpackagetool6 --type Plasma/Applet --remove org.kde.plasma.appwindows`.

## Configuration

Right-click the applet → **Configure App Windows…**

| Setting | Options | Default |
| --- | --- | --- |
| **Button alignment** | Left, Right | Left |
| **When one window is available** | Show icon and text, Show icon only, Do not show | Show icon and text |

The second setting keeps the panel quiet for single-window applications: it can
fall back to just an icon, or hide the applet entirely until a second window
exists.

## License

GPL-2.0-or-later.
