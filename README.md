# Pilotix Rocky5 tail mount

TPU tail mount for the Pilotix Rocky5 5" frame: 5.8 GHz antenna on a 2-hole flange SMA pigtail (MGS 7813 style, M2 at 12.3 mm) plus a 25x25 mm GPS module (Norduva GPS v3.0.5, patch up).

Slides over the two tail standoffs (5 mm round, 26 mm c-c) and is trapped by the top plate.

## Variants

| Files | Description |
|---|---|
| `rocky5_tail_mount_hinton.*` | Merge of Weston Hinton's GPS and SMA standoff mounts ([FPV-Parametric-Library](https://github.com/wbhinton/FPV-Parametric-Library)). GPS box tilted 25°, SMA platform 30°. OpenSCAD source plus a parametric FreeCAD model (`.FCStd`, driven by the `Params` spreadsheet; `build_hinton_fcstd.py` regenerates it). |
| `rocky5_tail_mount.*` | Alternative custom design: flat GPS tray with retaining lip, solid wedge braces, SMA plate 30°. OpenSCAD only. |

## Before printing

- Standoff length is assumed to be 22 mm; measure yours and set `standoff_height` / `so_len`.
- Check rear prop clearance: the mount is ~34 mm wide and extends ~46 mm behind the standoffs.
- Print in TPU 95A.

## License

GPL-3.0-or-later (the Hinton-derived files are GPL; the rest is released under the same license).
