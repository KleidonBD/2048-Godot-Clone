extends PanelContainer

signal game_lost

const NUMBER_TILE := preload("res://main_scenes/number_tile.tscn")
const WIN_VALUE : int = 2048

@onready var number_tiles : Node = $NumberTiles
@onready var rows : Array[Node] = $Rows.get_children()
@onready var confetti : GPUParticles2D = %Confetti

var can_input : bool = true

func _ready() -> void:
	ScoreKeeper.win_achieved.connect(func() -> void:
		confetti.emitting = true
		)

func _input(event : InputEvent) -> void:
	if not can_input or not event.is_pressed():
		return
	# Disable new inputs until this one is fully processed.
	can_input = false
	
	# Input spam safety:
	# Check if any animations are still in progress from a previous move and force them to finish.
	while not NumberTile.updating_tweens.is_empty():
		var tween : Tween = NumberTile.updating_tweens[0]
		tween.pause()
		tween.custom_step(1.0)
		tween.finished.emit()
	# Ensure all number tiles have their latest properties (color, position, etc.) before new changes are made.
	get_tree().call_group("number_tiles", "instant_update")
	
	# Bool that indicates whether input resulted in any change to the board.
	var move_made : bool = false
	
	# Input handling.
	if event.is_action_pressed("ui_left"):
		for i : int in range(1, 5):
			if slide_row(get_row(i)):
				move_made = true
	elif event.is_action_pressed("ui_right"):
		for i : int in range(1, 5):
			if slide_row(get_row(i), true):
				move_made = true
	elif event.is_action_pressed("ui_up"):
		for i : int in range(1, 5):
			if slide_row(get_column(i)):
				move_made = true
	elif event.is_action_pressed("ui_down"):
		for i : int in range(1, 5):
			if slide_row(get_column(i), true):
				move_made = true
	
	if move_made:
		# Tell all number tiles to animate to their new properties (position, value, color).
		get_tree().call_group(NumberTile.GROUP_NAME, "update")
		# Only generate a new tile if the board changed this input.
		generate_tile()
	
	# Allow new inputs to be made now that function is done.
	can_input = true

func generate_board() -> void:
	clear_board()
	# I don't know why but the board doesn't generate properly the first time without this delay here.
	await get_tree().create_timer(0.1).timeout
	generate_tile()
	generate_tile()

func generate_tile() -> void:
	# Roll value of generated tile. 90% chance to be 2, 10% to be 4.
	var val : int = 4 if randf() <= 0.1 else 2
	
	# Generate an Array of all empty squares on the board.
	var empty_squares : Array[Square] = get_empty_squares()
	
	# Randomly choose an empty square from the array.
	var square : Square = empty_squares.pick_random()
	# Instantiate a new number tile.
	var number_tile : NumberTile = NUMBER_TILE.instantiate()
	# Add the number tile to the NumberTiles node.
	# The NumberTiles node is a basic Node so its children's positions are independant of parent Control nodes.
	number_tiles.add_child(number_tile)
	# Assign the new number tile to the chosen square.
	square.number_tile = number_tile
	# Move the new number tile to the square's position.
	number_tile.global_position = square.global_position
	# Call the new number tile's spawn function to set its initial properties and trigger its animation.
	number_tile.spawn(square, val)
	# Erase the randomly chosen square from the empty_squares Array, as it is no longer empty.
	empty_squares.erase(square)
	
	# Once a tile is generated, a loss check is performed if there are no empty squares on the board.
	if empty_squares.is_empty() and loss_check():
		game_lost.emit()

func get_empty_squares() -> Array[Square]:
	var empty_squares : Array[Square] = []
	for i : int in range(1, 5):
		for square : Square in get_row(i):
			if square.is_empty():
				empty_squares.append(square)
	return empty_squares

func clear_board() -> void:
	# Delete every number tile and unassign them from their squares.
	for tile : NumberTile in number_tiles.get_children():
		var square : Square = tile.current_square
		square.number_tile = null
		tile.queue_free()

func loss_check() -> bool:
	# Anonymous function to check a single row for adjacent number tiles that are identical.
	# If two number tiles of the same value are adjacent, they can be merged and thus another move can be made.
	var check_row_movable : Callable = func(row : Array[Square]) -> bool:
		var last_square : Square = null
		for square : Square in row:
			if last_square and last_square.number_tile.next_value == square.number_tile.next_value:
				return true
			else:
				last_square = square
		return false
	# Call the anonymous function on every row and column. Returns false (i.e. not a loss) if at least
	# one row or column is moveable.
	for i : int in range(1, 5):
		var row : Array[Square] = get_row(i)
		var column : Array[Square] = get_column(i)
		if check_row_movable.call(row) or check_row_movable.call(column):
			return false # The game is not yet lost as another move can still be made.
	return true # The game is lost as there are no more possible moves to be made.

func slide_row(row : Array[Square], reverse : bool = false) -> bool:
	var changed : bool = false
	if reverse:
		row.reverse()
	
	# For every number tile in the row of squares, calculate its new position and whether it gets merged.
	# This occurs from first-to-last as later tiles are trying to move toward the first.
	for i : int in len(row):
		# If the current square is empty, there is no number tile to check and so it will move to the next.
		var current_square : Square = row[i]
		if current_square.is_empty():
			continue
		var previous_i : int = i - 1
		
		# For every square before the current number tile, the number tile will check if it can move to it.
		while previous_i >= 0:
			var current_tile : NumberTile = current_square.number_tile
			var previous_square : Square = row[previous_i]
			if previous_square.is_empty():
				# Set the current tile's next square to the previous square because it is empty.
				# Once all number tiles are called to update at the end of the move,
				# this tile will animate to its next square and its next square will become its current square.
				current_tile.next_square = previous_square
				# Assign the number tile to its new square.
				previous_square.number_tile = current_tile
				# Unassign the number tile from the square it is no longer occupying.
				current_square.number_tile = null
				# Set the new square to the current square so the loop can check if the tile can move again.
				current_square = previous_square
				# A square has been made, so changed is set to true.
				changed = true
				# The previous index is subtracted so the loop can check the number tile again in its new square.
				previous_i -= 1
			elif previous_square.number_tile.can_merge and \
			previous_square.number_tile.current_value == current_tile.current_value:
				# If the previous square's number tile has not merged this turn and its value is identical to
				# the current square's number tile, the current square will merge into the previous square.
				
				var previous_tile : NumberTile = previous_square.number_tile
				# Double the value of the previous tile (i.e. the tile the current one is merging into)
				previous_tile.next_value = previous_tile.current_value * 2
				# Set the current tile's next square to the previous square so it knows to move to it.
				current_tile.next_square = previous_square
				# Set the current_tile as merged so it knows to delete itself after it moves to its new square.
				current_tile.merged = true
				# Set the previous tile's can_merge value so it cannot merge multiple times in a single move.
				# e.g. row of [2, 2, 0, 4] will result in [4, 4, 0, 0] instead of [8, 0, 0, 0].
				previous_tile.can_merge = false
				# Set the current square's number tile to null since its number tile has moved off of it.
				current_square.number_tile = null
				# A number tile has moved, so a change to the board has been made.
				changed = true
				
				# When a number_tile is merged, score increases by the merged tile's new value (i.e. the total
				# of the two merged tiles.)
				ScoreKeeper.increase_score(previous_tile.next_value)
				# If the merged tile is 2048, a win signal is emitted.
				# A special effect will occur the first time this occurs in a game, but the game will continue.
				if previous_tile.next_value == WIN_VALUE:
					ScoreKeeper.trigger_win()
				break
			else:
				break
	
	# Return whether any tiles in this row moved as a result of this function call.
	return changed

func get_row(row : int) -> Array[Square]:
	if row > 4 or row < 1:
		push_error("Invalid row.")
	
	# For type safety, child squares of the row in the scene tree are assigned to a new, statically-typed Array.
	var row_array : Array[Square] = []
	# 1 is subtracted from the row number because Arrays start from 0 and I numbered rows from 1-4.
	row_array.assign(rows[row - 1].get_children())
	
	return row_array

func get_column(col : int) -> Array[Square]:
	if col > 4 or col < 1:
		push_error("Invalid column.")
	
	var column : Array[Square] = []
	# Assign the index (minus one) of each row to a new Array to get the column of that index.
	for row : Node in rows:
		column.append(row.get_child(col - 1))
	
	return column
