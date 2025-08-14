#!/usr/bin/env python3

# tithi_calculator.py

from skyfield.api import load, Topos
from datetime import datetime, timezone

def get_tithi(date: datetime, latitude: float = 28.6139, longitude: float = 77.2090):
	"""
	Calculate the Hindu tithi for a given date and location.
	Default location: New Delhi, India.
	"""
	# Load ephemeris data
	eph = load('de421.bsp')
	ts = load.timescale()
	
	# Set observer location
	observer = Topos(latitude_degrees=latitude, longitude_degrees=longitude)
	
	# Convert date to UTC
	date_utc = date.astimezone(timezone.utc)
	t = ts.utc(date_utc.year, date_utc.month, date_utc.day, date_utc.hour, date_utc.minute, date_utc.second)
	
	# Get positions
	sun = eph['sun']
	moon = eph['moon']
	earth = eph['earth']
	
	astrometric_sun = earth.at(t).observe(sun).apparent()
	astrometric_moon = earth.at(t).observe(moon).apparent()
	
	# Get ecliptic longitude
	_, sun_lon, _ = astrometric_sun.ecliptic_latlon()
	_, moon_lon, _ = astrometric_moon.ecliptic_latlon()
	
	# Calculate angular difference
	diff = (moon_lon.degrees - sun_lon.degrees) % 360
	tithi_num = int(diff // 12) + 1  # 1 to 30
	
	# Determine Paksha
	paksha = "Shukla Paksha" if tithi_num <= 15 else "Krishna Paksha"
	tithi_names = [
		"Pratipada", "Dvitiya", "Tritiya", "Chaturthi", "Panchami", "Shashthi", "Saptami", "Ashtami",
		"Navami", "Dashami", "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima/Amavasya"
	]
	tithi_index = (tithi_num - 1) % 15
	tithi_name = tithi_names[tithi_index]
	
	return {
		"tithi_number": tithi_num,
		"tithi_name": tithi_name,
		"paksha": paksha
	}
	
# Example usage:
if __name__ == "__main__":
	date = datetime(2025, 7, 16, 0, 0, 0, tzinfo=timezone.utc)
	result = get_tithi(date)
	print(result)
	