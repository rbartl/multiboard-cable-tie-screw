/*
  Under-desk cable tie for the Multiboard system.

  Functional re-interpretation of "Under-Desk Cable Tie for OpenGrid System"
  (makerworld.com/en/models/1908305) with the OpenGrid foot replaced by a
  Multiboard multihole snap.

  Snap geometry by Andy Levesque (MultiConnectOpenSCAD), credit to @David D
  (Multiconnect) and Jonathan at Keep Making (Multiboard).
  CC BY-NC-SA 4.0 + Multiboard License (https://multibuild.io/license; see LICENSE).
*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

/* [Model] */

// Cable capacity
size = "M"; // [S:small - 1-2 cables, M:medium - ~5 cables, L:large - up to ~10 cables]
// Which part to render
part = "all"; // [all, body, nut]

/* [Fit] */

// Printer tolerance for the nut thread. Increase if the nut is too tight.
thread_slop = 0.15;

/* [Hidden] */

$fa = 1;
$fs = 0.4;
$slop = thread_slop;

// Multiboard grid. A cell is a 25 mm square with its corners cut back by
// cell_chamfer, which is the outline every plate here follows.
cell = 25;
cell_chamfer = (cell - cell / (1 + 2 * cos(45))) / 2; // 7.3223

// The sizes differ mainly in post height: cables stack up inside the pot.
// size -> [post height, plate cells in y, nut height]
spec = size == "S" ? [12, 1, 8]
     : size == "L" ? [36, 1, 9]
     :               [22, 1, 9];

post_h    = spec[0];
plate_y   = spec[1];
nut_h     = spec[2];
snaps     = plate_y;

// Thread diameter is capped by the 25 mm cell so the plate stays grid-sized.
thread_d = 22;
pitch    = 3;
// Measured depth of the BOSL2 thread profile at this pitch; the bore has to
// clear it, otherwise the wall under the thread root ends up paper thin.
thread_depth = 1.62;
wall     = 2.4;
base_t   = 4;
// Fillet where the two posts meet the plate — that root is where they bend.
root_fillet = 1.2;
bore_d   = thread_d - 2 * (thread_depth + wall);
nut_od   = thread_d + 8;
// Opening angle of each of the two cable windows.
slot_a   = 100;
// The vendored snap mesh spans z 0..6.19; sink it 0.1 into the plate so the
// two solids actually merge.
snap_z   = 6.09;

if (part == "all") {
    body();
    translate([0, plate_y * cell / 2 + nut_od / 2 + 4, 0]) nut();
} else if (part == "body") {
    body();
} else if (part == "nut") {
    nut();
}

module body() {
    difference() {
        union() {
            for (i = [0:snaps - 1])
                back((i - (snaps - 1) / 2) * cell) down(snap_z)
                    import("multiboard_snap.stl", convexity = 6);
            plate();
            up(base_t - 0.01)
                threaded_rod(d = thread_d, l = post_h + 0.01, pitch = pitch,
                             bevel1 = false, bevel2 = true, anchor = BOTTOM);
            up(base_t - 0.01)
                cyl(d1 = thread_d + 2 * root_fillet, d2 = thread_d,
                    h = root_fillet + 0.01, anchor = BOTTOM);
        }
        // cable bore
        up(base_t) cyl(d = bore_d, h = post_h + 1, anchor = BOTTOM);
        // through channel: a window on each side so a cable passes straight
        // through the centre instead of dead-ending against the back wall
        for (a = [0, 180])
            zrot(a) up(base_t - 0.01) sector_cut(slot_a, post_h + 1.02, thread_d);
    }
}

// Plate following the Multiboard cell outline, plate_y cells long.
module plate() {
    w = cell / 2;
    l = plate_y * cell / 2;
    c = cell_chamfer;
    linear_extrude(base_t)
        polygon([
            [ w - c, -l], [ w, -l + c], [ w, l - c], [ w - c, l],
            [-w + c,  l], [-w,  l - c], [-w, -l + c], [-w + c, -l],
        ]);
}

module sector_cut(ang, h, r) {
    linear_extrude(h)
        polygon([[0, 0], for (t = [-ang / 2 : ang / 32 : ang / 2]) [r * cos(t), r * sin(t)]]);
}

module nut() {
    knurl_r = 1.2;
    knurls = round(nut_od * 1.6);
    difference() {
        union() {
            cyl(d = nut_od - knurl_r, h = nut_h, chamfer = 0.6, anchor = BOTTOM);
            for (i = [0:knurls - 1])
                zrot(i * 360 / knurls) right((nut_od - knurl_r) / 2)
                    cyl(d = knurl_r * 2, h = nut_h - 1.2, anchor = BOTTOM);
        }
        up(-0.01) threaded_rod(d = thread_d, l = nut_h + 0.02, pitch = pitch,
                               internal = true, bevel = true, anchor = BOTTOM);
    }
}
