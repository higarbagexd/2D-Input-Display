# 2D Input Display (Beta)


---

## Features

- **Real Time Input Display:** Have an overlay for controller buttons, analog sticks, keyboard keys, and mouse movements/buttons live on screen.
- **Input Mapping & Remapping:** Remap controller buttons to other actions, map keyboard keys to controller inputs, or rebind inputs vice versa.
- **Multiple Preset Layouts:** Switch between different built-in overlay presets.
- **Customizable Overlay Window:** Frameless, transparent window that stays on top, with adjustable background visibility, custom title bar, and dynamic scaling.
- **Automatic Update Notifications:** Built-in checker that detects when a new release is available on GitHub and lets you jump straight to the download page.
- **Save/Load Configs:** Automatically loads saved mapping configurations on startup.
- **System Tray Support:** Please note that the app runs in the system tray so it doesn't clutter the taskbar, and that you can open the Control Panel or quit directly from the tray icon.
---

## Things used

- **C++** Core backend logic, input routing, and bridge between the input and QML.
- **Qt 6.10 & QML:** For the UI and networking.
- **SDL3:** Controller state polling and device handling.
- **Windows System APIs:** Low-level system hooks for global keyboard and mouse tracking.

---

## Beta Release Notice

This application is currently in **Beta**. You may run into minor bugs, visual glitches, or potentially missing features.

If you encounter any bugs or have feedback, please open an issue under the **Issues** tab.

---

## Getting Started

### Download for Windows
1. Download `InputOverlay-v0.1.0-beta.zip` from the [Latest Release](https://github.com/higarbagexd/2D-Input-Display/releases/latest) page.
2. Extract the `.zip` folder and run `appInputOverlay.exe`.

   - This app will not work on Linux and MacOS. I will attempt to add support for them later on.

---

## Roadmap & Planned Features

- **Preset Color & Style Customization:** An edit button on each preset allowing users to customize key/button colors, border styles, and active state highlights via dynamic QML properties.
- **Multi-Player Overlay Support:** Run multiple overlays simultaneously with colored player indicators (e.g., Red dot for P1, Blue dot for P2) that can be toggled in settings.
- **Dynamic Controller Chooser:** Auto-detect connected gamepads and select/reassign which physical device controls which player slot.
- **OBS / Recording Mode:** Hide the desktop overlay from your screen while keeping it active as a clean source inside OBS or recording software.
- Comments and Code Documentation. This is what I will focus on the most before creating anything else. I will create documentation for all classes and comments.

---

## Building from Source

### Option 1: Using Qt Creator (Easiest)
1. Install Qt 6.10 with Qt Quick and Qt Network modules.
2. Open `CMakeLists.txt` in Qt Creator.
3. Select your C++ compiler (MSVC or MinGW) and click **Build**.

### Option 2: Command Line (CMake)
```bash
git clone [https://github.com/higarbagexd/2D-Input-Display.git](https://github.com/higarbagexd/2D-Input-Display.git)
cd 2D-Input-Display
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```
## Credits

  2D-Input-Display
 
  Copyright (C) 2026 higarbagexd
 
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.


 - Minimalist Keyboard and mouse preset inspired by https://obsproject.com/forum/resources/input-overlay.552/

