class_name Square extends PanelContainer

# Tracking which number tile is currently occupying this square.
# Value is null if no number tile is occupying it (i.e. the square is empty)
var number_tile : NumberTile = null

func is_empty() -> bool:
	if number_tile:
		return false
	return true
