# Save this as hp_bar_ui.tscn (or create via editor)
# This is the structure you need to create in the Godot editor:

# CanvasLayer
#   └─ MarginContainer
#       └─ VBoxContainer
#           └─ ProgressBar (add to group "hp_bar")

# Here's the GDScript for a custom HP bar if you want more control:
extends ProgressBar

@export var low_hp_threshold: float = 30.0
@export var critical_hp_threshold: float = 15.0

# Colors for different HP states
var normal_color = Color(0.2, 0.8, 0.2)  # Green
var low_color = Color(0.9, 0.7, 0.0)     # Yellow
var critical_color = Color(0.9, 0.1, 0.1) # Red

func _ready():
	add_to_group("hp_bar")
	update_color()

func _process(_delta):
	update_color()

func update_color():
	var hp_percent = (value / max_value) * 100.0
	
	# Create style if it doesn't exist
	if not get_theme_stylebox("fill"):
		var style = StyleBoxFlat.new()
		add_theme_stylebox_override("fill", style)
	
	var style = get_theme_stylebox("fill")
	if style is StyleBoxFlat:
		if hp_percent <= critical_hp_threshold:
			style.bg_color = critical_color
		elif hp_percent <= low_hp_threshold:
			style.bg_color = low_color
		else:
			style.bg_color = normal_color
