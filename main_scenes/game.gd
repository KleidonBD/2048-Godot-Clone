extends Node


@onready var score_label : Label = $PlayArea/ScoreLabel
@onready var play_area : VBoxContainer = $PlayArea
@onready var menu : VBoxContainer = $Menu
@onready var board : PanelContainer = $PlayArea/Board
@onready var high_score_label : Label = $Menu/HighScoreLabel
@onready var start_button : Button = $Menu/StartButton
@onready var lose_screen : Control = $LoseScreen
@onready var new_game_button : Button = $LoseScreen/VBoxContainer/NewGameButton
@onready var return_button : Button = $LoseScreen/VBoxContainer/ReturnButton
@onready var reset_button: Button = $PlayArea/Spacer/ResetButton


func _ready() -> void:
	# Ensure the score and high score labels display 0 on startup.
	score_label.text = str(0)
	high_score_label.text = "High Score:\n%s" % str(ScoreKeeper.high_score)
	
	# Signal to update the score label when the score is updated.
	ScoreKeeper.score_updated.connect(func(score : int) -> void:
		score_label.text = str(score)
		)
	
	# Start the game when the start game button is pressed.
	start_button.pressed.connect(start_game)
	
	# Start a new game from the lose screen when the new game button is pressed.
	new_game_button.pressed.connect(func() -> void:
		lose_screen.hide()
		start_game()
		)
	
	# Reload the scene from the lose screen when the "Return to main menu" button is pressed.
	# This works because the game starts from the main menu, and the ScoreKeeper autoload does not get reloaded.
	return_button.pressed.connect(get_tree().reload_current_scene)
	
	# Start a new game from the play area when the new game (reset) button is pressed.
	reset_button.pressed.connect(start_game)
	
	# Show the lose screen when the game is lost.
	board.game_lost.connect(lose_screen.trigger_loss)

func start_game() -> void:
	# Hide the menu and show the play area when the game is started.
	menu.hide()
	play_area.show()
	# Ensure the score is reset to 0.
	ScoreKeeper.reset_score()
	score_label.text = str(0)
	# Generate a fresh board.
	board.generate_board()
