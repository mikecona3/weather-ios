from dataclasses import dataclass

import numpy as np

from cell_track import TrackedCell


@dataclass
class PathProjection:
    lead_time_min: float
    lat: float
    lon: float
    radius_km: float  # uncertainty radius at this lead time


def project_path(
    track: TrackedCell,
    lead_times_min: list[float] = (5, 10, 15, 20, 30),
    base_uncertainty_km: float = 1.5,
    growth_km_per_min: float = 0.6,
) -> list[PathProjection]:
    
    velocity = track.velocity_kmh()
    if velocity is None:
        return []

    east_kmh, north_kmh = velocity
    origin = track.latest

    confidence = confidence_factor(track)

    projections = []
    for t_min in lead_times_min:
        t_h = t_min / 60.0
        km_per_deg_lat = 111.0
        km_per_deg_lon = 111.0 * np.cos(np.radians(origin.lat))

        d_lat = (north_kmh * t_h) / km_per_deg_lat
        d_lon = (east_kmh * t_h) / km_per_deg_lon

        radius = (base_uncertainty_km + growth_km_per_min * t_min) * confidence

        projections.append(
            PathProjection(
                lead_time_min=t_min,
                lat=origin.lat + d_lat,
                lon=origin.lon + d_lon,
                radius_km=radius,
            )
        )
    return projections


def confidence_factor(track: TrackedCell, full_confidence_scans: int = 5) -> float:
    n = len(track.history)
    if n >= full_confidence_scans:
        return 1.0
    # linear interpolation from 1.8x (n=2) down to 1.0x (n=full_confidence_scans)
    return 1.8 - (0.8 * (n - 2) / (full_confidence_scans - 2))
