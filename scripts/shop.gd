extends CanvasLayer

signal closed

@onready var fa_font: Font = preload("res://assets/fonts/fa-solid-900.woff2")

const ICON_HEALTH: String = "\uf004"
const ICON_SPEED: String = "\uf70c"
const ICON_DAMAGE: String = "\uf255"
const ICON_FIRERATE: String = "\uf0e7"
const ICON_PEPPER: String = "\U00f816"

const ITEMS := [
	{ "id": "max_health",    "label": " Vie Max +20",      "icon": ICON_HEALTH,   "cost": 30 },
	{ "id": "speed",         "label": " Vitesse +20",      "icon": ICON_SPEED,    "cost": 25 },
	{ "id": "damage_left",   "label": " Dégâts G +5",      "icon": ICON_DAMAGE,   "cost": 20 },
	{ "id": "damage_right",  "label": " Dégâts D +5",      "icon": ICON_DAMAGE,   "cost": 20 },
	{ "id": "firerate_left", "label": " Cadence G +0.1",   "icon": ICON_FIRERATE, "cost": 35 },
	{ "id": "firerate_right","label": " Cadence D +0.1",   "icon": ICON_FIRERATE, "cost": 35 },
]

var _player: Node = null

@onready var pepper_display := $Panel/Layout/PepperDisplay
@onready var items_grid := $Panel/Layout/ItemsGrid
@onready var close_button := $Panel/Layout/CloseButton

func init(player: Node) -> void:
	_player = player

func open() -> void:
	_refresh_display()
	visible = true
	get_tree().paused = true

func _refresh_display() -> void:
	pepper_display.text = ICON_PEPPER + " " + str(_player.peppers)
	
	if fa_font:
		pepper_display.add_theme_font_override("font", fa_font)

	for child in items_grid.get_children():
		child.queue_free()

	for item in ITEMS:
		var btn := Button.new()
		btn.text = item["icon"] + item["label"] + "\n" + ICON_PEPPER + " " + str(item["cost"])
		btn.custom_minimum_size = Vector2(200, 60)
		
		if fa_font:
			btn.add_theme_font_override("font", fa_font)
			
		btn.pressed.connect(_on_item_pressed.bind(item))
		items_grid.add_child(btn)

func _on_item_pressed(item: Dictionary) -> void:
	if _player.peppers < item["cost"]:
		return
	_player.peppers -= item["cost"]
	_apply_upgrade(item["id"])
	_refresh_display()

func _apply_upgrade(id: String) -> void:
	match id:
		"max_health":
			_player.max_health += 20
			_player.health = min(_player.health + 20, _player.max_health)
		"speed":
			_player.speed += 20.0
		"damage_left":
			_player.weapon_left.damage += 5
		"damage_right":
			_player.weapon_right.damage += 5
		"firerate_left":
			_player.weapon_left.fire_rate = maxf(0.2, _player.weapon_left.fire_rate - 0.1)
		"firerate_right":
			_player.weapon_right.fire_rate = maxf(0.2, _player.weapon_right.fire_rate - 0.1)

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	if fa_font:
		close_button.add_theme_font_override("font", fa_font)

func _on_close_pressed() -> void:
	visible = false
	get_tree().paused = false
	emit_signal("closed")
