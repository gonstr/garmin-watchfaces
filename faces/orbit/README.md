# Orbit

Open the [browser mockup](mockup/index.html) to explore the design with illustrative data. The native Connect IQ prototype targets the fēnix 9 Pro 47 mm AMOLED and uses the watch's clock and time-format setting.

## Slate on Connect IQ

Slate is the default finish. Its single green hand travels once around the dial every 12 hours and advances continuously between the hour marks. In app settings, choose the featured complication and the left and right readouts independently. The defaults are daylight, steps, and Body Battery. You can also select heart rate, temperature, stress, calories, distance, barometric pressure, or training status.

The featured display uses a daylight arch, a progress bar, a sparkline, a temperature range with the current reading, or a text value. Steps use the watch's configured goal. Calories and distance use prototype goals of 2,400 kcal and 10 km. Daylight uses the cached weather location. Missing readings show a dash, and the browser's nightly HRV comparison is currently browser-only.

## Build the native prototype

Install Java and use [Garmin's Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/) to install the SDK and the fēnix 9 Pro 47 mm device profile. Put the SDK's `bin` directory on your PATH and create a developer key using the Monkey C extension's **Generate Developer Key** command. Keep the key outside Git.

From the repository root, build and launch the device simulator.

```sh
cd faces/orbit/connectiq
mkdir -p build
monkeyc -f monkey.jungle -d fenix9pro47mm -y /path/to/developer_key.der -o build/Orbit.prg
connectiq
monkeydo build/Orbit.prg fenix9pro47mm
```

To try it on the watch, connect it by USB, copy `build/Orbit.prg` to `GARMIN/APPS`, disconnect the watch, and select Orbit in the watch-face picker. See [Garmin's sideload instructions](https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/).
