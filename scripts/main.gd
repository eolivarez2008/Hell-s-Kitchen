extends Node2D

@onready var player := $Player
@onready var enemy_spawner := $EnemySpawner
@onready var wave_manager := $WaveManager

func _ready() -> void:
	enemy_spawner.init(player)
	wave_manager.init(enemy_spawner)
	wave_manager.wave_ended.connect(_on_wave_ended)
	wave_manager.start_next_wave()

func _process(delta: float) -> void:
	_update_nearest_enemy()

func _update_nearest_enemy() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var min_dist := INF

	for enemy in enemies:
		var dist : float = player.global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy

	player.set_nearest_enemy(nearest)

func _on_wave_ended(wave_number: int) -> void:
	_clear_enemies()
	_regen_player()
	wave_manager.start_next_wave()

func _clear_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()

func _regen_player() -> void:
	player.health = player.max_health
