extends "res://scripts/enemy_base.gd"

func _ready() -> void:
	speed = 95
	max_health = 95
	health = 95
	contact_damage = 30
	pepper_table = [
		{ "type": 1, "chance": 0.5 },
		{ "type": 2, "chance": 0.5 },
	]
	super._ready()
