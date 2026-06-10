extends Area2D

enum Type { GREEN, YELLOW, RED }

const VALUES := {
	Type.GREEN: 5,
	Type.YELLOW: 15,
	Type.RED: 40
}

@export var REGIONS := {
	Type.GREEN: Rect2(402, 287, 51, 52),
	Type.YELLOW: Rect2(500, 287, 51, 52),
	Type.RED: Rect2(591, 287, 51, 52) 
}

var type: Type = Type.GREEN
var value: int = 5

var _scale_timer := 0.0
const POP_DURATION := 0.2

var magnet_speed := 350.0
var target_player: CharacterBody2D = null

@onready var body: Sprite2D = $Body

func init(t: Type) -> void:
	type = t
	value = VALUES[t]
	scale = Vector2(0.5, 0.5)
	_scale_timer = POP_DURATION
	
	if body:
		body.region_rect = REGIONS[t]

func _process(delta: float) -> void:
	if _scale_timer > 0.0:
		_scale_timer -= delta
		var t := 1.0 - (_scale_timer / POP_DURATION)
		scale = Vector2.ONE * lerp(0.5, 1.0, t)

func _physics_process(delta: float) -> void:
	if target_player:
		var direction := global_position.direction_to(target_player.global_position)
		global_position += direction * magnet_speed * delta
	else:
		for area in get_overlapping_areas():
			if area.name == "MagnetArea":
				var player_node = area.get_parent()
				if player_node.is_in_group("player"):
					target_player = player_node
					break

func _on_body_entered(body_node: Node) -> void:
	if body_node.is_in_group("player"):
		body_node.add_peppers(value)
		queue_free()
