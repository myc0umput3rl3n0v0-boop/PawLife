extends Node
const SAVE_PATH := "user://save_game.json"
const SAVE_VERSION := 1

func save_game(data: Dictionary) -> bool:
    var out = {"version": SAVE_VERSION, "time": OS.get_unix_time(), "data": data}
    var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f == null:
        return false
    f.store_string(JSON.print(out))
    f.close()
    return true

func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if f == null:
        return {}
    var txt = f.get_as_text()
    f.close()
    var parsed = JSON.parse_string(txt)
    if parsed.error != OK:
        return {}
    var root = parsed.result
    if root.has("data"):
        return root["data"]
    return {}
