extends "res://scripts/enemy_base.gd"

func _ready() -> void:
	speed = 85
	max_health = 100
	health = 100
	contact_damage = 25
	pepper_table = [
		{ "type": 1, "chance": 1 },
	]
	super._ready()
