extends RefCounted

const CONFIG_PATH := "user://settings.cfg"


static func load_file() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	return config


static func get_value(section: String, key: String, fallback: Variant) -> Variant:
	var config := load_file()
	return config.get_value(section, key, fallback)


static func set_value(section: String, key: String, value: Variant) -> void:
	var config := load_file()
	config.set_value(section, key, value)
	config.save(CONFIG_PATH)


static func set_values(section: String, values: Dictionary) -> void:
	var config := load_file()
	for key in values:
		config.set_value(section, key, values[key])
	config.save(CONFIG_PATH)
