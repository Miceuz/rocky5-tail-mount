// Copyright (C) 2026 Weston Hinton <wbhinton@gmail.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
// =============================================================================
// PROJECT: GPS + SMA STANDOFF MOUNT (merged)
// SOURCE:  https://github.com/wbhinton/FPV-Parametric-Library @ eb64e64
//          Mounts/Multi-rotor/GPS-standoff-mount.scad  v3.6
//          Mounts/Multi-rotor/SMA-Standoff-Mount.scad  v4.0
// MODIFIED 2026-10-04: merged into one part (SMA platform hangs off the GPS box
//          rear edge), added 2-hole flange SMA seat, nobs made optional,
//          round standoff bores, defaults set for Pilotix Rocky5 + Elarion GPS module v3.0.5.
// Coordinates: z=0 bottom plate, z=standoff_height underside of top plate, +Y = rearward.
// =============================================================================

/* [1. FRAME SETTINGS] */
standoff_dist   = 26.0;
standoff_dia    = 5.0;
standoff_height = 21.7;  // tail standoff length - 0.3; MEASURE
wall            = 1.6;
// Round bore, d = standoff_dia + fit_tolerance (printed TPU holes run ~0.1-0.2 small)
fit_tolerance   = 0.1;

/* [2. GPS COMPARTMENT SETTINGS] */
gps_angle       = 25;
gps_offset      = 5.0;   // standoff centre line to box front (top plate ends at 3.6)
gps_w           = 25.0;
gps_l           = 25.0;
gps_h           = 8.5;   // patch 4 + PCB 1.6 + parts 2.6 + slack
nob_height      = 0;     // 0: parts side rests on floor (use foam tape); nobs would hit parts on this board

/* [3. WIRE WINDOW SETTINGS] */
wire_width      = 12.5;  // JST-GH, centred on board edge
wire_window_h   = 4.0;
wire_offset     = 0;

/* [4. HARDWARE & RETENTION] */
zt_width        = 3.;
zt_depth        = 1.5;
$fn = 60;

/* [5. ANTENNA PLATFORM SETTINGS] */
sma_type        = "flange";  // "flange" (2-hole panel jack) or "bulkhead" (hex nut)
antenna_angle   = 30;
platform_offset = 7.0;   // box rear edge to SMA hole centre, along the plate
platform_w      = gps_w + (wall * 2);  // = GPS box width
platform_padding = 7.0;
mounting_thick  = 3.5;   // flange: 2.0 above flange keeps the 1/4-36 thread exposed

/* [6. SMA HARDWARE] */
sma_hole_dia    = 6.6;   // bulkhead
sma_hex_flat    = 8.2;
shoulder_thick  = 1.25;
fl_l            = 16.4;  // flange 16 x 6 x 1.5 (MGS 7813) + clearance
fl_w            = 6.4;
fl_t            = 1.5;
fl_chamf        = 1.2;
fl_pitch        = 12.3;
fl_hole_d       = 2.2;   // M2 self-tap; 2.4 for screw + nut
fl_body_d       = 8.0;

/* [7. INTERNAL CALCULATIONS] */
box_w = gps_w + (wall * 2);
box_l = gps_l + (wall * 2);
box_d_total = gps_h + nob_height + 1.2;
platform_l = platform_offset + platform_padding;

// Trig to keep top flush
tilt_lift = sin(gps_angle) * (box_l/2);
box_z_pos = standoff_height - (box_d_total / 2) - tilt_lift;

module box_frame() {
    translate([0, gps_offset + (box_l/2), box_z_pos]) rotate([-gps_angle, 0, 0]) children();
}

// platform frame: origin on the box rear-top edge, plate top face at z=0, global tilt = antenna_angle
module platform_frame() {
    box_frame() translate([0, box_l/2, box_d_total/2]) rotate([gps_angle - antenna_angle, 0, 0]) children();
}

module flange_shape(l, w, c) {
    offset(delta = c, chamfer = true) square([l - 2*c, w - 2*c], center = true);
}

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================

difference() {
    // --- STEP 1: SOLID GEOMETRY ---
    union() {
        // A. Standoff Sleeves
        for(i=[-1, 1]) {
            translate([i * standoff_dist/2, 0, 0])
                cylinder(h=standoff_height, d=standoff_dia + (wall*2));
        }

        // B. GPS Outer Shell (Sharp Corners)
        box_frame() {
            cube([box_w, box_l, box_d_total], center=true);

            // Internal Corner Nobs (optional)
            if (nob_height > 0)
                for(x=[-1,1], y=[-1,1])
                    translate([x*(gps_w/2 - 1.5), y*(gps_l/2 - 1.5), -box_d_total/2 + 1.2])
                        cylinder(h=nob_height + 0.1, d=3);
        }

        // C. SOLID TRIANGULAR GUSSETS
        for(side=[-1, 1]) {
            hull() {
                translate([side * standoff_dist/2, 0, 0])
                    cylinder(h=standoff_height, d=standoff_dia + (wall*2));
                box_frame()
                    translate([side * (box_w/2 - 0.5), 0, 0])
                        cube([1, box_l, box_d_total], center=true);
            }
        }

        // D. Antenna platform
        platform_frame()
            translate([-platform_w/2, 0, -mounting_thick])
                cube([platform_w, platform_l, mounting_thick]);

        // E. Platform-to-box web
        hull() {
            platform_frame() translate([-platform_w/2, 0, -mounting_thick]) cube([platform_w, 2, mounting_thick]);
            box_frame() translate([-platform_w/2, box_l/2 - wall, -box_d_total/2]) cube([platform_w, wall, box_d_total]);
        }

        // F. Platform rib trusses, down to the box rear-bottom edge
        for(i=[-1, 1]) {
            hull() {
                platform_frame()
                    translate([i * (platform_w/2 - 1.25), platform_l/2, -mounting_thick/2])
                        cube([2.5, platform_l, mounting_thick], center=true);
                box_frame()
                    translate([i * (platform_w/2 - 1.25), box_l/2 - wall/2, -box_d_total/2 + 0.5])
                        cube([2.5, wall, 1], center=true);
            }
        }
    }

    // --- STEP 2: SUBTRACTIONS ---

    // A. SAFETY PLANE CUT
    translate([-100, -100, standoff_height])
        cube([200, 200, 50]);

    // B. STANDOFF HOLES (round)
    for(i=[-1, 1]) {
        translate([i * standoff_dist/2, 0, -1])
            cylinder(h=standoff_height + 2, d=standoff_dia + fit_tolerance);
    }

    // C. Internal Cavity (Sharp-edged)
    box_frame() {

        // 1. Main GPS Cavity
        translate([0, 0, -box_d_total/2 + 1.2 + nob_height + (gps_h+5)/2])
            cube([gps_w + 0.4, gps_l + 0.4, gps_h + 5], center=true);

        // 2. Floor relief
        if (nob_height > 0)
            translate([0,0, -box_d_total/2 + 1.2 + (nob_height+0.1)/2])
                cube([gps_w - 4, gps_l - 4, nob_height + 0.1], center=true);

        // 3. OFFSET WIRE WINDOW (front wall, towards the frame)
        translate([wire_offset, -gps_l/2 - wall, -box_d_total/2 + 1.2 + nob_height + (wire_window_h/2)])
            cube([wire_width, wall * 4, wire_window_h], center=true);

        // 4. Zip-Tie Channel
        translate([0, 0, -box_d_total/2 + 1.2 - (zt_depth/2)])
            cube([box_w + 50, zt_width, zt_depth], center=true);

        // 5. Ejection Hole
        translate([0, 0, -50]) cylinder(h=100, d=10);
    }

    // D. SMA seat
    platform_frame() translate([0, platform_offset, 0]) {
        if (sma_type == "bulkhead") {
            translate([0, 0, -50]) cylinder(h=55, d=sma_hole_dia);
            translate([0, 0, -50]) cylinder(h=50 - shoulder_thick, d=sma_hex_flat / cos(30), $fn=6);
        } else {
            translate([0, 0, -50]) cylinder(h=55, d=fl_body_d);
            translate([0, 0, -mounting_thick - 1]) linear_extrude(fl_t + 1) flange_shape(fl_l, fl_w, fl_chamf);
            for (sx = [-1, 1]) translate([sx*fl_pitch/2, 0, -50]) cylinder(h=55, d=fl_hole_d);
        }
    }
}
