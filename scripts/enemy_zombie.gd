extends "res://scripts/enemy_base.gd"

func _ready() -> void:
	speed = 60
	max_health = 80
	health = 80
	contact_damage = 15
	pepper_table = [
		{ "type": 0, "chance": 0.7 },
		{ "type": 1, "chance": 0.3 },
	]
	super._ready()
