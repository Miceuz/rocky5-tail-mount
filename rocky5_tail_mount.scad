// Pilotix Rocky5 tail mount: SMA 2-hole flange (MGS 7813 style) + Elarion GPS module v3.0.5
// Print in TPU 95A.
// Coordinates: X across frame, +Y forward, Z up.
// Origin: midpoint between the two tail standoff centres, z=0 = underside of top plate.

$fn = 48;
show_ghost = false;          // true: show standoffs, top plate, GPS and antenna for fit check

// ---------- frame ----------
so_pitch   = 26.0;           // tail standoff c-c (measured from plate photos)
so_d       = 5.0;            // standoff diameter
so_len     = 22;             // tail standoff length (top plate to bottom plate) - MEASURE
so_clear   = 0.1;            // bore = so_d + so_clear (printed TPU holes run ~0.1-0.2 small)
ring_wall  = 2.5;
ring_h     = so_len - 0.3;   // sleeve spans the standoff, trapped by the plates
cable_slot = [8, 8];         // SMA cable pass-through in the bridge (w, h)
brace_t    = 8;              // diagonal brace thickness
plate_end  = 3.6;            // top plate end behind standoff centre (ghost/clearance only)
plate_t    = 2.0;

// ---------- GPS ----------
gps_w      = 25.0;
gps_clr    = 0.2;            // per side
gps_comp_h = 2.6;            // component side height (faces down)
gps_pcb_t  = 1.6;
gps_patch_h= 4.0;            // ceramic patch (faces up)
gps_patch_w= 20.0;
cav_extra  = 0.3;            // vertical slack (or foam tape)
floor_t    = 2.5;
wall_t     = 2.0;
lip_t      = 1.4;
lip_w      = 0.8;            // lip overlap onto PCB edge
jst_slot_w = 12.5;           // JST-GH slot, on +X wall
tray_front = -5.0;           // y of tray front face
tray_floor_z = -7.4;         // z of tray bottom

// ---------- SMA ----------
ant_tilt   = 30;             // deg from vertical, toward rear
fl_l       = 16.0 + 0.4;     // flange 16 x 6 x 1.5
fl_w       = 6.0 + 0.4;
fl_t       = 1.5;
fl_chamf   = 1.2;
fl_pitch   = 12.3;
fl_hole_d  = 2.2;            // M2 self-tap into TPU; 2.4 for screw + nut
body_d     = 8.0;            // clearance for body between flange and thread
sp_t       = 5.0;            // SMA plate thickness
sp_front   = 2.0;            // material between flange and front face (< 2.4 keeps thread exposed)
cbore_d    = 11;             // front counterbore for the antenna nut
sp_w       = 20;
sp_y0      = -5;             // plate extent along its own Y (local)
sp_y1      = 7;

// ---------- derived ----------
pocket     = gps_w + 2*gps_clr;
tray_o     = pocket + 2*wall_t;
cav_h      = gps_comp_h + gps_pcb_t + cav_extra;
tray_h     = floor_t + cav_h + lip_t;
tray_cy    = tray_front - tray_o/2;
ring_r     = (so_d + so_clear)/2 + ring_wall;
bridge_y   = [-9, -3];
sp_pos     = [0, tray_front - tray_o - 7, -4];   // SMA plate front-face centre

module rings() {
    for (sx = [-1, 1]) translate([sx*so_pitch/2, 0, -ring_h])
        cylinder(r = ring_r, h = ring_h);
}

module ring_cuts() {
    for (sx = [-1, 1]) translate([sx*so_pitch/2, 0, -ring_h - 1]) {
        cylinder(d = so_d + so_clear, h = ring_h + 2);
    }
    // cable pass-through between the standoffs
    translate([-cable_slot[0]/2, bridge_y[0] - 1, -ring_h + 3])
        cube([cable_slot[0], bridge_y[1] - bridge_y[0] + 2, cable_slot[1]]);
}

module bridge() {
    translate([-so_pitch/2, bridge_y[0], -ring_h])
        cube([so_pitch, bridge_y[1] - bridge_y[0], ring_h]);
}

module tray() {
    translate([-tray_o/2, tray_front - tray_o, tray_floor_z])
        cube([tray_o, tray_o, tray_h]);
}

module tray_cuts() {
    // cavity under the lip
    translate([-pocket/2, tray_cy - pocket/2, tray_floor_z + floor_t])
        cube([pocket, pocket, cav_h]);
    // lip opening
    translate([-(pocket/2 - lip_w), tray_cy - (pocket/2 - lip_w), tray_floor_z + floor_t + cav_h - 0.01])
        cube([pocket - 2*lip_w, pocket - 2*lip_w, lip_t + 1]);
    // JST-GH slot through +X wall, floor to PCB underside
    translate([pocket/2 - 1, tray_cy - jst_slot_w/2, tray_floor_z + floor_t])
        cube([wall_t + 2, jst_slot_w, gps_comp_h + cav_extra]);
}

module ribs() {
    // diagonal braces: solid wedges from cable slot edge to bridge edge, bridge foot to tray rear
    bx0 = cable_slot[0]/2;
    bx1 = so_pitch/2;
    for (m = [0, 1]) mirror([m, 0, 0]) hull() {
        translate([bx0, bridge_y[0], -ring_h]) cube([bx1 - bx0, bridge_y[1] - bridge_y[0], brace_t]);
        translate([bx0, tray_front - tray_o, tray_floor_z]) cube([bx1 - bx0, brace_t, brace_t]);
        // tray underside up to the bridge: makes the brace a solid wedge
        translate([bx0, tray_front - tray_o, tray_floor_z]) cube([bx1 - bx0, bridge_y[1] - (tray_front - tray_o), 1]);
    }
}

module flange_shape(l, w, c) {
    offset(delta = c, chamfer = true) square([l - 2*c, w - 2*c], center = true);
}

module sma_frame() {    // local frame: +Z = antenna axis, front face at z=0
    translate(sp_pos) rotate([ant_tilt, 0, 0]) children();
}

module sma_plate() {
    sma_frame() translate([-sp_w/2, sp_y0, -sp_t]) cube([sp_w, sp_y1 - sp_y0, sp_t]);
}

module sma_cuts() {
    sma_frame() {
        translate([0, 0, -sp_t - 1]) cylinder(d = body_d, h = sp_t + 2);
        translate([0, 0, -sp_t - 0.01]) linear_extrude(sp_t - sp_front + 0.01) flange_shape(fl_l, fl_w, fl_chamf);
        translate([0, 0, -(sp_t - fl_t - sp_front)]) cylinder(d = cbore_d, h = sp_t);
        for (sx = [-1, 1]) translate([sx*fl_pitch/2, 0, -sp_t - 1]) cylinder(d = fl_hole_d, h = sp_t + 2);
    }
}

module sma_web() {      // ties the upper edge of the SMA plate to the tray rear wall
    hull() {
        sma_frame() translate([-sp_w/2, sp_y1 - 3, -sp_t]) cube([sp_w, 3, sp_t]);
        translate([-sp_w/2, tray_front - tray_o, tray_floor_z]) cube([sp_w, 3, tray_h]);
    }
}

module mount() {
    difference() {
        union() { rings(); bridge(); tray(); ribs(); sma_plate(); sma_web(); }
        ring_cuts();
        tray_cuts();
        sma_cuts();
    }
}

module ghost() {
    %for (sx = [-1, 1]) translate([sx*so_pitch/2, 0, -so_len]) cylinder(d = so_d, h = so_len);
    %translate([-16.5, -plate_end, -so_len - plate_t]) cube([33, 60, plate_t]);
    %translate([-16.5, -plate_end, 0]) cube([33, 60, plate_t]);
    // GPS: components down, PCB, patch up
    %translate([-gps_w/2, tray_cy - gps_w/2, tray_floor_z + floor_t + cav_extra/2]) {
        cube([gps_w, gps_w, gps_comp_h + gps_pcb_t]);
        translate([(gps_w - gps_patch_w)/2, (gps_w - gps_patch_w)/2, gps_comp_h + gps_pcb_t])
            cube([gps_patch_w, gps_patch_w, gps_patch_h]);
    }
    // SMA body + antenna stub
    %sma_frame() { cylinder(d = 6.35, h = 8); translate([0, 0, 8]) cylinder(d = 8, h = 30); }
}

mount();
if (show_ghost) ghost();
