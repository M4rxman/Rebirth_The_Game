extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")



func _on_exit_pressed() -> void:
	get_tree().quit() # Replace with function body.


func _on_credits_pressed() -> void:
	OS.shell_open("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
