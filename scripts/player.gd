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
@onready var body: AnimatedSprite2D = $Body
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
var _is_moving: bool = false
var _last_direction := Vector2.DOWN
var _is_dashing: bool = false
var hud: CanvasLayer = null
var _movement_locked := false

var _enemy_update_timer: float = 0.0
const ENEMY_UPDATE_INTERVAL: float = 0.1

var skills := [
	{ "req_lvl": 1, "cooldown": 4.0, "max_charges": 3, "current_charges": 3, "current_cooldown": 0.0 },
	{ "req_lvl": 4, "cooldown": 8.0, "max_charges": 3, "current_charges": 3, "current_cooldown": 0.0 },
	{ "req_lvl": 7, "cooldown": 12.0, "max_charges": 3, "current_charges": 3, "current_cooldown": 0.0 },
	{ "req_lvl": 10, "cooldown": 20.0, "max_charges": 3, "current_charges": 3, "current_cooldown": 0.0 }
]

const SHOCKWAVE_EFFECT = preload("res://scenes/shockwave_effect.tscn")
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
	_shake_intensity = 5.0
	if hud:
		hud.update_health(health, max_health)
		hud.play_screen_flash(Color(1.0, 0.1, 0.1))

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
		
	_enemy_update_timer -= delta
	if _enemy_update_timer <= 0.0:
		_update_nearest_enemy()
		_enemy_update_timer = ENEMY_UPDATE_INTERVAL
		
	_update_camera_effects(delta)
	_update_skills_cooldown(delta)
	_update_shield(delta)
	_update_sprite_animation()
	
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
	if Engine.is_editor_hint() or _movement_locked:
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
		2: _activate_bomb(350.0, 2, 16.0)
		3: _activate_mind_control()

func _activate_mind_control() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy._dead and randf() <= 0.7:
			enemy.infect()
	if hud:
		hud.play_screen_flash(Color(0.7, 0.1, 0.9))

func _activate_bomb(radius: float, time: float, thickness: float) -> void:
	var wave = SHOCKWAVE_EFFECT.instantiate()
	
	wave.target_radius = radius
	wave.duration = time
	wave.initial_thickness = thickness
	wave.global_position = global_position
	
	get_tree().current_scene.call_deferred("add_child", wave)
	
	_shake_intensity = max(_shake_intensity, radius * 0.05)
	
	_movement_locked = true
	velocity = Vector2.ZERO
	
	var lock_tween = create_tween()
	lock_tween.tween_callback(func():
		_movement_locked = false
	).set_delay(0.5)
	
func _activate_dash() -> void:
	_is_dashing = true
	if dash_particles:
		dash_particles.emitting = true
		
	var dash_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
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
	if _movement_locked:
		if weapon_left: weapon_left.set_target(null)
		if weapon_right: weapon_right.set_target(null)
		return

	var closest_enemy: Node2D = null
	var min_distance := INF
	
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy._dead:
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
	camera.position = camera.position.Dynamic_Lerp(target_camera_pos, look_ahead_speed * delta) if "Dynamic_Lerp" in camera else camera.position.lerp(target_camera_pos, look_ahead_speed * delta)
	if _shake_intensity > 0.0:
		_shake_intensity = move_toward(_shake_intensity, 0.0, shake_decay * delta)
		var shake_offset := Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		camera.position += shake_offset

func _update_sprite_animation() -> void:
	if not body:
		return
		
	var anim_suffix := "front"
	var angle := _last_direction.angle()
	
	if angle >= -PI/4 and angle < PI/4:
		anim_suffix = "right"
	elif angle >= PI/4 and angle < 3*PI/4:
		anim_suffix = "front"
	elif angle >= -3*PI/4 and angle < -PI/4:
		anim_suffix = "back"
	else:
		anim_suffix = "left"
		
	var target_anim := ""
	if _is_moving:
		target_anim = "run_" + anim_suffix
	else:
		target_anim = "idle_" + anim_suffix
		
	if body.animation != target_anim:
		body.play(target_anim)

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	if _is_dashing:
		move_and_slide()
		return
		
	if _movement_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		_is_moving = true
		_last_direction = direction
	else:
		_is_moving = false
	velocity = direction * speed
	move_and_slide()

func _draw() -> void:
	if Engine.is_editor_hint() and typeof(attack_range) == TYPE_FLOAT:
		var circle_color := Color(0.0, 0.6, 0.2, 0.15)
		draw_circle(Vector2.ZERO, attack_range, circle_color)

func set_active(active: bool) -> void:
	_movement_locked = not active
	if not active:
		velocity = Vector2.ZERO
		_is_moving = false
