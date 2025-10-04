extends Node3D

@export var lifetime: float = 2.0

func _ready():
	pass
	"""
	# Play particles
	if $GPUParticles3D:
		$GPUParticles3D.emitting = true
	
	# Play sound
	if $AudioStreamPlayer3D:
		$AudioStreamPlayer3D.play()
	
	# Auto-remove after lifetime
	var timer = get_tree().create_timer(lifetime)
	await timer.timeout
	queue_free()
	"""
