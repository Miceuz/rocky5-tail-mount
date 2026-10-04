# Builds a parametric FreeCAD model of rocky5_tail_mount_hinton.scad (GPL-3.0-or-later,
# derived from Weston Hinton's FPV-Parametric-Library). All dimensions live in the
# "Params" spreadsheet; features are bound to it with expressions.
# Run: FreeCAD.AppImage freecadcmd build_hinton_fcstd.py
import math, os
import FreeCAD as App
import Part, Sketcher, Mesh
from FreeCAD import Vector, Placement, Rotation

OUT = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else os.getcwd()
NAME = "rocky5_tail_mount_hinton"

# ---------- parameters (alias, value, comment) ----------
PARAMS = [
    ("standoff_dist", 26.0, "tail standoff c-c"),
    ("standoff_dia", 5.0, "standoff diameter"),
    ("standoff_height", 21.7, "tail standoff length - 0.3; MEASURE"),
    ("wall", 1.6, "sleeve / box wall"),
    ("fit_tolerance", 0.1, "round bore = dia + tol (printed TPU holes run ~0.1-0.2 small)"),
    ("gps_angle", 25, "GPS box tilt, deg"),
    ("gps_offset", 5.0, "standoff line to box front"),
    ("gps_w", 25.0, "GPS board"),
    ("gps_l", 25.0, "GPS board"),
    ("gps_h", 8.5, "patch 4 + PCB 1.6 + parts 2.6 + slack"),
    ("floor_t", 1.2, "box floor"),
    ("wire_width", 12.5, "JST-GH window"),
    ("wire_window_h", 4.0, ""),
    ("wire_offset", 0, ""),
    ("zt_width", 3.0, "zip-tie channel"),
    ("zt_depth", 1.5, ""),
    ("eject_d", 10.0, "ejection hole"),
    ("gusset_t", 4.0, "sleeve-to-box gusset plate"),
    ("antenna_angle", 30, "deg from vertical, rearward"),
    ("platform_offset", 7.0, "box rear edge to SMA hole"),
    ("platform_padding", 7.0, ""),
    ("mounting_thick", 3.5, "2.0 above flange keeps thread exposed"),
    ("rib_w", 2.5, "platform rib width"),
    ("web_l", 2.0, "platform slice used by the web"),
    ("fl_l", 16.4, "flange 16x6x1.5 + clearance"),
    ("fl_w", 6.4, ""),
    ("fl_t", 1.5, ""),
    ("fl_pitch", 12.3, "flange hole c-c"),
    ("fl_hole_d", 2.2, "M2 self-tap; 2.4 for nut"),
    ("fl_body_d", 8.0, "SMA body clearance"),
]
DERIVED = [
    ("sleeve_d", "standoff_dia + 2 * wall"),
    ("box_w", "gps_w + 2 * wall"),
    ("box_l", "gps_l + 2 * wall"),
    ("box_d", "gps_h + floor_t"),
    ("platform_w", "box_w"),
    ("platform_l", "platform_offset + platform_padding"),
    ("cg", "cos(gps_angle)"),
    ("sg", "sin(gps_angle)"),
    ("ca", "cos(antenna_angle)"),
    ("sa", "sin(antenna_angle)"),
    ("Cby", "gps_offset + box_l / 2"),
    ("Cbz", "standoff_height - box_d / 2 - sg * box_l / 2"),
    # platform frame origin = box frame point (0, box_l/2, box_d/2)
    ("P0y", "Cby + box_l / 2 * cg + box_d / 2 * sg"),
    ("P0z", "Cbz - box_l / 2 * sg + box_d / 2 * cg"),
]

# numeric mirror of the spreadsheet (used only to order hull vertices)
V = {k: v for k, v, _ in PARAMS}
def _d(k, f): V[k] = f
_d("sleeve_d", V["standoff_dia"] + 2 * V["wall"])
_d("box_w", V["gps_w"] + 2 * V["wall"])
_d("box_l", V["gps_l"] + 2 * V["wall"])
_d("box_d", V["gps_h"] + V["floor_t"])
_d("platform_w", V["box_w"])
_d("platform_l", V["platform_offset"] + V["platform_padding"])
for a, n in (("gps_angle", "g"), ("antenna_angle", "a")):
    V["c" + n] = math.cos(math.radians(V[a])); V["s" + n] = math.sin(math.radians(V[a]))
_d("Cby", V["gps_offset"] + V["box_l"] / 2)
_d("Cbz", V["standoff_height"] - V["box_d"] / 2 - V["sg"] * V["box_l"] / 2)
_d("P0y", V["Cby"] + V["box_l"] / 2 * V["cg"] + V["box_d"] / 2 * V["sg"])
_d("P0z", V["Cbz"] - V["box_l"] / 2 * V["sg"] + V["box_d"] / 2 * V["cg"])

def ev(expr):
    return eval(expr.replace("Params.", ""), {}, V)

doc = App.newDocument(NAME)
sh = doc.addObject("Spreadsheet::Sheet", "Params")
row = 1
sh.set("A1", "parameter"); sh.set("B1", "value"); sh.set("C1", "note")
for k, v, c in PARAMS:
    row += 1
    sh.set(f"A{row}", k); sh.set(f"B{row}", str(v)); sh.set(f"C{row}", c); sh.setAlias(f"B{row}", k)
row += 1; sh.set(f"A{row}", "--- derived ---")
for k, f in DERIVED:
    row += 1
    sh.set(f"A{row}", k); sh.set(f"B{row}", "=" + f); sh.setAlias(f"B{row}", k)
doc.recompute()

P = "Params."
# frame transforms (local y, z expressions -> global y, z expressions); rotation about X
FRAMES = {
    "box":  dict(oy=P + "Cby", oz=P + "Cbz", c=P + "cg", s=P + "sg", ang=P + "gps_angle"),
    "plat": dict(oy=P + "P0y", oz=P + "P0z", c=P + "ca", s=P + "sa", ang=P + "antenna_angle"),
}
def to_global(frame, ly, lz):
    f = FRAMES[frame]
    return (f"{f['oy']} + ({ly}) * {f['c']} + ({lz}) * {f['s']}",
            f"{f['oz']} - ({ly}) * {f['s']} + ({lz}) * {f['c']}")

def bind(obj, prop, expr):
    obj.setExpression(prop, expr)

def place(obj, x, y, z, frame=None):
    """corner/base of obj at local (x, y, z) in frame (None = global)"""
    if frame:
        gy, gz = to_global(frame, y, z)
        obj.Placement = Placement(Vector(), Rotation(Vector(-1, 0, 0), 1))
        bind(obj, "Placement.Rotation.Angle", FRAMES[frame]["ang"])
    else:
        gy, gz = y, z
    bind(obj, "Placement.Base.x", x); bind(obj, "Placement.Base.y", gy); bind(obj, "Placement.Base.z", gz)

def box(name, lx, ly, lz, x, y, z, frame=None):
    o = doc.addObject("Part::Box", name)
    bind(o, "Length", lx); bind(o, "Width", ly); bind(o, "Height", lz)
    place(o, x, y, z, frame)
    return o

def cyl(name, d, h, x, y, z, frame=None):
    o = doc.addObject("Part::Cylinder", name)
    bind(o, "Radius", f"({d}) / 2"); bind(o, "Height", h)
    place(o, x, y, z, frame)
    return o

def hull2d(pts):
    """monotone chain on (y, z) values; returns indices CCW"""
    idx = sorted(range(len(pts)), key=lambda i: (pts[i][2], pts[i][3]))
    def cross(o, a, b):
        return (pts[a][2] - pts[o][2]) * (pts[b][3] - pts[o][3]) - (pts[a][3] - pts[o][3]) * (pts[b][2] - pts[o][2])
    lo, up = [], []
    for i in idx:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], i) <= 1e-9: lo.pop()
        lo.append(i)
    for i in reversed(idx):
        while len(up) >= 2 and cross(up[-2], up[-1], i) <= 1e-9: up.pop()
        up.append(i)
    return lo[:-1] + up[:-1]

def profile_extrude(name, pts, x0, length, mirror=False):
    """pts: list of (y_expr, z_expr). Sketch in YZ at x = x0, extruded +X by length."""
    pts = [(y, z, ev(y), ev(z)) for y, z in pts]
    order = hull2d(pts)
    sk = doc.addObject("Sketcher::SketchObject", name + "_profile")
    sk.Placement = Placement(Vector(), Rotation(Vector(1, 1, 1), 120))  # sketch u -> Y, v -> Z, normal -> X
    bind(sk, "Placement.Base.x", x0)
    n = len(order)
    for k in range(n):
        a, b = pts[order[k]], pts[order[(k + 1) % n]]
        sk.addGeometry(Part.LineSegment(Vector(a[2], a[3], 0), Vector(b[2], b[3], 0)))
    for k in range(n):
        sk.addConstraint(Sketcher.Constraint("Coincident", k, 2, (k + 1) % n, 1))
    for k in range(n):
        p = pts[order[k]]
        ci = sk.addConstraint(Sketcher.Constraint("DistanceX", k, 1, p[2])); bind(sk, f"Constraints[{ci}]", p[0])
        ci = sk.addConstraint(Sketcher.Constraint("DistanceY", k, 1, p[3])); bind(sk, f"Constraints[{ci}]", p[1])
    ex = doc.addObject("Part::Extrusion", name)
    ex.Base = sk; ex.DirMode = "Custom"; ex.Dir = Vector(1, 0, 0); ex.Solid = True
    bind(ex, "LengthFwd", length)
    out = [ex]
    if mirror:
        m = doc.addObject("Part::Mirroring", name + "_mirror")
        m.Source = ex; m.Normal = Vector(1, 0, 0); m.Base = Vector(0, 0, 0)
        out.append(m)
    return out

def frame_pts(frame, lys, lzs):
    return [to_global(frame, ly, lz) for ly in lys for lz in lzs]

solids, tools = [], []

# A. sleeves
for side, sx in (("L", "-"), ("R", "")):
    solids.append(cyl(f"Sleeve{side}", P + "sleeve_d", P + "standoff_height", f"{sx}{P}standoff_dist / 2", "0", "0"))
# B. GPS box
solids.append(box("GPSBox", P + "box_w", P + "box_l", P + "box_d",
                  f"-{P}box_w / 2", f"-{P}box_l / 2", f"-{P}box_d / 2", "box"))
# C. gussets: planar plates, convex hull of sleeve side silhouette + box side silhouette
r = f"{P}sleeve_d / 2"
# start at the sleeve centre line so the flat plate stays inside the round sleeve
g_pts = [("0", "0"), (r, "0"), (r, P + "standoff_height"), ("0", P + "standoff_height")]
g_pts += frame_pts("box", [f"-{P}box_l / 2", f"{P}box_l / 2"], [f"-{P}box_d / 2", f"{P}box_d / 2"])
solids += profile_extrude("Gusset", g_pts, f"{P}box_w / 2 - {P}gusset_t", P + "gusset_t", mirror=True)
# D. antenna platform
solids.append(box("Platform", P + "platform_w", P + "platform_l", P + "mounting_thick",
                  f"-{P}platform_w / 2", "0", f"-{P}mounting_thick", "plat"))
# E. platform-to-box web
w_pts = frame_pts("plat", ["0", P + "web_l"], [f"-{P}mounting_thick", "0"])
w_pts += frame_pts("box", [f"{P}box_l / 2 - {P}wall", f"{P}box_l / 2"], [f"-{P}box_d / 2", f"{P}box_d / 2"])
solids += profile_extrude("Web", w_pts, f"-{P}platform_w / 2", P + "platform_w")
# F. platform ribs down to the box rear-bottom edge
r_pts = frame_pts("plat", ["0", P + "platform_l"], [f"-{P}mounting_thick", "0"])
r_pts += frame_pts("box", [f"{P}box_l / 2 - {P}wall", f"{P}box_l / 2"], [f"-{P}box_d / 2", f"-{P}box_d / 2 + 1"])
solids += profile_extrude("Rib", r_pts, f"{P}platform_w / 2 - {P}rib_w", P + "rib_w", mirror=True)

# --- cut tools ---
tools.append(box("SafetyCut", "200", "200", "50", "-100", "-100", P + "standoff_height"))
for side, sx in (("L", "-"), ("R", "")):
    tools.append(cyl(f"Bore{side}", f"{P}standoff_dia + {P}fit_tolerance", f"{P}standoff_height + 2",
                     f"{sx}{P}standoff_dist / 2", "0", "-1"))
tools.append(box("Cavity", f"{P}gps_w + 0.4", f"{P}gps_l + 0.4", f"{P}gps_h + 5",
                 f"-({P}gps_w + 0.4) / 2", f"-({P}gps_l + 0.4) / 2", f"-{P}box_d / 2 + {P}floor_t", "box"))
tools.append(box("WireWindow", P + "wire_width", f"{P}wall * 4", P + "wire_window_h",
                 f"{P}wire_offset - {P}wire_width / 2", f"-{P}gps_l / 2 - 3 * {P}wall",
                 f"-{P}box_d / 2 + {P}floor_t", "box"))
tools.append(box("ZipTie", f"{P}box_w + 50", P + "zt_width", P + "zt_depth",
                 f"-({P}box_w + 50) / 2", f"-{P}zt_width / 2", f"-{P}box_d / 2 + {P}floor_t - {P}zt_depth", "box"))
tools.append(cyl("EjectHole", P + "eject_d", "100", "0", "0", "-50", "box"))
tools.append(cyl("SMABody", P + "fl_body_d", "55", "0", P + "platform_offset", "-50", "plat"))
tools.append(box("FlangeRecess", P + "fl_l", P + "fl_w", f"{P}fl_t + 1",
                 f"-{P}fl_l / 2", f"{P}platform_offset - {P}fl_w / 2", f"-{P}mounting_thick - 1", "plat"))
for side, sx in (("L", "-"), ("R", "")):
    tools.append(cyl(f"FlangeHole{side}", P + "fl_hole_d", "55", f"{sx}{P}fl_pitch / 2", P + "platform_offset", "-50", "plat"))

fuse = doc.addObject("Part::MultiFuse", "Body_Solids"); fuse.Shapes = solids; fuse.Refine = True
cuts = doc.addObject("Part::MultiFuse", "Cut_Tools"); cuts.Shapes = tools
mount = doc.addObject("Part::Cut", "TailMount"); mount.Base = fuse; mount.Tool = cuts; mount.Refine = True
doc.recompute()

bad = [o.Name for o in doc.Objects if hasattr(o, "isValid") and not o.isValid()]
s = mount.Shape
print("invalid:", bad)
print("valid:", s.isValid(), "solids:", len(s.Solids), "volume mm3: %.1f" % s.Volume)
bb = s.BoundBox
print("bbox: x %.1f..%.1f y %.1f..%.1f z %.1f..%.1f" % (bb.XMin, bb.XMax, bb.YMin, bb.YMax, bb.ZMin, bb.ZMax))

doc.saveAs(os.path.join(OUT, NAME + ".FCStd"))
Part.export([mount], os.path.join(OUT, NAME + ".step"))
Mesh.export([mount], os.path.join(OUT, NAME + "_fc.stl"))
