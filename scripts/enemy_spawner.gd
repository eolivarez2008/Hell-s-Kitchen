extends Node2D

const ENEMY_SCENES := {
	"slimek": preload("res://scenes/enemy_slimek.tscn"),
	"bruto":  preload("res://scenes/enemy_bruto.tscn"),
	"zapper": preload("res://scenes/enemy_zapper.tscn"),
}

const SPAWN_WEIGHTS := {
	"slimek": 0.65,
	"zapper": 0.20,
	"bruto":  0.15,
}

const ARENA_CENTER := Vector2(640, 360)
const ARENA_RX := 840.0
const ARENA_RY := 730.0

const IndicatorScene := preload("res://scenes/indicator.tscn")

var player: Node2D = null
var spawn_interval := 2.0
var health_mult := 1.0
var speed_mult := 1.0

const INDICATOR_DURATION := 0.9

@onready var timer := $SpawnTimer
@onready var arena := $"../Arena"

func init(p: Node2D) -> void:
	player = p

func set_wave_params(interval: float, h_mult: float, s_mult: float) -> void:
	spawn_interval = interval
	health_mult = h_mult
	speed_mult = s_mult

func start() -> void:
	timer.wait_time = spawn_interval
	timer.start()

func stop() -> void:
	timer.stop()

func _on_spawn_timer_timeout() -> void:
	if player == null or arena == null:
		return
	
	var spawn_pos: Vector2 = _random_spawn_position()
	var enemy_key: String = _pick_enemy_type()
	
	_spawn_with_indicator(spawn_pos, enemy_key)

func _random_spawn_position() -> Vector2:
	var angle: float = randf() * TAU
	var r: float = sqrt(randf())
	return ARENA_CENTER + Vector2(cos(angle) * ARENA_RX * r, sin(angle) * ARENA_RY * r)


func _spawn_with_indicator(spawn_pos: Vector2, enemy_key: String) -> void:
	var indicator := IndicatorScene.instantiate() as Sprite2D
	indicator.global_position = spawn_pos
	indicator.modulate = Color(1, 0, 0, 0.8)
	indicator.add_to_group("indicators")
	get_parent().add_child(indicator)
	
	var tween := create_tween().set_loops(3)
	tween.tween_property(indicator, "modulate:a", 0.2, INDICATOR_DURATION / 6.0)
	tween.tween_property(indicator, "modulate:a", 0.8, INDICATOR_DURATION / 6.0)
	
	tween.finished.connect(func():
		if not is_instance_valid(indicator):
			return
		indicator.queue_free()
		if player == null:
			return
		var enemy: Area2D = ENEMY_SCENES[enemy_key].instantiate()
		enemy.global_position = spawn_pos
		get_parent().add_child(enemy)
		enemy.init(player, health_mult, speed_mult)
	)

func _pick_enemy_type() -> String:
	var roll := randf()
	var cumulative := 0.0
	for key in SPAWN_WEIGHTS:
		cumulative += SPAWN_WEIGHTS[key]
		if roll <= cumulative:
			return key
	return "slimek"
