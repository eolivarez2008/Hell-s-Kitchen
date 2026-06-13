extends Node2D

@onready var player := $Player
@onready var enemy_spawner := $EnemySpawner
@onready var wave_manager := $WaveManager
@onready var hud := $HUD
@onready var shop := $Shop
@onready var game_over := $GameOver
@onready var death_watch_timer := $DeathWatchTimer

func _ready() -> void:
	if player and hud:
		player.hud = hud
	enemy_spawner.init(player)
	wave_manager.init(enemy_spawner)
	shop.init(player)
	wave_manager.wave_ended.connect(_on_wave_ended)
	wave_manager.wave_started.connect(_on_wave_started)
	shop.closed.connect(_on_shop_closed)
	wave_manager.start_next_wave()

func _check_player_dead() -> void:
	if player.health <= 0:
		game_over.show_game_over(wave_manager.current_wave)

func _process(delta: float) -> void:
	hud.update_health(player.health, player.max_health)
	hud.update_peppers(player.peppers)
	hud.update_timer(wave_manager.time_remaining)
	hud.update_spicy(player.spicy_level, player.spicy_xp, player._xp_for_next_level())

func _on_wave_started(wave_number: int) -> void:
	hud.update_wave(wave_number)

func _on_wave_ended(wave_number: int) -> void:
	_clear_enemies()
	_regen_player()
	shop.open()

func _on_shop_closed() -> void:
	wave_manager.start_next_wave()

func _clear_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()

func _regen_player() -> void:
	player.health = player.max_health
