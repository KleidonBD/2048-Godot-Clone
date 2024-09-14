extends Button

# Logic to invert font outline colors on hover and preses, as there is no hover or pressed outline color settings
# engine's theme system.

var is_held : bool = false

func _ready() -> void:
	button_down.connect(func() -> void:
		add_theme_color_override("font_outline_color", Color.BLACK)
		is_held = true
		)
	button_up.connect(func() -> void:
		add_theme_color_override("font_outline_color", Color.WHITE)
		is_held = false
		)
	mouse_entered.connect(func() -> void:
		if is_held:
			add_theme_color_override("font_outline_color", Color.BLACK)
		)
	mouse_exited.connect(func() -> void:
		add_theme_color_override("font_outline_color", Color.WHITE)
		)

func _process(_delta: float) -> void:
	force_update_transform()
