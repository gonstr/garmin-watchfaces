# Orbit Native Implementation Plan

> For agentic workers, use superpowers:executing-plans for inline execution or superpowers:subagent-driven-development for delegated execution.

**Goal** Build a sideloadable Orbit watch face for the fēnix 9 Pro 47 mm AMOLED.

**Architecture** A Connect IQ app provides a watch-face view that draws the recessed ring and hands using native graphics and reads time and date from the watch.

**Tech stack** Monkey C, Garmin Connect IQ SDK, and Connect IQ Simulator.

**Spec** [Orbit native prototype](../specs/2026-11-19-orbit-native-design.md)

## Build and verify the first prototype

- [x] Set up Java and the Garmin SDK and confirm the exact device ID from the installed device profile.
- [x] Add the manifest, Jungle file, resources, and watch-face source under `faces/orbit/connectiq/`. Scale the dial from the mockup proportions and use a reduced, time-only layout in low-power mode.
- [x] Compile a signed device PRG with a local developer key stored outside Git. Launch the simulator for the exact model.
- [ ] Check midnight, noon, 12/24-hour formatting, date rollover, and the low-power transition. Inspect hand alignment and text clearance on the 454 × 454 canvas.
- [ ] Add build and sideload instructions to the face README and provide the verified PRG for wrist testing.
