extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	OS.shell_open("https://github.com/M4rxman/Rebirth_The_Game")


func _on_body_entered(body: Node3D) -> void:
	# Only free this item if the entered body is the player (node must be in group "player")
	if body and body.is_in_group("player"):
		queue_free()
