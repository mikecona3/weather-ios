"""
This is the true beta - this is not guaranteed to work or function 
correctly at any time. Please be advised.
Storm cell identification with frame to frame tracking. 

Approach: threshold reflectivity to find storm cores, label connected
regions, compute centroids, then match centroids between consecutive scans
by nearest-neighbor (with a max-jump distance to avoid matching unrelated
cells). This is a simplified version of the same idea behind SCIT/TITAN
storm-tracking algorithms.
"""

from dataclasses import dataclass, field

import numpy as np
from scipy import ndimage


@dataclass
class StormCell:
    id: int
    lat: float
    lon: float
    max_dbz: float
    area_km2: float
    timestamp: "object"  # datetime


@dataclass
class TrackedCell:
    id: int
    history: list[StormCell] = field(default_factory=list)

    @property
    def latest(self) -> StormCell:
        return self.history[-1]

    def velocity_kmh(self) -> tuple[float, float] | None:
        """Return (east_kmh, north_kmh) motion estimate from the last two
        observations, or None if there's only one."""
        if len(self.history) < 2:
            return None
        a, b = self.history[-2], self.history[-1]
        dt_h = (b.timestamp - a.timestamp).total_seconds() / 3600.0
        if dt_h <= 0:
            return None
        d_lat = b.lat - a.lat
        d_lon = b.lon - a.lon
        km_per_deg_lat = 111.0
        km_per_deg_lon = 111.0 * np.cos(np.radians((a.lat + b.lat) / 2))
        return (d_lon * km_per_deg_lon / dt_h, d_lat * km_per_deg_lat / dt_h)


def identify_cells(
    reflectivity: np.ndarray,
    lats: np.ndarray,
    lons: np.ndarray,
    timestamp,
    dbz_threshold: float = 40.0,
    min_pixels: int = 4,
) -> list[StormCell]:
    """Threshold + connected-component label reflectivity to find storm cores."""
    mask = np.ma.filled(reflectivity, fill_value=-999) >= dbz_threshold
    labeled, n = ndimage.label(mask)

    cells = []
    for label_id in range(1, n + 1):
        region = labeled == label_id
        if region.sum() < min_pixels:
            continue
        cells.append(
            StormCell(
                id=label_id,
                lat=float(lats[region].mean()),
                lon=float(lons[region].mean()),
                max_dbz=float(np.ma.filled(reflectivity, -999)[region].max()),
                area_km2=float(region.sum()),  # gate count as rough proxy; refine with gate spacing
                timestamp=timestamp,
            )
        )
    return cells


def update_tracks(
    tracks: list[TrackedCell],
    new_cells: list[StormCell],
    max_jump_km: float = 15.0,
) -> list[TrackedCell]:
    """Match new_cells to existing tracks by nearest centroid; start new
    tracks for unmatched cells; drop tracks that go unmatched (storm ended)."""
    used = set()
    next_id = max((t.id for t in tracks), default=0) + 1
    matched_tracks = []

    for track in tracks:
        best, best_dist = None, max_jump_km
        for cell in new_cells:
            if cell.id in used:
                continue
            dist = _haversine_km(track.latest.lat, track.latest.lon, cell.lat, cell.lon)
            if dist < best_dist:
                best, best_dist = cell, dist
        if best:
            track.history.append(best)
            used.add(best.id)
            matched_tracks.append(track)
        # else: track goes unmatched this scan and is dropped (storm cell ended/merged)

    new_tracks = []
    for cell in new_cells:
        if cell.id not in used:
            new_tracks.append(TrackedCell(id=next_id, history=[cell]))
            next_id += 1

    return matched_tracks + new_tracks


def _haversine_km(lat1, lon1, lat2, lon2) -> float:
    r = 6371.0
    p1, p2 = np.radians(lat1), np.radians(lat2)
    dp = np.radians(lat2 - lat1)
    dl = np.radians(lon2 - lon1)
    a = np.sin(dp / 2) ** 2 + np.cos(p1) * np.cos(p2) * np.sin(dl / 2) ** 2
    return 2 * r * np.arcsin(np.sqrt(a))
