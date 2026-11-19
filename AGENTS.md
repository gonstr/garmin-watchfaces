# Repository conventions

- Use one directory per watch face under `faces/<name>/`. Use lowercase, hyphenated names. Add new faces to the table in the root README.
- Keep the current browser preview at `faces/<name>/mockup/index.html` and update it in place. Track only the current version of each face and the source assets and licenses needed to maintain it. Use Git history for earlier committed versions.
- Put local snapshots, alternate HTML versions, reference images, and exported screenshots under `backups/<name>/`. Name snapshots `YYYY-MM-DD-HHMMSS-<description>.<ext>`. Save a copy there when asked for a snapshot or before replacing a design that needs a local rollback. Keep backups, generated builds, and preview-session files out of Git.
- Make the browser preview work offline. Keep assets scoped to the face unless they are deliberately shared, and retain font and asset license notices. Orbit embeds fonts in its HTML and keeps the font source files and notices in `faces/orbit/mockup/assets/fonts/`.
- Keep browser sample data and native Garmin data clearly distinguished. If a native Connect IQ implementation is added, put it in `faces/<name>/connectiq/` and document the build and supported devices in that face's README.
- Verify visual changes in the browser using the normal preview controls. For Orbit, check the affected finish, complication settings, and time behavior. When serving locally, bind to localhost and serve the `faces/` directory.
