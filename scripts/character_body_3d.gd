extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var sensitivity = 1000
@export var Goal: Node3D

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	# if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	# 	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	print(direction)
	if direction:
		velocity.angle_to(direction) 
		# velocity.x = direction.x * SPEED
		rotation.y += direction.x * SPEED * 0.01
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _process(delta: float) -> void:
	$CameraPivot/arrow.look_at(Goal.global_position)
	
func _input(event):
	if event is InputEventMouseMotion:
		# rotation.y -= event.relative.x / sensitivity
		$CameraPivot.rotation.x -= event.relative.y / sensitivity
		$CameraPivot.rotation.x = clamp($CameraPivot.rotation.x, deg_to_rad(-45), deg_to_rad(90))
