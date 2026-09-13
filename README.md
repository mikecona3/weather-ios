# Weather App -> Tornado Tracker

A Python pipeline for detecting rotational (mesocyclone/TVS-like) signatures in
NEXRAD Level II radar data, tracking storm cells over time, and projecting a
short-term forward path with a shrinking uncertainty cone.

## REALITY CHECK: (READ FIRST!)

This is a nowcasting app for the time being. The severe weather (tornado, 
hurricanes, etc) algorithm is not ready for v1. When installed this app 
can provide forecasts and weather data as expected, but to keep expectations
in check this is NOT a severe weather tracking app, yet. 

## Data source

NOAA hosts NEXRAD Level II data free and public on AWS S3:
s3://noaa-nexrad-level2/YYYY/MM/DD/STATION/
No API key needed — it's a public bucket. Station codes are 4-letters.

## Setup

bash
pip install -r requirements.txt
python main.py --station KBGM --mode latest

## Status

v1 scope (this commit):
- [x] Fetch latest/historical scans from AWS
- [ ] Load + plot reflectivity and velocity with Py-ART
- [ ] Basic velocity couplet detection (rotation candidate flagging)
- [ ] Cell tracking across multiple scans
- [ ] Motion extrapolation + uncertainty cone
- [ ] ML classifier layer (v2)
