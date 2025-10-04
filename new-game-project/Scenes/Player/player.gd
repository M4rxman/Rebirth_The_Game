extends CharacterBody3D

var character_state : int 
var character_generation : int = 0

const LERP_VALUE : float = 0.15

var snap_vector : Vector3 = Vector3.DOWN
var speed : float

@export_group("Movement variables")
@export var walk_speed : float = 2.0
@export var run_speed : float = 50.0
@export var jump_strength : float = 15.0
@export var gravity : float = 50.0

const ANIMATION_BLEND : float = 7.0

@onready var spring_arm_pivot : Node3D = $camera_mount
@onready var character_slot = $bodyMesh
@onready var egg_slot = $Egg 

func _ready() -> void:
	character_slot.visible = true
	egg_slot.hide()
	speed = walk_speed

func _physics_process(delta):
	var move_direction : Vector3 = Vector3.ZERO
	move_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	move_direction.z = Input.get_action_strength("move_backwards") - Input.get_action_strength("move_forwards")
	move_direction = move_direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
	
	velocity.y -= gravity * delta
	
	if Input.is_action_pressed("quit"):
		get_tree().quit()
	
	if Input.is_action_pressed("run"):
		speed = run_speed
	else:
		speed = walk_speed
	
	velocity.x = move_direction.x * speed
	velocity.z = move_direction.z * speed
	
	#if move_direction:
		#player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)
	
	var just_landed := is_on_floor() and snap_vector == Vector3.ZERO
	var is_jumping := is_on_floor() and Input.is_action_just_pressed("jump")
	if is_jumping:
		velocity.y = jump_strength
		snap_vector = Vector3.ZERO
	elif just_landed:
		snap_vector = Vector3.DOWN
	
	if Input.is_action_just_pressed("egg_action"):
		switch_to_egg()
	
	apply_floor_snap()
	move_and_slide()
	#animate(delta)

func switch_to_character():
	walk_speed = 2.0
	run_speed = 50.0
	
	speed = walk_speed
	character_slot.visible = true
	egg_slot.visible = false

func switch_to_egg():
	print("swithced to the egg")
	character_generation += 1
	egg_slot.show()
	
	speed = 0
	walk_speed = 0
	run_speed = 0
	
	character_slot.visible = false
	
	egg_slot.hatch()
