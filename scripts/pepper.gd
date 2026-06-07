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

func init(t: Type) -> void:
	type = t
	value = VALUES[t]
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, COLORS[type])

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.add_peppers(value)
		queue_free()
