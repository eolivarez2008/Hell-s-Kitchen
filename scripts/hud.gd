extends CanvasLayer

@onready var health_bar: ProgressBar = $Container/HealthBar
@onready var pepper_label: Label = $Container/PepperCount

func update_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

func update_peppers(amount: int) -> void:
	pepper_label.text = "🌶 " + str(amount)
