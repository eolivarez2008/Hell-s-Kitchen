extends "res://scripts/enemy_base.gd"

func _ready() -> void:
	speed = 100
	max_health = 40
	health = 40
	contact_damage = 10
	pepper_table = [
		{ "type": 0, "chance": 1 },
	]
	super._ready()
