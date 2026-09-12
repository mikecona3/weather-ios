import requests

USER_AGENT = "tornado-tracker-weather-app (contact: replace-with-your-email@example.com)"
BASE_URL = "https://api.weather.gov"


def _headers():
    # NWS API requires a descriptive User-Agent identifying the app; it does
    # not require an API key or auth token.
    return {"User-Agent": USER_AGENT, "Accept": "application/geo+json"}


def get_grid_point(lat: float, lon: float) -> dict:
    """Resolve a lat/lon to its NWS forecast office + grid cell."""
    resp = requests.get(f"{BASE_URL}/points/{lat},{lon}", headers=_headers(), timeout=10)
    resp.raise_for_status()
    return resp.json()["properties"]


def get_forecast(lat: float, lon: float, hourly: bool = False) -> dict:
    """
    Get the forecast for a lat/lon.

    hourly=False -> daily forecast (today, tonight, tomorrow, ... ~7 days,
        each period has a short human-readable summary)
    hourly=True  -> hour-by-hour forecast, ~7 days out, no summary text
    """
    point = get_grid_point(lat, lon)
    url = point["forecastHourly"] if hourly else point["forecast"]
    resp = requests.get(url, headers=_headers(), timeout=10)
    resp.raise_for_status()
    return resp.json()["properties"]


def get_active_alerts(lat: float, lon: float) -> list[dict]:
    """Any active NWS alerts (watches/warnings/advisories) covering this point."""
    resp = requests.get(
        f"{BASE_URL}/alerts/active", params={"point": f"{lat},{lon}"},
        headers=_headers(), timeout=10,
    )
    resp.raise_for_status()
    return resp.json()["features"]


def get_forecast_discussion(office_id: str) -> str:
    """
    The human-written 'Area Forecast Discussion' (AFD) from the local NWS
    office — forecasters explaining their reasoning in plain text. office_id
    is the 3-letter office code from get_grid_point()['cwa'], e.g. 'BGM' for
    Binghamton.
    """
    resp = requests.get(
        f"{BASE_URL}/products/types/AFD/locations/{office_id}",
        headers=_headers(), timeout=10,
    )
    resp.raise_for_status()
    products = resp.json()["@graph"]
    if not products:
        return ""
    latest_id = products[0]["id"]
    detail = requests.get(f"{BASE_URL}/products/{latest_id}", headers=_headers(), timeout=10)
    detail.raise_for_status()
    return detail.json()["productText"]


def summarize_forecast(lat: float, lon: float) -> dict:
    """Convenience wrapper: everything the UI needs in one call."""
    point = get_grid_point(lat, lon)
    daily = get_forecast(lat, lon, hourly=False)
    return {
        "location": {
            "city": point.get("relativeLocation", {}).get("properties", {}).get("city"),
            "state": point.get("relativeLocation", {}).get("properties", {}).get("state"),
            "office": point.get("cwa"),
        },
        "periods": daily["periods"],  # list of ~14 half-day periods (day/night pairs)
        "updated": daily.get("updated"),
    }


if __name__ == "__main__":
    import argparse
    import json

    parser = argparse.ArgumentParser(description="Fetch a NOAA/NWS forecast for a lat/lon")
    parser.add_argument("lat", type=float)
    parser.add_argument("lon", type=float)
    parser.add_argument("--discussion", action="store_true", help="Also print the local forecast discussion")
    args = parser.parse_args()

    summary = summarize_forecast(args.lat, args.lon)
    print(json.dumps(summary, indent=2)[:2000])

    if args.discussion:
        print("\n--- Forecast Discussion ---\n")
        print(get_forecast_discussion(summary["location"]["office"]))
