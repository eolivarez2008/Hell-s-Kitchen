extends CharacterBody2D

@export var speed := 120.0
var target: Node2D = null

func init(player: Node2D) -> void:
	target = player

func _physics_process(delta: float) -> void:
	if target == null:
		return

	var direction := (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
