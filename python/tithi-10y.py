#!/usr/bin/env python3

# tithi_list_10_years.py

from skyfield.api import load, Topos
from datetime import datetime, timedelta, timezone
import csv

def get_tithi(date: datetime, latitude: float = 28.6139, longitude: float = 77.2090):
	eph = load('de421.bsp')
	ts = load.timescale()
	observer = Topos(latitude_degrees=latitude, longitude_degrees=longitude)
	date_utc = date.astimezone(timezone.utc)
	t = ts.utc(date_utc.year, date_utc.month, date_utc.day, date_utc.hour, date_utc.minute, date_utc.second)
	sun = eph['sun']
	moon = eph['moon']
	earth = eph['earth']
	astrometric_sun = earth.at(t).observe(sun).apparent()
	astrometric_moon = earth.at(t).observe(moon).apparent()
	_, sun_lon, _ = astrometric_sun.ecliptic_latlon()
	_, moon_lon, _ = astrometric_moon.ecliptic_latlon()
	diff = (moon_lon.degrees - sun_lon.degrees) % 360
	tithi_num = int(diff // 12) + 1
	paksha = "Shukla Paksha" if tithi_num <= 15 else "Krishna Paksha"
	tithi_names = [
		"Pratipada", "Dvitiya", "Tritiya", "Chaturthi", "Panchami", "Shashthi", "Saptami", "Ashtami",
		"Navami", "Dashami", "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima/Amavasya"
	]
	tithi_index = (tithi_num - 1) % 15
	tithi_name = tithi_names[tithi_index]
	return tithi_num, tithi_name, paksha

def generate_tithi_list(start_date, years=10, latitude=28.6139, longitude=77.2090, output_file='tithi_list.csv'):
	eph = load('de421.bsp')
	ts = load.timescale()
	sun = eph['sun']
	moon = eph['moon']
	earth = eph['earth']
	tithi_names = [
		"Pratipada", "Dvitiya", "Tritiya", "Chaturthi", "Panchami", "Shashthi", "Saptami", "Ashtami",
		"Navami", "Dashami", "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima/Amavasya"
	]
	with open(output_file, 'w', newline='') as csvfile:
		writer = csv.writer(csvfile)
		writer.writerow(['Date', 'Tithi Number', 'Tithi Name', 'Paksha'])
		for i in range(years * 366):  # Leap years included
			date = start_date + timedelta(days=i)
			date_utc = date.astimezone(timezone.utc)
			t = ts.utc(date_utc.year, date_utc.month, date_utc.day, 0, 0, 0)
			astrometric_sun = earth.at(t).observe(sun).apparent()
			astrometric_moon = earth.at(t).observe(moon).apparent()
			_, sun_lon, _ = astrometric_sun.ecliptic_latlon()
			_, moon_lon, _ = astrometric_moon.ecliptic_latlon()
			diff = (moon_lon.degrees - sun_lon.degrees) % 360
			tithi_num = int(diff // 12) + 1
			paksha = "Shukla Paksha" if tithi_num <= 15 else "Krishna Paksha"
			tithi_index = (tithi_num - 1) % 15
			tithi_name = tithi_names[tithi_index]
			writer.writerow([date.strftime('%Y-%m-%d'), tithi_num, tithi_name, paksha])
		
if __name__ == "__main__":
	# Start from today
	start_date = datetime.now(timezone.utc)
	generate_tithi_list(start_date, years=10, output_file='tithi_list.csv')
	print("Tithi list for the next 10 years has been saved to tithi_list.csv")
	