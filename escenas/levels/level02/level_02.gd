extends Node2D

## Cantidad de vidas para este nivel específico.
## Sobreescribe el max_lives del GameManager al cargar el nivel.
@export var lives_for_this_level: int = 3

func _ready() -> void:
	# Le decimos al GameManager cuántas vidas tiene este nivel ANTES de reset_game()
	GameManager.max_lives = lives_for_this_level
	GameManager.reset_game()
