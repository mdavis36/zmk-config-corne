# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Project Overview

ZMK firmware configuration for a Corne (crkbd) split keyboard with nice!nano v2
controllers and nice!view displays. This is a user config repo — it does not
contain ZMK source code, only personal keymap/config that gets built via GitHub
Actions using the upstream ZMK build system.

## Build System

Firmware is built automatically by GitHub Actions on push/PR. The workflow at
`.github/workflows/build.yml` delegates to
`zmkfirmware/zmk/.github/workflows/build-user-config.yml@main`. There is no
local build — pushing to the repo triggers CI which produces firmware `.uf2`
artifacts.

The `build.yaml` defines the build matrix: two halves (corne_left, corne_right)
on nice_nano_v2 with nice_view display adapters.

## Key Files

- **`config/corne.keymap`** — The keymap definition (devicetree overlay format).
  This is the primary file you'll edit. Contains all layers, behaviors, and key
  bindings.
- **`config/corne.conf`** — Kconfig options (display enabled, BT TX power
  boost).
- **`config/west.yml`** — West manifest pinning ZMK to `v0.3.0`.
- **`build.yaml`** — GitHub Actions build matrix (board/shield combos).

## Keymap Architecture

The keymap uses ZMK's devicetree syntax. 5 layers (0-4):

| Layer | Name          | Purpose                                                                                                       |
| ----- | ------------- | ------------------------------------------------------------------------------------------------------------- |
| 0     | default_layer | QWERTY with home-row mods (CTRL/ALT/GUI on S/D/F and J/K/L)                                                   |
| 1     | lower_layer   | Symbols and number pad (activated by holding A)                                                               |
| 2     | raise_layer   | F-keys, navigation arrows, volume, page up/down (activated by holding semicolon, or tap-dance on right thumb) |
| 3     | layer_3       | Bluetooth management, output toggle, ext power (activated by sticky-layer on left thumb)                      |
| 4     | layer_4       | Mouse movement and clicks (activated by double-tap on td_multi)                                               |

Key conventions in this keymap:

- Outermost columns are `&none` (Corne 6-col layout ignoring the outer keys)
- Home-row mods use `&mt` with `tap-preferred` flavor
- `&lt` (layer-tap) uses `hold-preferred` flavor
- Custom `Shift_MT` hold-tap behavior for shift on Z and / keys
- `td_multi` tap-dance: single tap = layer-tap to layer 2 + Enter, double tap =
  toggle to layer 4 (exit via `&to 0`)
- Left thumb center key: hold = Hyper (Shift+Alt+Ctrl+Cmd), tap = Space

## ZMK Keymap Syntax Notes

- Bindings use `&behavior PARAM1 PARAM2` format (e.g., `&kp A`,
  `&mt LEFT_GUI F`, `&bt BT_SEL 0`)
- `&kp` = key press, `&mt` = mod-tap, `&lt` = layer-tap, `&sl` = sticky layer,
  `&to` = switch layer
- `&none` = no action, `&trans` = transparent (falls through to lower layer)
- Key codes are from ZMK includes (e.g., `LEFT_GUI`, `NUMBER_4`, `C_VOLUME_UP`)
