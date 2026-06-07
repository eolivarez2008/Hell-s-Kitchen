extends CharacterBody2D

var speed := 200.0
var max_health := 100
var health := 100
var peppers := 0

const ARENA_MIN := Vector2(40, 40)
const ARENA_MAX := Vector2(1240, 680)

@onready var weapon_left := $WeaponLeft
@onready var weapon_right := $WeaponRight
@onready var hud: CanvasLayer = $"hud"

func _ready() -> void:
	add_to_group("player")
	weapon_left.init(10, 1.0)
	weapon_right.init(10, 1.5)
	if hud:
		hud.update_health(health, max_health)

func add_peppers(amount: int) -> void:
	peppers += amount

func set_nearest_enemy(enemy: Node2D) -> void:
	weapon_left.set_target(enemy)
	weapon_right.set_target(enemy)

func take_damage(amount: int) -> void:
	health -= amount
	health = max(0, health)
	
	if hud:
		hud.update_health(health, max_health)
		
	if health <= 0:
		die()

func die() -> void:
	get_tree().quit()

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()
	position = position.clamp(ARENA_MIN, ARENA_MAX)
