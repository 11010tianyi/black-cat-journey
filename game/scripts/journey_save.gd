class_name JourneySave
extends RefCounted

## Tiny JSON save file. One slot is enough for a linear journey: the last
## checkpoint reached plus whatever little state the story needs.

const PATH := "user://journey.save"

static func exists() -> bool:
	return FileAccess.file_exists(PATH)

static func read() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}

static func write(data: Dictionary) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("无法写入存档: %s" % PATH)
		return
	file.store_string(JSON.stringify(data))
	file.close()

static func clear() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

static func position_of(data: Dictionary) -> Vector3:
	var raw: Variant = data.get("position")
	if raw is Array and raw.size() == 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.ZERO
