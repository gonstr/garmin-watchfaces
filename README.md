# Garmin Watch Faces

A collection of Garmin watch face prototypes. Each design lives under `faces/<name>/`.

| Face | Preview | Description |
| --- | --- | --- |
| Orbit | [faces/orbit/mockup/index.html](faces/orbit/mockup/index.html) | Recessed analog dial, a segmented seconds light, configurable complications, and a center display that adapts to the selected data. |

Orbit is a browser prototype with illustrative data. A native Connect IQ build is still to come.

## Preview locally

Open `faces/orbit/mockup/index.html` directly in a browser, or start a local server from the repository root:

```sh
python3 -m http.server 8000 --bind 127.0.0.1 --directory faces
```

Then visit [Orbit on localhost](http://127.0.0.1:8000/orbit/mockup/). Orbit embeds its fonts, so the preview works offline. Font sources and licenses are in [Orbit's font directory](faces/orbit/mockup/assets/fonts/).

## Repository layout

- `faces/<name>/mockup/index.html` is the current browser preview for a face. Keep browser assets under mockup and any future device implementation under connectiq/.
- `backups/<name>/` holds local snapshots, design studies, and screenshots. It is ignored by Git. Keep a separate copy if you need that history on another machine.
- [AGENTS.md](AGENTS.md) describes the conventions for maintaining the collection.
