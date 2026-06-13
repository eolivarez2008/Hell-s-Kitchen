@tool
extends CharacterBody2D

@export var shake_decay := 4.0
@export var look_ahead_distance := 50.0
@export var look_ahead_speed := 3.0
@export var xp_base := 15
@export var xp_growth := 10
@export var attack_range := 450.0:
	set(value):
		attack_range = value
		queue_redraw()

@onready var weapon_left := $WeaponLeft
@onready var weapon_right := $WeaponRight
@onready var body := $Body
@onready var camera := $Camera
@onready var dash_particles: CPUParticles2D = $DashParticles

var _shake_intensity := 0.0
var speed := 200.0
var max_health := 100
var health := 100
var peppers := 0
var spicy_level := 0
var spicy_xp := 0
var is_shielded := false
var shield_duration := 3.0
var shield_timer := 0.0
var _flash_timer: float = 0.0
var _squash_timer: float = 0.0
var _anim_scale: Vector2 = Vector2.ONE
var _time: float = 0.0
var _is_moving: bool = false
var _last_direction := Vector2.ZERO
var _is_dashing: bool = false
var hud: CanvasLayer = null
var skills := [
	{ "req_lvl": 1, "cooldown": 4.0, "max_charges": 3, "current_charges": 3, "current_cooldown": 0.0 },
	{ "req_lvl": 4, "cooldown": 8.0, "max_charges": 3, "current_charges": 3, "current_cooldown": 0.0 },
	{ "req_lvl": 7, "cooldown": 12.0, "max_charges": 3, "current_charges": 3, "current_cooldown": 0.0 },
	{ "req_lvl": 10, "cooldown": 20.0, "max_charges": 3, "current_charges": 3, "current_cooldown": 0.0 }
]

const COLOR_NORMAL := Color(1.0, 1.0, 1.0)
const COLOR_HIT := Color(10.0, 10.0, 10.0)
const FLASH_DURATION: float = 0.1
const SQUASH_DURATION: float = 0.15
const DASH_SPEED: float = 650.0

func _ready() -> void:
	add_to_group("player")
	
	if Engine.is_editor_hint():
		return
		
	if weapon_left:
		weapon_left.init(10, 1.0)
	if weapon_right:
		weapon_right.init(10, 1.5)
	if hud:
		hud.update_health(health, max_health)
		_refresh_hud_locks()

func _refresh_hud_locks() -> void:
	if not hud:
		return
	for i in range(skills.size()):
		var is_locked = spicy_level < skills[i]["req_lvl"]
		hud.update_skill_lock(i, is_locked)

func add_peppers(amount: int) -> void:
	peppers += amount
	_add_xp(amount)

func _add_xp(amount: int) -> void:
	if spicy_level >= 10:
		return
	spicy_xp += amount
	var needed := _xp_for_next_level()
	while spicy_xp >= needed and spicy_level < 10:
		spicy_xp -= needed
		spicy_level += 1
		needed = _xp_for_next_level()
		
		for skill in skills:
			if skill["req_lvl"] == spicy_level:
				skill["current_charges"] = skill["max_charges"]
				
		if hud:
			hud.on_level_up(spicy_level)
			
		_refresh_hud_locks()

func _xp_for_next_level() -> int:
	return xp_base + (spicy_level - 1) * xp_growth

func take_damage(amount: int) -> void:
	if is_shielded:
		return
	health -= amount
	health = max(0, health)
	_flash_timer = FLASH_DURATION
	_squash_timer = SQUASH_DURATION
	_shake_intensity = 15.0
	if hud:
		hud.update_health(health, max_health)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
		
	_time += delta
	_update_nearest_enemy()
	_update_procedural_animations(delta)
	_update_camera_effects(delta)
	_update_skills_cooldown(delta)
	_update_shield(delta)
	
func _update_shield(delta: float) -> void:
	if not is_shielded:
		return
	shield_timer -= delta
	if hud:
		hud.update_shield_progress(shield_timer / shield_duration)
	if shield_timer <= 0.0:
		is_shielded = false
		shield_timer = 0.0
		if hud:
			hud.set_shield_active(false)

func _update_skills_cooldown(delta: float) -> void:
	for i in range(skills.size()):
		var skill = skills[i]
		
		if skill["current_cooldown"] > 0.0:
			skill["current_cooldown"] -= delta
			if skill["current_cooldown"] < 0.0:
				skill["current_cooldown"] = 0.0
					
		if hud:
			var pct = 0.0
			if skill["current_cooldown"] > 0.0:
				pct = skill["current_cooldown"] / skill["cooldown"]
			hud.update_skill_ui(i, skill["current_charges"], skill["max_charges"], pct, skill["current_cooldown"])

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
		
	if event.is_action_pressed("skill_1"): _use_skill(0)
	elif event.is_action_pressed("skill_2"): _use_skill(1)
	elif event.is_action_pressed("skill_3"): _use_skill(2)
	elif event.is_action_pressed("skill_4"): _use_skill(3)

func _use_skill(index: int) -> void:
	var skill = skills[index]
	
	if spicy_level < skill["req_lvl"]:
		return
		
	if skill["current_charges"] <= 0 or skill["current_cooldown"] > 0.0:
		if hud:
			hud.shake_slot(index)
		return
		
	skill["current_charges"] -= 1
	skill["current_cooldown"] = skill["cooldown"]
	
	_trigger_skill_logic(index)

func replenish_skill_charges(index: int, amount: int) -> void:
	if index < skills.size():
		skills[index]["current_charges"] = min(skills[index]["current_charges"] + amount, skills[index]["max_charges"])

func _trigger_skill_logic(index: int) -> void:
	match index:
		0: _activate_dash()
		1: _activate_shield()
		2: print("Compétence 3 activée !")
		3: print("Compétence Ultim activée !")

func _activate_dash() -> void:
	_is_dashing = true
	if dash_particles:
		dash_particles.emitting = true
		
	var dash_dir = Vector2.ZERO
	dash_dir.x = Input.get_axis("move_left", "move_right")
	dash_dir.y = Input.get_axis("move_up", "move_down")
	
	if dash_dir == Vector2.ZERO:
		dash_dir = _last_direction if _last_direction != Vector2.ZERO else Vector2.DOWN
	else:
		dash_dir = dash_dir.normalized()
		
	velocity = dash_dir * DASH_SPEED
	_shake_intensity = max(_shake_intensity, 8.0)
	
	if hud:
		hud.play_dash_effect(dash_dir)
		hud.flash_white()
	
	var tween = create_tween()
	
	tween.tween_callback(func():
		_is_dashing = false
		if dash_particles:
			dash_particles.emitting = false
	).set_delay(0.2)

func _activate_shield() -> void:
	is_shielded = true
	shield_timer = shield_duration
	if hud:
		hud.set_shield_active(true)

func _update_nearest_enemy() -> void:
	var closest_enemy: Node2D = null
	var min_distance := INF
	
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist := global_position.distance_to(enemy.global_position)
			if dist < min_distance and dist <= attack_range:
				min_distance = dist
				closest_enemy = enemy
				
	if weapon_left:
		weapon_left.set_target(closest_enemy)
	if weapon_right:
		weapon_right.set_target(closest_enemy)
		
	queue_redraw()

func _update_camera_effects(delta: float) -> void:
	if not camera:
		return
	var target_camera_pos := Vector2.ZERO
	if _is_moving:
		target_camera_pos = _last_direction * look_ahead_distance
	camera.position = camera.position.lerp(target_camera_pos, look_ahead_speed * delta)
	if _shake_intensity > 0.0:
		_shake_intensity = move_toward(_shake_intensity, 0.0, shake_decay * delta)
		var shake_offset := Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		camera.position += shake_offset

func _update_procedural_animations(delta: float) -> void:
	if not body:
		return
	_flash_timer -= delta
	_squash_timer -= delta
	if _flash_timer > 0.0:
		body.modulate = COLOR_HIT
	else:
		body.modulate = COLOR_NORMAL
	if _squash_timer > 0.0:
		var t: float = _squash_timer / SQUASH_DURATION
		var hit_scale: Vector2 = Vector2(1.0 + 0.4 * t, 1.0 - 0.4 * t)
		_anim_scale = _anim_scale.lerp(hit_scale, 0.5)
		scale = _anim_scale
		return
	if _is_moving:
		var breathe: float = sin(_time * 16.0) * 0.04
		var target_scale: Vector2 = Vector2(1.0 + breathe, 1.0 - breathe)
		_anim_scale = _anim_scale.lerp(target_scale, 0.25)
	else:
		var idle: float = sin(_time * 7.0) * 0.04
		var target_scale: Vector2 = Vector2(1.0 - idle, 1.0 + idle)
		_anim_scale = _anim_scale.lerp(target_scale, 0.12)
	scale = _anim_scale

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	if _is_dashing:
		move_and_slide()
		return
		
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		_is_moving = true
		_last_direction = direction
		if body:
			if direction.x < 0:
				body.flip_h = true
			elif direction.x > 0:
				body.flip_h = false
	else:
		_is_moving = false
	velocity = direction * speed
	move_and_slide()

func _draw() -> void:
	if Engine.is_editor_hint() and typeof(attack_range) == TYPE_FLOAT:
		var circle_color := Color(0.0, 0.6, 0.2, 0.15)
		draw_circle(Vector2.ZERO, attack_range, circle_color)
