import matplotlib.pyplot as plt
import pyart

from rotation_detect import RotationCandidate


def plot_scan(
    radar: "pyart.core.Radar",
    sweep: int = 0,
    candidates: list[RotationCandidate] | None = None,
    save_path: str | None = None,
):
    fig = plt.figure(figsize=(14, 6))
    display = pyart.graph.RadarDisplay(radar)

    ax1 = fig.add_subplot(1, 2, 1)
    display.plot(
        "reflectivity", sweep=sweep, ax=ax1, vmin=-20, vmax=70,
        cmap="pyart_NWSRef", colorbar_label="dBZ",
    )

    ax2 = fig.add_subplot(1, 2, 2)
    display.plot(
        "velocity", sweep=sweep, ax=ax2, vmin=-40, vmax=40,
        cmap="pyart_NWSVel", colorbar_label="m/s",
    )

    if candidates:
        for c in candidates:
            # Convert range/azimuth to the display's x/y (km from radar)
            x = c.range_km * __import__("numpy").sin(__import__("numpy").radians(c.azimuth_deg))
            y = c.range_km * __import__("numpy").cos(__import__("numpy").radians(c.azimuth_deg))
            ax2.plot(x, y, "o", markersize=14, markerfacecolor="none",
                     markeredgecolor="black", markeredgewidth=2)
            ax2.annotate(f"{c.shear_ms:.0f} m/s", (x, y), textcoords="offset points",
                         xytext=(8, 8), fontsize=8, color="black")

    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=150)
        print(f"Saved plot to {save_path}")
    else:
        plt.show()
    plt.close(fig)
