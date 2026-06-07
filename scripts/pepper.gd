extends Area2D

enum Type { GREEN, YELLOW, RED }

const VALUES := {
	Type.GREEN: 5,
	Type.YELLOW: 15,
	Type.RED: 40
}

const COLORS := {
	Type.GREEN: Color(0.2, 0.8, 0.2),
	Type.YELLOW: Color(0.9, 0.8, 0.1),
	Type.RED: Color(0.9, 0.2, 0.2)
}

var type: Type = Type.GREEN
var value: int = 5

var _scale_timer := 0.0
const POP_DURATION := 0.2

func init(t: Type) -> void:
	type = t
	value = VALUES[t]
	scale = Vector2(0.5, 0.5)
	_scale_timer = POP_DURATION
	queue_redraw()

func _process(delta: float) -> void:
	if _scale_timer > 0.0:
		_scale_timer -= delta
		var t := 1.0 - (_scale_timer / POP_DURATION)
		scale = Vector2.ONE * lerp(0.5, 1.0, t)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, COLORS[type])

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.add_peppers(value)
		queue_free()
