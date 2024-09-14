class_name NumberTile extends ColorRect

# A static variable to store all tweens that are still in the middle of their animations.
static var updating_tweens : Array[Tween] = []

# The tile's color based on its value.
@export var colors : Dictionary = {
	2 : Color.CYAN,
	4 : Color.AQUAMARINE,
	8 : Color.SEA_GREEN,
	16 : Color.YELLOW_GREEN,
	32 : Color.GOLD,
	64 : Color.ORANGE,
	128 : Color.MAROON,
	256 : Color.FIREBRICK,
	512 : Color.WEB_MAROON,
	1024 : Color.MEDIUM_VIOLET_RED,
	2048 : Color.DEEP_PINK
}

# The tile's current value.
var current_value : int = 2
# The tile's next value. This will become its current value when the tile is called to update.
var next_value : int = 2
# Whether the tile is able to be merged with (i.e. true if it has not already merged this input.)
var can_merge : bool = true
# Whether the tile is set to merge into another (i.e. it will delete itself after moving into another tile.)
var merged : bool = false

# The square the tile currently occupies.
var current_square : Square = null
# The square the tile will move to once it is called to update.
var next_square : Square = null

@onready var label : Label = %Label

func _ready() -> void:
	# The number_tiles group is used by the board to tell them all to update simultaneously.
	add_to_group("number_tiles")

func update() -> void:
	# If there is no next_square, the tile has not moved and does not neeed to update.
	if next_square == current_square:
		return
	
	# Wait until the tile moves to its new square.
	await move_pos(next_square.global_position).finished
	if merged:
		# Update the value of the tile this one is merging into and then delete this tile.
		next_square.number_tile.update_value()
		queue_free()
	else:
		# Update the next square to be the current square, as this tile has finished moving to it.
		current_square = next_square


func move_pos(new_pos : Vector2) -> Tween:
	# Animate the tile to the new global position.
	var tween : Tween = create_tween()
	tween.tween_property(self, "global_position", new_pos, 0.1)
	# Add this tween to updating_tweens.
	updating_tweens.append(tween)
	# Tell the tween to remove itself from updating_tweens once its animation finishes.
	tween.finished.connect(func() -> void:
		updating_tweens.erase(tween)
		)
	# Return the tween so the calling function can access it and wait for it to finish.
	return tween

func update_value() -> void:
	# This function should only be called if another tile has merged onto it, which means this tile should
	# have a next_value that is different from its current value.
	if current_value == next_value:
		push_error("current_value is the same as next_value, but update_value() was called.")
	
	# Update the current_value to the next value.
	current_value = next_value
	# Reset can_merge so it is able to merge again next turn.
	can_merge = true
	# Update the label to the new value.
	label.text = str(current_value)
	
	# Get the next color based on the new value. Every value from 2-2048 has a preset color.
	# From 4096 on, the color simply gets progressively darker.
	var new_color : Color = colors[current_value] if current_value <= 2048 else color - Color(0.05, 0.05, 0.05, 0)
	
	# Create the tween, add it to updating_tweens, and tell it to remove itself from updating_tweens once its
	# animation finishes.
	var tween : Tween = create_tween()
	updating_tweens.append(tween)
	tween.finished.connect(func() -> void:
		updating_tweens.erase(tween)
		)
	
	# Fade from the current color into the new color.
	tween.tween_property(self, "color", new_color, 0.1)
	# Grow the tile by 15% and then shrink it back to its normal size.
	tween.parallel().tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.05)

func instant_update() -> void:
	# Instantly update all values, skipping animations so a new input can be handled without waiting for them to
	# finish.
	current_square = next_square
	current_value = next_value
	label.text = str(current_value)
	color = colors[current_value] if current_value <= 2048 else color - Color(0.05, 0.05, 0.05, 0)
	global_position = current_square.global_position

# Function called by the board when it instantiates this tile.
func spawn(square : Square, initial_value : int = 2) -> void:
	# Set the tile's first value (it can be either 2 or 4.)
	if not initial_value == 2:
		next_value = initial_value
	current_square = square
	next_square = square
	
	# Instantly update the tile to all of its initial properties (position, color, value)
	instant_update()
	
	# Create a tween, add it to updating_values, and tell it to delete itself when its animation finishes.
	var tween : Tween = create_tween()
	updating_tweens.append(tween)
	tween.finished.connect(func() -> void:
		updating_tweens.erase(tween)
		)
	
	# Start the tile with a size of 0.
	tween.tween_property(self, "scale", Vector2(0, 0), 0)
	# Grow it to 1.2x its normal size for a bit of juice.
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	# While it's growing, spin it.
	tween.parallel().tween_property(self, "rotation_degrees", 360, 0.2)
	# Once it finishes growing and spinning, quickly shrink it down to its normal size.
	tween.tween_property(self, "scale", Vector2(1, 1), 0.05)
	# Reset the rotation degrees to 0, which is identical to 360.
	# If it remains 360, it cannot spin again as it will try going from 360 to 360, which does nothing.
	tween.parallel().tween_property(self, "rotation_degrees", 0, 0)
