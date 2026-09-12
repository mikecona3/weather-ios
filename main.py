import argparse
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

import pyart  # noqa: E402

from fetch_nexrad import fetch_latest  # noqa: E402
from rotation_detect import candidates_across_sweeps  # noqa: E402
from cell_track import identify_cells  # noqa: E402
from visualize import plot_scan  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description="Tornado detection & nowcast pipeline")
    parser.add_argument("--station", required=True, help="4-letter NEXRAD station code, e.g. KBGM")
    parser.add_argument("--mode", choices=["latest"], default="latest")
    parser.add_argument("--dbz-threshold", type=float, default=40.0,
                         help="Reflectivity threshold (dBZ) for storm cell identification")
    parser.add_argument("--shear-threshold", type=float, default=25.0,
                         help="Velocity shear threshold (m/s) for rotation couplet detection")
    parser.add_argument("--out", default="scan_plot.png", help="Output plot path")
    args = parser.parse_args()

    print(f"Fetching latest scan for {args.station}...")
    scan_path = fetch_latest(args.station)
    print(f"  -> {scan_path}")

    print("Reading radar volume...")
    radar = pyart.io.read_nexrad_archive(scan_path)

    print("Running rotation detection across all sweeps...")
    candidates = candidates_across_sweeps(radar, shear_threshold_ms=args.shear_threshold)
    if candidates:
        print(f"  -> {len(candidates)} rotation candidate(s) found:")
        for c in candidates:
            print(f"     az={c.azimuth_deg:.1f}deg range={c.range_km:.1f}km "
                  f"elev={c.elevation_deg:.1f}deg shear={c.shear_ms:.1f}m/s "
                  f"({c.lat:.4f}, {c.lon:.4f})")
    else:
        print("  -> No rotation candidates above threshold.")

    print("Identifying storm cells from reflectivity...")
    refl = radar.get_field(0, "reflectivity")
    lats, lons, _ = radar.get_gate_lat_lon_alt(0)
    from datetime import datetime, timezone
    cells = identify_cells(refl, lats, lons, datetime.now(timezone.utc),
                            dbz_threshold=args.dbz_threshold)
    print(f"  -> {len(cells)} storm cell(s) above {args.dbz_threshold} dBZ")

    print(f"Plotting to {args.out}...")
    plot_scan(radar, sweep=0, candidates=candidates, save_path=args.out)

    print("\nNote: cell tracking + motion nowcast require multiple scans over "
          "time. Run this on a loop (e.g. every 5 min) and feed each scan's "
          "cells into cell_track.update_tracks() to build tracks, then "
          "nowcast.project_path() once a track has 2+ observations.")


if __name__ == "__main__":
    main()
