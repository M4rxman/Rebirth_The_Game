extends TextEdit

@onready var editor = $"."
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Globals.meal*2-Globals.meal>=0:
		editor.text = str((Globals.meal*2)-Globals.meal)
	else:
		editor.text = str(0)
	pass
