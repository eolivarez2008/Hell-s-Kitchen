@tool
extends Node2D

const ARENA_CENTER := Vector2(640, 360)
const ARENA_RX := 840.0
const ARENA_RY := 730.0

var _heat_lines: Array = []
var _spawn_timer: float = 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		for i in range(5):
			_spawn_heat_line(randf_range(200, 500))

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return

	_spawn_timer += delta
	if _spawn_timer >= 0.8:
		_spawn_timer = 0.0
		_spawn_heat_line()

	var i := _heat_lines.size() - 1
	while i >= 0:
		var line = _heat_lines[i]
		line.life += delta
		line.pos.y -= 40.0 * delta
		line.pos.x += sin(line.life * 5.0) * 0.5
		if line.life >= line.max_life:
			_heat_lines.remove_at(i)
		i -= 1

func _spawn_heat_line(start_y: float = 550.0) -> void:
	_heat_lines.append({
		"pos": Vector2(randf_range(300, 900), start_y),
		"length": randf_range(30, 60),
		"life": 0.0,
		"max_life": randf_range(1.5, 2.5),
		"speed_scale": randf_range(3.0, 6.0)
	})

func clamp_to_arena(pos: Vector2) -> Vector2:
	var offset := pos - ARENA_CENTER
	var nx: float = offset.x / ARENA_RX
	var ny: float = offset.y / ARENA_RY
	if nx * nx + ny * ny <= 1.0:
		return pos
	var angle: float = atan2(offset.y, offset.x)
	return ARENA_CENTER + Vector2(cos(angle) * ARENA_RX, sin(angle) * ARENA_RY)

func random_spawn_position() -> Vector2:
	var angle: float = randf() * TAU
	var r: float = sqrt(randf())
	return ARENA_CENTER + Vector2(cos(angle) * ARENA_RX * r, sin(angle) * ARENA_RY * r)

func _draw() -> void:
	var center := ARENA_CENTER
	var rx := 980.0
	var ry := 870.0

	draw_rect(Rect2(0, 0, 1280, 720), Color(0.08, 0.08, 0.10))

	_draw_rounded_rect(Rect2(40, 40, 1200, 640), 32.0, Color(0.11, 0.11, 0.14), 16)
	_draw_rounded_rect_outline(Rect2(40, 40, 1200, 640), 32.0, Color(0.20, 0.20, 0.25), 16, 2.0)

	for radius: float in [260.0, 220.0, 180.0]:
		_draw_dashed_circle(Vector2(640, 360), radius, Color(0.22, 0.22, 0.28, 0.7), 72, 10.0, 8.0, 1.5)

	var corner_positions := [
		Vector2(90, 90), Vector2(1190, 90),
		Vector2(90, 630), Vector2(1190, 630)
	]
	for pos: Vector2 in corner_positions:
		draw_circle(pos, 8.0, Color(0.08, 0.35, 0.55, 0.9))
		draw_circle(pos, 4.0, Color(0.2, 0.7, 1.0, 0.9))

	for k: int in range(12):
		var angle: float = (TAU / 12.0) * k
		var p_in := Vector2(640, 360) + Vector2(cos(angle), sin(angle)) * 275.0
		var p_out := Vector2(640, 360) + Vector2(cos(angle), sin(angle)) * 295.0
		draw_line(p_in, p_out, Color(0.30, 0.30, 0.38, 0.8), 1.5, true)

	_draw_ellipse_flat(center + Vector2(25, 25), rx, ry, Color(0.0, 0.0, 0.0, 0.35), 64)

	var handle_pts := PackedVector2Array([
		Vector2(1090, 335), Vector2(1255, 320),
		Vector2(1262, 348), Vector2(1262, 375),
		Vector2(1255, 392), Vector2(1090, 385)
	])
	var handle_shadow := PackedVector2Array()
	for pt: Vector2 in handle_pts:
		handle_shadow.append(pt + Vector2(5, 6))
	draw_colored_polygon(handle_shadow, Color(0.0, 0.0, 0.0, 0.3))
	draw_colored_polygon(handle_pts, Color(0.22, 0.22, 0.24))
	var handle_top := PackedVector2Array([
		handle_pts[0], handle_pts[1], handle_pts[2],
		handle_pts[0] + Vector2(0, 8)
	])
	draw_colored_polygon(handle_top, Color(0.45, 0.45, 0.48, 0.5))
	draw_polyline(handle_pts, Color(0.12, 0.12, 0.14), 2.0, true)
	draw_line(handle_pts[0], handle_pts[5], Color(0.12, 0.12, 0.14), 2.0, true)
	for rx_rivet: float in [1115.0, 1155.0, 1195.0]:
		draw_circle(Vector2(rx_rivet, 360), 9.0, Color(0.10, 0.10, 0.12))
		draw_circle(Vector2(rx_rivet, 360), 6.0, Color(0.50, 0.50, 0.52))
		draw_circle(Vector2(rx_rivet - 2, 357), 2.0, Color(0.85, 0.85, 0.90))
	for j: int in range(6):
		var gx: float = 1220.0 + j * 6.0
		draw_line(Vector2(gx, 328), Vector2(gx, 390), Color(0.15, 0.15, 0.17), 1.0, true)

	_draw_ellipse_flat(center, rx, ry, Color(0.12, 0.12, 0.12), 80)
	_draw_ellipse_flat(center, rx - 8, ry - 8, Color(0.35, 0.35, 0.35), 80)
	_draw_ellipse_arc(center, rx - 4, ry - 4, Color(1, 1, 1, 0.6), 80, 6.0, 3.5, 5.0)
	_draw_ellipse_flat(center, rx - 24, ry - 24, Color(0.10, 0.10, 0.11), 80)
	_draw_ellipse_arc(center, rx - 140, ry - 140, Color(1, 1, 1, 0.07), 80, 25.0, 3.2, 4.8)

	if not Engine.is_editor_hint():
		for line in _heat_lines:
			var alpha: float = sin((line.life / line.max_life) * PI) * 0.4
			var color := Color(1.0, 1.0, 1.0, alpha)
			_draw_wavy_heat(line.pos, line.length, line.life * line.speed_scale, color)

	_draw_dashed_ellipse(center, rx - 120, ry - 120, Color(1.0, 0.35, 0.0, 0.6), 90, 20.0, 12.0)

func _draw_rounded_rect(rect: Rect2, radius: float, color: Color, corner_segments: int) -> void:
	var pts := PackedVector2Array()
	var corners := [
		Vector2(rect.position.x + radius, rect.position.y + radius),
		Vector2(rect.end.x - radius,      rect.position.y + radius),
		Vector2(rect.end.x - radius,      rect.end.y - radius),
		Vector2(rect.position.x + radius, rect.end.y - radius)
	]
	var start_angles := [PI, -PI / 2.0, 0.0, PI / 2.0]
	for c: int in range(4):
		for s: int in range(corner_segments + 1):
			var angle: float = start_angles[c] + (PI / 2.0) * s / corner_segments
			pts.append(corners[c] + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(pts, color)

func _draw_rounded_rect_outline(rect: Rect2, radius: float, color: Color, corner_segments: int, width: float) -> void:
	var pts := PackedVector2Array()
	var corners := [
		Vector2(rect.position.x + radius, rect.position.y + radius),
		Vector2(rect.end.x - radius,      rect.position.y + radius),
		Vector2(rect.end.x - radius,      rect.end.y - radius),
		Vector2(rect.position.x + radius, rect.end.y - radius)
	]
	var start_angles := [PI, -PI / 2.0, 0.0, PI / 2.0]
	for c: int in range(4):
		for s: int in range(corner_segments + 1):
			var angle: float = start_angles[c] + (PI / 2.0) * s / corner_segments
			pts.append(corners[c] + Vector2(cos(angle), sin(angle)) * radius)
	pts.append(pts[0])
	draw_polyline(pts, color, width, true)

func _draw_dashed_circle(center: Vector2, radius: float, color: Color, segments: int, dash: float, gap: float, width: float) -> void:
	var step: float = TAU / segments
	var drawing: bool = true
	var acc: float = 0.0
	for i: int in range(segments):
		var a1: float = step * i
		var a2: float = step * (i + 1)
		var p1 := center + Vector2(cos(a1), sin(a1)) * radius
		var p2 := center + Vector2(cos(a2), sin(a2)) * radius
		if drawing:
			draw_line(p1, p2, color, width, true)
		acc += (p2 - p1).length()
		if drawing and acc >= dash:
			drawing = false
			acc = 0.0
		elif not drawing and acc >= gap:
			drawing = true
			acc = 0.0

func _draw_ellipse_flat(center: Vector2, rx: float, ry: float, color: Color, segments: int) -> void:
	var pts := PackedVector2Array()
	for i: int in range(segments + 1):
		var angle: float = TAU * i / segments
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, color)	

func _draw_ellipse_arc(center: Vector2, rx: float, ry: float, color: Color, segments: int, width: float, angle_start: float, angle_end: float) -> void:
	var step: float = TAU / segments
	for i: int in range(segments):
		var a1: float = step * i
		if a1 >= angle_start and a1 <= angle_end:
			var a2: float = step * (i + 1)
			var p1 := center + Vector2(cos(a1) * rx, sin(a1) * ry)
			var p2 := center + Vector2(cos(a2) * rx, sin(a2) * ry)
			draw_line(p1, p2, color, width, true)

func _draw_wavy_heat(start_pos: Vector2, length: float, time_offset: float, color: Color) -> void:
	var points := PackedVector2Array()
	var steps := 8
	for i in range(steps):
		var t := float(i) / steps
		var curr_y := start_pos.y - (length * t)
		var curr_x := start_pos.x + sin(t * 4.0 + time_offset) * 8.0
		points.append(Vector2(curr_x, curr_y))
	if points.size() > 1:
		draw_polyline(points, color, 3.0, true)

func _draw_dashed_ellipse(center: Vector2, rx: float, ry: float, color: Color, segments: int, dash: float, gap: float) -> void:
	var step: float = TAU / segments
	var i: int = 0
	var drawing: bool = true
	var acc: float = 0.0
	while i < segments:
		var angle: float = step * i
		var p1 := center + Vector2(cos(angle) * rx, sin(angle) * ry)
		var p2 := center + Vector2(cos(angle + step) * rx, sin(angle + step) * ry)
		if drawing:
			draw_line(p1, p2, color, 4.0, true)
		acc += (p2 - p1).length()
		if drawing and acc >= dash:
			drawing = false
			acc = 0.0
		elif not drawing and acc >= gap:
			drawing = true
			acc = 0.0
		i += 1
