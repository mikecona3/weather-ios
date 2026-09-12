"""
Basic rotation (TVS/mesocyclone-style) detection from radar velocity data.

Approach: scan the radial velocity field for adjacent gate pairs (along the
same range, neighboring azimuths) where velocity flips sign and the shear
(difference) exceeds a threshold — the classic "couplet" signature of
rotation. This is a simplified version of what NWS algorithms (like MDA/TDA)
do; it's a reasonable v1 that can be replaced or supplemented with an ML
classifier later.

Caveat: gate-to-gate velocity couplets are a NECESSARY but not SUFFICIENT
condition for tornadic rotation — plenty of non-tornadic shear produces
similar signatures. Treat detections as "candidate," not "confirmed."
"""

from dataclasses import dataclass

import numpy as np
import pyart


@dataclass
class RotationCandidate:
    azimuth_deg: float
    range_km: float
    elevation_deg: float
    shear_ms: float  # velocity difference across the couplet, m/s
    lat: float
    lon: float


def find_velocity_couplets(
    radar: "pyart.core.Radar",
    sweep: int = 0,
    shear_threshold_ms: float = 25.0,
    max_gate_separation: int = 4,
) -> list[RotationCandidate]:
    """
    Scan one sweep's velocity field for rotation couplets.

    shear_threshold_ms: minimum |v_in| + |v_out| across the couplet to flag.
        25 m/s (~56 mph combined shear) is a starting point — tune against
        known cases for your radar/region.
    max_gate_separation: how many azimuth gates apart the in/out pair can be
        and still count as one couplet (accounts for beam smearing).
    """
    vel_field = radar.get_field(sweep, "velocity")
    azimuths = radar.get_azimuth(sweep)
    ranges = radar.range["data"]

    sweep_start, sweep_end = radar.get_start_end(sweep)
    lats, lons, _ = radar.get_gate_lat_lon_alt(sweep)

    candidates = []
    n_az, n_gates = vel_field.shape

    for az_idx in range(n_az):
        row = vel_field[az_idx]
        if np.ma.is_masked(row) and row.mask.all():
            continue

        for gate_idx in range(n_gates - max_gate_separation):
            window = row[gate_idx: gate_idx + max_gate_separation]
            if np.ma.is_masked(window) and window.mask.any():
                continue

            v_min, v_max = np.min(window), np.max(window)
            # A couplet: strong inbound (negative) next to strong outbound
            # (positive) within the window.
            if v_min < 0 and v_max > 0:
                shear = float(v_max - v_min)
                if shear >= shear_threshold_ms:
                    center_gate = gate_idx + max_gate_separation // 2
                    candidates.append(
                        RotationCandidate(
                            azimuth_deg=float(azimuths[az_idx]),
                            range_km=float(ranges[center_gate]) / 1000.0,
                            elevation_deg=float(radar.fixed_angle["data"][sweep]),
                            shear_ms=shear,
                            lat=float(lats[az_idx, center_gate]),
                            lon=float(lons[az_idx, center_gate]),
                        )
                    )

    return _dedupe_nearby(candidates)


def _dedupe_nearby(candidates: list[RotationCandidate], min_sep_km: float = 2.0) -> list[RotationCandidate]:
    """Collapse clustered detections (same rotation, many adjacent gates) to local maxima."""
    if not candidates:
        return []
    candidates = sorted(candidates, key=lambda c: -c.shear_ms)
    kept: list[RotationCandidate] = []
    for c in candidates:
        if all(_haversine_km(c.lat, c.lon, k.lat, k.lon) > min_sep_km for k in kept):
            kept.append(c)
    return kept


def _haversine_km(lat1, lon1, lat2, lon2) -> float:
    r = 6371.0
    p1, p2 = np.radians(lat1), np.radians(lat2)
    dp = np.radians(lat2 - lat1)
    dl = np.radians(lon2 - lon1)
    a = np.sin(dp / 2) ** 2 + np.cos(p1) * np.cos(p2) * np.sin(dl / 2) ** 2
    return 2 * r * np.arcsin(np.sqrt(a))


def candidates_across_sweeps(radar: "pyart.core.Radar", **kwargs) -> list[RotationCandidate]:
    """Run detection on every sweep and pool results — persistence across
    elevation tilts is a stronger indicator than a single-tilt hit."""
    all_candidates = []
    for sweep in range(radar.nsweeps):
        all_candidates.extend(find_velocity_couplets(radar, sweep=sweep, **kwargs))
    return all_candidates
