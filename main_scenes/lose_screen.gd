extends Control

@onready var high_score_label : Label = $VBoxContainer/HighScoreLabel
@onready var score_label : Label = $VBoxContainer/ScoreLabel

func trigger_loss() -> void:
	# Set the lose screen to be completely transparent and then show it.
	modulate = Color(modulate, 0)
	show()
	
	# Wait for a second after a loss is triggered so the player isn't instantly jump-scared with a lose screen
	# after making a move.
	await get_tree().create_timer(1).timeout
	
	# Display the high score and the score they got this game.
	high_score_label.text = "High Score:\n%s" % str(ScoreKeeper.high_score)
	score_label.text = "Your Score:\n%s" % str(ScoreKeeper.current_score)
	
	# Animation to fade the screen in.
	var tween : Tween = create_tween()
	tween.tween_property(self, "modulate", Color(modulate, 1), 1)
