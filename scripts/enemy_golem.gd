extends "res://scripts/enemy_base.gd"

func _ready() -> void:
	speed = 40
	max_health = 150
	health = 150
	contact_damage = 20
	pepper_table = [
		{ "type": 2, "chance": 1 },
	]
	super._ready()
