# game_manager.gd
extends Node

# Señales para que la UI y otros nodos se enteren de los cambios
signal lives_changed(new_lives)
signal score_changed(new_score)
signal game_over
signal game_started

@export var max_lives: int = 3

var current_lives: int = 3:
	set(value):
		current_lives = clamp(value, 0, max_lives)
		lives_changed.emit(current_lives)
		if current_lives <= 0:
			game_over.emit()

var score: int = 0:
	set(value):
		score = value
		score_changed.emit(score)

func _ready() -> void:
	reset_game()

func reset_game() -> void:
	current_lives = max_lives
	score = 0
	game_started.emit()

func add_score(amount: int) -> void:
	score += amount
