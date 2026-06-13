extends CanvasLayer

const ICON_PEPPER: String = "\uf816"
const ICON_WAVE: String = "\uf091"
const ICON_CLOCK: String = "\uf017"

@onready var health_bar: ProgressBar = $HealthBar
@onready var shield_overlay: ProgressBar = $HealthBar/ShieldOverlay
@onready var pepper_label: Label = $PepperCount
@onready var wave_label: Label = $WaveContainer/WaveLabel
@onready var wave_timer: Label = $WaveContainer/WaveTimer
@onready var level_bar: ProgressBar = $SpicyContainer/LevelBar
@onready var level_label: Label = $SpicyContainer/LevelLabel

@onready var slots: Array[Node] = [
	$SkillsContainer/Skill1/Slot1,
	$SkillsContainer/Skill2/Slot2,
	$SkillsContainer/Skill3/Slot3,
	$SkillsContainer/Skill4/Slot4
]

@onready var speed_lines: TextureRect = $SpeedLines

func _ready() -> void:
	update_input_labels()
	speed_lines.visible = false
	speed_lines.pivot_offset = speed_lines.size / 2.0
	if is_instance_valid(health_bar):
		var fill_style: StyleBoxFlat = health_bar.get_theme_stylebox("fill").duplicate()
		health_bar.add_theme_stylebox_override("fill", fill_style)

func play_dash_effect(direction: Vector2) -> void:
	var old_tween = speed_lines.get_meta("dash_tween", null)
	if old_tween and old_tween.is_valid():
		old_tween.kill()

	speed_lines.visible = true
	speed_lines.modulate = Color(1, 1, 1, 0)
	speed_lines.scale = Vector2(1.15, 1.15)

	var tween := create_tween()
	speed_lines.set_meta("dash_tween", tween)

	tween.tween_property(speed_lines, "modulate:a", 1.0, 0.04)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(speed_lines, "scale", Vector2.ONE, 0.15)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	tween.tween_property(speed_lines, "modulate:a", 0.0, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): speed_lines.visible = false)

func flash_white(duration: float = 0.08) -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.35)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)

func update_input_labels() -> void:
	var actions = ["skill_1", "skill_2", "skill_3", "skill_4"]
	
	for i in range(actions.size()):
		if i >= slots.size() or not is_instance_valid(slots[i]):
			continue
			
		var action_name = actions[i]
		var events = InputMap.action_get_events(action_name)
		
		if events.size() > 0:
			var first_event = events[0]
			if first_event is InputEventKey:
				var key_text = OS.get_keycode_string(first_event.physical_keycode)
				
				if key_text == "Escape": key_text = "Esc"
				elif key_text == "Space": key_text = "Space"
				elif key_text == "Control": key_text = "Ctrl"
				elif key_text == "Shift": key_text = "Maj"
				
				var key_label = slots[i].get_parent().get_node("InputContainer/KeyLabel") as Label
				if key_label:
					key_label.text = key_text.to_upper()

func update_health(current: int, maximum: int) -> void:
	if not is_instance_valid(health_bar):
		return
	health_bar.max_value = maximum
	
	var tween := create_tween()
	tween.tween_property(health_bar, "value", current, 0.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

func update_peppers(amount: int) -> void:
	pepper_label.text = ICON_PEPPER + " " + str(amount)

func update_wave(wave_number: int) -> void:
	wave_label.text = ICON_WAVE + " Vague " + str(wave_number)

func update_timer(seconds_remaining: float) -> void:
	wave_timer.text = ICON_CLOCK + " " + str(int(ceil(seconds_remaining))) + "s"

func update_spicy(level: int, current_xp: int, needed_xp: int) -> void:
	if not is_instance_valid(level_bar):
		return
	level_bar.max_value = needed_xp
	
	var tween := create_tween()
	tween.tween_property(level_bar, "value", current_xp, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	level_label.text = "LVL " + str(level)

func on_level_up(level: int) -> void:
	if not is_instance_valid(level_bar):
		return
	level_label.text = "LVL " + str(level)
	
	var tween := create_tween()
	tween.tween_property(level_bar, "modulate", Color(2.0, 1.5, 0.0), 0.1)
	tween.tween_property(level_bar, "modulate", Color.WHITE, 0.4)

func update_skill_lock(slot_index: int, is_locked: bool) -> void:
	if slot_index >= slots.size() or not is_instance_valid(slots[slot_index]):
		return
	var lock_overlay = slots[slot_index].get_node("LockOverlay")
	if lock_overlay:
		lock_overlay.visible = is_locked

func update_skill_ui(slot_index: int, current_charges: int, max_charges: int, cooldown_pct: float, cooldown_time: float) -> void:
	if slot_index >= slots.size() or not is_instance_valid(slots[slot_index]):
		return
		
	var slot = slots[slot_index]
	
	var overlay = slot.get_node("CooldownOverlay")
	var label = slot.get_node("CooldownLabel")
	if overlay and label:
		if cooldown_pct > 0.0:
			overlay.visible = true
			overlay.value = cooldown_pct
			label.visible = true
			label.text = str(snapped(cooldown_time, 0.1)) + "s"
		else:
			overlay.visible = false
			label.visible = false
			
	var charges_container = slot.get_node("Container/Charges") as HBoxContainer
	if charges_container:
		var index := 0
		for child in charges_container.get_children():
			if child is ColorRect:
				child.modulate.a = 1.0 if index < current_charges else 0.2
				child.visible = index < max_charges
				index += 1

func shake_slot(slot_index: int) -> void:
	if slot_index >= slots.size() or not is_instance_valid(slots[slot_index]):
		return
	var slot = slots[slot_index]
	
	var old_tween = slot.get_meta("shake_tween", null)
	if old_tween and old_tween.is_valid():
		old_tween.kill()
		
	var tween := create_tween()
	slot.set_meta("shake_tween", tween)
	
	var duration := 0.04
	var intensity := 5.0
	tween.tween_property(slot, "position:x", slot.position.x + intensity, duration)
	tween.tween_property(slot, "position:x", slot.position.x - intensity, duration)
	tween.tween_property(slot, "position:x", slot.position.x + intensity, duration)
	tween.tween_property(slot, "position:x", slot.position.x, duration)
	
const COLOR_HEALTH_NORMAL := Color(1, 0, 0, 1)
const COLOR_HEALTH_SHIELD := Color(0.2, 0.5, 1.0, 1)

func set_shield_active(active: bool) -> void:
	if not is_instance_valid(health_bar):
		return
	var fill_style: StyleBoxFlat = health_bar.get_theme_stylebox("fill")
	if active:
		fill_style.bg_color = COLOR_HEALTH_SHIELD
		shield_overlay.visible = true
		shield_overlay.value = 1.0
	else:
		fill_style.bg_color = COLOR_HEALTH_NORMAL
		shield_overlay.visible = false

func update_shield_progress(pct: float) -> void:
	if not is_instance_valid(shield_overlay):
		return
	shield_overlay.value = pct
