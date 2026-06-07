extends Node2D

@onready var player := $Player
@onready var enemy_spawner := $EnemySpawner

func _ready() -> void:
	enemy_spawner.init(player)
	enemy_spawner.start()
