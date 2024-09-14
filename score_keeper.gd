extends Node

signal score_updated(new_score : int)
signal win_achieved

# The highest score achieved by the player this session.
var high_score : int = 0
# The score of the current game the player is playing.
var current_score : int = 0
# Whether a 2048 tile has been achieved this game yet.
var game_won : bool = false

func increase_score(amount : int) -> void:
	# Increase the score by the amount.
	current_score += amount
	# Update the high score if the current score is higher than it.
	if current_score > high_score:
		high_score = current_score
	# Signal emitted so labels can update their text to the current score.
	score_updated.emit(current_score)

func trigger_win() -> void:
	# If the game has not been won already, emit the signal and set game_won to true.
	if not game_won:
		game_won = true
		win_achieved.emit()

func reset_score() -> void:
	# Reset the values to default for a new game.
	current_score = 0
	game_won = false
