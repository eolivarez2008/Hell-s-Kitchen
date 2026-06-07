extends Node2D

const EnemyScene := preload("res://scenes/enemy.tscn")

var player: Node2D = null
var spawn_interval := 2.0

@onready var timer := $SpawnTimer

func init(p: Node2D) -> void:
	player = p

func start() -> void:
	timer.wait_time = spawn_interval
	timer.start()

func _on_spawn_timer_timeout() -> void:
	if player == null:
		return
	var enemy := EnemyScene.instantiate()
	enemy.global_position = _random_spawn_position()
	enemy.init(player)
	get_parent().add_child(enemy)

func _random_spawn_position() -> Vector2:
	var random_x := randf_range(0.0, 1280.0)
	var random_y := randf_range(0.0, 720.0)
	
	return Vector2(random_x, random_y)
