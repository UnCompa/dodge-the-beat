# hud.gd
extends CanvasLayer

@onready var lives_label = $HBoxContainer/LivesLabel
@onready var score_label = $HBoxContainer/ScoreLabel

func _ready() -> void:
	# Conectamos las señales del Singleton
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.game_over.connect(_on_game_over)
	
	# Inicializar textos
	_on_lives_changed(GameManager.current_lives)
	_on_score_changed(GameManager.score)

func _on_lives_changed(lives: int) -> void:
	lives_label.text = "Vidas: " + str(lives)
	# Podrías añadir una animación aquí de "daño" en la UI

func _on_score_changed(score: int) -> void:
	score_label.text = "Puntos: " + str(score)

func _on_game_over() -> void:
	# Mostrar pantalla de Game Over
	#$GameOverPanel.show()
	pass
