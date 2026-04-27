# Swim Set Timer - Garmin Connect IQ App

A Garmin watch app for interval swim training with configurable sets, pool sizes, and multiple alarms.

## Features

- **Configurable pool size**: 25-50 yards or meters
- **Flexible set timing**: Configure minutes and seconds (default 1:50)
- **Multiple sets**: Set how many intervals to complete (default 8)
- **Distance display**: Automatically calculates distance (pool size × 2)
- **Smart alarms**:
  - Set completion vibration (double pulse)
  - Warning alarm at configurable time (default 1:20 into set)
  - 20-second countdown alarm
  - 10-second countdown alarm

## Setup Instructions

### 1. Install Garmin Connect IQ SDK

**Option A: Using VS Code (Recommended)**
1. Install [Visual Studio Code](https://code.visualstudio.com/)
2. Install the "Monkey C" extension from the VS Code marketplace
3. Open Command Palette (Cmd+Shift+P on Mac, Ctrl+Shift+P on Windows)
4. Run "Monkey C: Verify Installation" - this will guide you through SDK setup

**Option B: Manual Installation**
1. Download the SDK from [developer.garmin.com/connect-iq/sdk](https://developer.garmin.com/connect-iq/sdk/)
2. Extract and add the `bin` directory to your PATH
3. Set environment variable: `export MB_HOME=/path/to/sdk`

### 2. Generate Developer Key

```bash
openssl genrsa -out developer_key 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key -out developer_key.der -nocrypt
```

### 3. Build the App

```bash
monkeyc -o swimset.prg -f monkey.jungle -y developer_key.der
```

### 4. Test in Simulator

```bash
connectiq
```

Then load `swimset.prg` in the simulator and select a compatible device (Fenix 7, Vivoactive 4, Venu 2, etc.)

### 5. Deploy to Device

**Via Garmin Express:**
1. Connect your watch to your computer
2. Copy `swimset.prg` to the watch's `GARMIN/APPS` folder

**Via Connect IQ Mobile App:**
1. Build and sign the app
2. Use the Connect IQ app to sideload

## Usage

### Controls
- **Select button**: Start timer
- **Back button**: Stop timer  
- **Menu button**: Reset timer

### Configuration

Configure settings through:
- Garmin Connect IQ mobile app
- Garmin Express desktop app
- Connect IQ Store (if published)

**Available Settings:**
- Pool Size: 25-50 (yards or meters)
- Pool Unit: Yards or Meters
- Set Time: Minutes (0-5) and Seconds (0-59)
- Number of Sets: 1-50
- Warning Time: 10-60 seconds into the set
- Enable/Disable 20-second alarm
- Enable/Disable 10-second alarm

## Display

The watch shows:
- Current set / total sets
- Time remaining in current set (MM:SS)
- Distance for current set (e.g., "50yds")
- Status (Running/Stopped)

## Alarm Patterns

- **Set completion**: Double vibration (300ms, pause, 300ms)
- **Warning/countdown alarms**: Single vibration (200ms)

## Compatible Devices

Tested on devices with Connect IQ 3.2.0+:
- Fenix 7 / 7S / 7X
- Fenix 6 / 6S / 6X Pro
- Vivoactive 4 / 4S
- Venu 2 / 2S / 2 Plus

## Project Structure

```
swimset/
├── manifest.xml              # App metadata and device compatibility
├── monkey.jungle             # Build configuration
├── resources/
│   ├── strings.xml          # UI strings
│   ├── properties.xml       # Default settings
│   └── settings.xml         # Settings configuration
└── source/
    ├── SwimSetApp.mc        # Main app entry point
    ├── SwimSetView.mc       # UI and timer logic
    └── SwimSetDelegate.mc   # Input handling
```

## Development

To modify the app:
1. Edit source files in `source/` directory
2. Rebuild with `monkeyc` command
3. Test in simulator or on device

## License

MIT
