extends CanvasLayer

const ICON_PEPPER: String = "\uf816"
const ICON_WAVE: String = "\uf091"
const ICON_CLOCK: String = "\uf017"

@onready var health_bar: ProgressBar = $Container/HealthBar
@onready var pepper_label: Label = $Container/PepperCount
@onready var wave_label: Label = $Container/WaveLabel
@onready var wave_timer: Label = $Container/WaveTimer

func update_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

func update_peppers(amount: int) -> void:
	pepper_label.text = ICON_PEPPER + " " + str(amount)

func update_wave(wave_number: int) -> void:
	wave_label.text = ICON_WAVE + " Vague " + str(wave_number)

func update_timer(seconds_remaining: float) -> void:
	wave_timer.text = ICON_CLOCK + " " + str(int(ceil(seconds_remaining))) + "s"
