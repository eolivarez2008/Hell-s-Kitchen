extends CharacterBody2D

const PepperScene := preload("res://scenes/pepper.tscn")

var speed := 120.0
var max_health := 30
var health := 30
var target: Node2D = null
var damage_per_second := 15
var damage_accumulator := 0.0

func init(player: Node2D, h: int, s: float) -> void:
	target = player
	max_health = h
	health = h
	speed = s

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	_drop_pepper()
	queue_free()

func _drop_pepper() -> void:
	var roll := randf()
	var pepper_type: int

	if roll < 0.6:
		pepper_type = 0
	elif roll < 0.9:
		pepper_type = 1
	else:
		pepper_type = 2

	var pepper := PepperScene.instantiate()
	pepper.global_position = global_position
	get_tree().current_scene.add_child(pepper)
	pepper.init(pepper_type)

func _physics_process(delta: float) -> void:
	if target == null:
		return

	var direction := (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_collider() == target:
			damage_accumulator += damage_per_second * delta
			
			if damage_accumulator >= 1.0:
				var damage_to_deal : float = floor(damage_accumulator)
				damage_accumulator -= damage_to_deal
				target.take_damage(int(damage_to_deal))
