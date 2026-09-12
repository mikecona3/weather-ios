"""
Minimal backend: wraps fetch_forecast.py and serves it as JSON for the
frontend to consume. Also serves the frontend itself so you can run one
process locally.

Run:
    python backend/app.py
Then open http://localhost:5000
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(__file__)), "src"))

from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS

from fetch_forecast import summarize_forecast, get_forecast, get_forecast_discussion, get_active_alerts

app = Flask(__name__, static_folder=os.path.join(os.path.dirname(os.path.dirname(__file__)), "frontend"))
CORS(app)

# Default location: Binghamton, NY area — change or pass ?lat=&lon= per request
DEFAULT_LAT = 42.0987
DEFAULT_LON = -75.9180


@app.route("/")
def index():
    return send_from_directory(app.static_folder, "index.html")


@app.route("/api/forecast")
def api_forecast():
    lat = request.args.get("lat", DEFAULT_LAT, type=float)
    lon = request.args.get("lon", DEFAULT_LON, type=float)
    try:
        summary = summarize_forecast(lat, lon)
        hourly = get_forecast(lat, lon, hourly=True)
        return jsonify({
            "location": summary["location"],
            "updated": summary["updated"],
            "daily_periods": summary["periods"],
            "hourly_periods": hourly["periods"][:12],
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 502


@app.route("/api/discussion")
def api_discussion():
    lat = request.args.get("lat", DEFAULT_LAT, type=float)
    lon = request.args.get("lon", DEFAULT_LON, type=float)
    try:
        summary = summarize_forecast(lat, lon)
        text = get_forecast_discussion(summary["location"]["office"])
        return jsonify({"office": summary["location"]["office"], "text": text})
    except Exception as e:
        return jsonify({"error": str(e)}), 502


@app.route("/api/alerts")
def api_alerts():
    lat = request.args.get("lat", DEFAULT_LAT, type=float)
    lon = request.args.get("lon", DEFAULT_LON, type=float)
    try:
        alerts = get_active_alerts(lat, lon)
        return jsonify({"alerts": alerts})
    except Exception as e:
        return jsonify({"error": str(e)}), 502


if __name__ == "__main__":
    app.run(debug=True, port=5000)
