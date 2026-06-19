extends CanvasLayer

@onready var sky: Parallax2D = $Background/Sky
@onready var bgdecor: Parallax2D = $Background/BGDecor
@onready var middledecor: Parallax2D = $Background/MiddleDecor
@onready var ground: Parallax2D = $Background/Ground
@onready var foreground: Parallax2D = $Background/ForeGround

@onready var progress_bar: ProgressBar = $ProgressBar

var vitesse_sky: float = -5.0
var vitesse_bgdecor: float = -15.0
var vitesse_middledecor: float = -30.0
var vitesse_ground: float = -50.0
var vitesse_foreground: float = -75.0

var cible_scene: String = "res://scenes/main.tscn"
var progression: Array = []

func _ready() -> void:
	ResourceLoader.load_threaded_request(cible_scene)
	
func _process(delta: float) -> void:
	var statut = ResourceLoader.load_threaded_get_status(cible_scene, progression)
	
	match statut:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			progress_bar.value = progression[0] * 100
			
		ResourceLoader.THREAD_LOAD_LOADED:
			var scene_packee = ResourceLoader.load_threaded_get(cible_scene)
			get_tree().change_scene_to_packed(scene_packee)
			
		ResourceLoader.THREAD_LOAD_FAILED:
			print("Erreur critique : Impossible de charger la scène")

	sky.scroll_offset.x += vitesse_sky * delta
	bgdecor.scroll_offset.x += vitesse_bgdecor * delta
	middledecor.scroll_offset.x += vitesse_middledecor * delta
	ground.scroll_offset.x += vitesse_ground * delta
	foreground.scroll_offset.x += vitesse_foreground * delta
