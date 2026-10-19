class_name SlideProfile
extends RefCounted

const PATH = "user://profile.json"
var settings: Dictionary = {"sound": true, "music": true, "sfx_volume": 0.75, "music_volume": 0.35, "haptic": true, "animation": true, "numbers": false, "theme": 0, "language": ""}
var stats: Dictionary = {"numbers": {"wins": 0, "best_time": 0, "best_moves": 0, "four": 0}, "pictures": {"wins": 0, "best_time": 0, "best_moves": 0, "four": 0}}
var daily_wins: Array = []
var picture_records: Dictionary = {}

func load_data() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not data is Dictionary:
		return
	var saved_settings = data.get("settings", {})
	if saved_settings is Dictionary:
		for key in settings:
			if saved_settings.has(key) and typeof(saved_settings[key]) == typeof(settings[key]):
				settings[key] = saved_settings[key]
		# JSON numbers are parsed as floats.
		settings.theme = clampi(int(saved_settings.get("theme", 0)), 0, 7)
		for key in ["sfx_volume", "music_volume"]:
			var value = saved_settings.get(key, settings[key])
			if value is float or value is int:
				settings[key] = clampf(float(value), 0, 1)
	var saved_stats = data.get("stats", {})
	if saved_stats is Dictionary:
		for mode in stats:
			if saved_stats.get(mode) is Dictionary:
				for key in stats[mode]:
					stats[mode][key] = maxi(0, int(saved_stats[mode].get(key, 0)))
	if data.get("daily", []) is Array:
		daily_wins = data.get("daily", [])
	var saved_pictures = data.get("picture_records", {})
	if saved_pictures is Dictionary:
		for picture in saved_pictures:
			if not saved_pictures[picture] is Dictionary:
				continue
			var levels: Dictionary = {}
			for dimension in [3, 4, 5]:
				var value = saved_pictures[picture].get(str(dimension), 0)
				if (value is int or value is float) and is_finite(float(value)) and float(value) > 0:
					levels[str(dimension)] = maxi(1, int(value))
			if not levels.is_empty():
				picture_records[str(picture)] = levels

func picture_best(picture: String, dimension: int) -> int:
	return int(picture_records.get(picture, {}).get(str(dimension), 0))

func save() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"settings": settings, "stats": stats, "daily": daily_wins, "picture_records": picture_records}))

func record_win(photo: bool, seconds: float, moves: int, dimension: int, date: String = "", picture: String = "") -> bool:
	var record: Dictionary = stats["pictures" if photo else "numbers"]
	var duration: int = maxi(1, int(ceil(seconds)))
	var best: bool = int(record.best_time) == 0 or duration < int(record.best_time)
	record.wins = int(record.wins) + 1
	if best:
		record.best_time = duration
	if int(record.best_moves) == 0 or moves < int(record.best_moves):
		record.best_moves = moves
	if dimension == 4:
		record.four = int(record.four) + 1
	if not date.is_empty() and not daily_wins.has(date):
		daily_wins.append(date)
	if photo and not picture.is_empty():
		var previous := picture_best(picture, dimension)
		if previous == 0 or duration < previous:
			if not picture_records.has(picture):
				picture_records[picture] = {}
			picture_records[picture][str(dimension)] = duration
	save()
	return best

func achievements(photo: bool) -> Array[bool]:
	var data: Dictionary = stats["pictures" if photo else "numbers"]
	return [int(data.wins) >= 1, int(data.best_time) > 0 and int(data.best_time) <= 60, int(data.best_moves) > 0 and int(data.best_moves) <= 50, int(data.four) >= 10]
