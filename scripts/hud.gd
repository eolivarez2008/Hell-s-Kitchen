extends CanvasLayer

@onready var health_bar: ProgressBar = $Container/HealthBar
@onready var pepper_label: Label = $Container/PepperCount
@onready var wave_label: Label = $Container/WaveLabel
@onready var wave_timer: Label = $Container/WaveTimer

func update_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

func update_peppers(amount: int) -> void:
	pepper_label.text = "🌶 " + str(amount)

func update_wave(wave_number: int) -> void:
	wave_label.text = "Vague " + str(wave_number)

func update_timer(seconds_remaining: float) -> void:
	wave_timer.text = "⏱ " + str(int(ceil(seconds_remaining))) + "s"
