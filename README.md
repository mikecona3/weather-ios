# Weather App -> Tornado Tracker 

A Python pipeline for detecting rotational (mesocyclone/TVS-like) signatures in
NEXRAD Level II radar data, tracking storm cells over time, and projecting a
short-term forward path with a shrinking uncertainty cone.

## REALITY CHECK read this first)

This is a nowcasting / decision-support tool, not a replacement for official
NWS warnings. It cannot see a tornado directly — no radar can, due to beam
geometry (the beam widens and rises with range from the radar site). What it
*can* do:

- Flag storm cells with velocity signatures consistent with rotation
- Track those cells scan-to-scan and extrapolate short-term motion
- Produce a tighter, physically-grounded uncertainty cone than a generic
  county-wide warning polygon, especially at short lead times (0-15 min)

Always treat NWS/NOAA warnings as authoritative. This tool is for
experimentation, learning, and (eventually) a supplementary display.

## Project layout

tornado_tracker/
├── README.md
├── requirements.txt
├── src/
│   ├── fetch_nexrad.py      # Pull latest/historical Level II scans from NOAA's AWS bucket
│   ├── rotation_detect.py   # Couplet/TVS-style rotation detection from velocity field
│   ├── cell_track.py        # Storm cell identification + frame-to-frame tracking
│   ├── nowcast.py           # Motion extrapolation + shrinking uncertainty cone
│   └── visualize.py         # Plot reflectivity, velocity, and detected rotation
├── main.py                  # CLI entry point that chains the above
└── data/                    # Downloaded radar scans land here (gitignored)


## Data source

NOAA hosts NEXRAD Level II data free and public on AWS S3:
`s3://noaa-nexrad-level2/YYYY/MM/DD/STATION/`
No API key needed — it's a public bucket. Station codes are 4-letter, e.g.
`KTLX` (Oklahoma City / Twin Lakes), `KBGM` (Binghamton, NY — closest to
upstate NY).

## Setup

bash
pip install -r requirements.txt
python main.py --station KBGM --mode latest

## Status

v1 scope (this commit):
- [x] Fetch latest/historical scans from AWS
- [x] Load + plot reflectivity and velocity with Py-ART
- [x] Basic velocity couplet detection (rotation candidate flagging)
- [ ] Cell tracking across multiple scans
- [ ] Motion extrapolation + uncertainty cone
- [ ] ML classifier layer (v2)

## Note on this environment

This was scaffolded in a sandboxed environment without outbound access to
AWS S3, so the live-fetch path is written and documented but not
network-tested here. Test `fetch_nexrad.py` first thing when you run this
locally — that's the one part relying on live network access to NOAA's bucket.

*NOTE: This is not guaranteed to work at any time, it is an initial commit and a
very early beta of future software. Since I am new to Swift/SwiftUI and iOS dev
work in general this could malfunction at any time, please refer to local media
or government media sites for official warnings/forecasting for severe weather. 
