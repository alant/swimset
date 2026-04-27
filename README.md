# Swim Set Timer - Garmin Connect IQ App

A premium, localized Garmin watch app for interval swim training. This app features a configurable interval timer, pool size settings, multiple proximity alarms, and a specialized "Swim Mode" input lock.

> [!IMPORTANT]
> **Hardware Testing**: This application has been physically tested **only on the Garmin Descent G2**. While it is compatible with many other devices (Fenix, Venu, Forerunner), user experience may vary on those models.

## Features

- **Multi-Language Support**: Fully localized for English, Chinese (Simplified & Traditional), and Japanese.
- **Swim Mode (Touch Lock)**: Automatically disables the touchscreen while the timer is running to prevent accidental water-induced taps.
- **Physical Button Support**: The hardware START/STOP button remains functional to pause/resume workouts even when the screen is locked.
- **Configurable Pool Size**: 25-50 yards or meters.
- **Flexible Set Timing**: Configure minutes and seconds for your intervals.
- **Smart Alarms**:
  - Set completion vibration (distinct double pulse).
  - Warning alarm at configurable time (e.g., 5 seconds before set ends).
  - 20-second and 10-second countdown alerts.
- **Red Pause Ring**: A vibrant red outer ring appears when the timer is paused, making status clear at a glance.

## Installation & Setup

### 1. Requirements
- Garmin Connect IQ SDK 4.x or newer.
- A developer key (`developer_key`).

### 2. Build the App
Debug build:
```bash
monkeyc -o bin/swimset.prg -f monkey.jungle -y developer_key -d descentg2
```
Distribution build:
```bash
monkeyc -e -d descentg2 -f monkey.jungle -o bin/swimset.iq -y developer_key.der
```

### 3. Deploy to Device
1. Connect your watch to your computer.
2. Copy `bin/swimset.prg` to the watch's `/GARMIN/APPS` folder.

## Usage

### Controls
- **START/STOP Button**: Opens the **Options Menu** (Start, Pause, Resume, Save, Discard).
- **Touch Screen**: Works as normal while the timer is stopped or paused. Disabled during an active swim set.
- **BACK Button**: Returns to previous screens but is blocked during a set to prevent accidental exits.

### Configuration
Configure settings through the on-device **Settings** menu or via the Garmin Connect IQ mobile app.
- **Pool Size/Units**: Set your pool length.
- **Set Time**: The target time for each interval.
- **App Language**: Choose between Auto (System Default), English, Chinese, or Japanese.

## Project Structure

```
swimset/
├── manifest.xml              # Device compatibility and App ID
├── monkey.jungle             # Build instructions
├── resources/
│   ├── strings.xml           # Localized strings (Multi-language format)
│   ├── drawables.xml         # Image and icon definitions
│   ├── settings.xml          # App settings UI
│   └── launcher_icon.png     # Optimized 40x40 icon
└── source/
    ├── SwimSetApp.mc         # App entry and L() localization helper
    ├── SwimSetView.mc        # Main timer display and logic
    ├── SwimSetDelegate.mc    # "Swim Mode" input handling
    └── SettingsMenuDelegate.mc # Settings and menu management
```

## License

This project is open-source under the MIT License.
