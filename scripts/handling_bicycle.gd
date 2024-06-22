extends CharacterBody3D
#@export var number: int = 5
# behavior parameters, adjust as needed
@export var gravity =-20
@export var wheel_base = 3.3
@export var steering_limit = 70 # front wheel max turning angle (deg)
@export var engine_power = 1
@export var braking = -1
@export var friction = -9
@export var max_vel = 4
@export var max_speed_reverse = 3.0
@export var Goal: Node3D
@export var sensitivity = 1000
@export var slip_speed = 1
@export var traction_slow = 0.75
@export var traction_fast = 0.02
var total_rotation = 0
var left_lean= false
var right_lean= false
var drifting = false
var drift_time = 0.4
var turn = 0
@onready var timer: Timer = $Timer
@onready var bicycle_animated: Node3D = $bicycle_Animated
@onready var character_body: CharacterBody3D = $"."
@onready var ligma: CharacterBody3D = $"."




func _on_timer_timeout() -> void:
	print(velocity)
	velocity+= (velocity*3/4)
	print(velocity)
	print("Nice Drifto!")
	timer.stop()
# Car state properties
var acceleration = Vector3.ZERO  # current acceleration
#var velocity = Vector3.ZERO  # current velocity#
var steer_angle = 0.0  # current wheel angle




func _ready():
	#print("called")
	#add_child(timer)
	#timer.autostart = false
	#timer.wait_time=2
	pass
	

func _physics_process(delta):
	#print(character_body.position)
	if is_on_floor():
		get_input()
		apply_friction(delta)
		calculate_steering(delta)
	acceleration.y = gravity
	if velocity.length() > max_vel and Input.is_action_pressed("pedal"):
		acceleration.x += velocity.x * friction * delta
		acceleration.z += velocity.z * friction * delta
	velocity += acceleration * delta
	#print(velocity.length())
	move_and_slide()

func apply_friction(delta):
	if velocity.length() < 0.2 and acceleration.length() == 0:
		velocity.x = 0
		velocity.z = 0
	var friction_force = velocity * friction * delta
	acceleration.x += friction_force.x
	acceleration.z += friction_force.z
	


func calculate_steering(delta):
	#print(transform.basis)
	var rear_wheel = transform.origin + transform.basis.z * wheel_base / 2.0
	var front_wheel = transform.origin - transform.basis.z * wheel_base / 2.0
	#print(front_wheel,rear_wheel)
	#print(velocity)
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(transform.basis.y.normalized(), steer_angle) * delta
	var new_heading = rear_wheel.direction_to(front_wheel)
	# traction
	#print(drifting, velocity.length())
	if not drifting and velocity.length() > slip_speed and not steer_angle==0 and Input.is_action_pressed("KANSAI DRIFTO"):
		drifting = true
		if timer.is_stopped():
			timer.start()
			#print("timer start")
		if Input.is_action_pressed("turn_left"):
			#bicycle_animated.rotate_z(deg_to_rad(30))
			left_lean= true
		elif Input.is_action_pressed("turn_right"):
			#bicycle_animated.rotate_z(deg_to_rad(-30))
			right_lean= true
		#bicycle_animated.look_at(get_global_transform().origin)
		#print(timer.time_left)
	if drifting:
		if steer_angle == 0:
			drifting = false
			if timer.time_left > 0:
				timer.stop()
				#print("timer stop by steer angle")
			if left_lean:
				bicycle_animated.set_rotation(Vector3(0,0.5,0))
				bicycle_animated.rotate_y(deg_to_rad(187-steering_limit/2))
				#bicycle_animated.rotate_x(deg_to_rad(steering_limit))
				left_lean = false
			if right_lean:
				bicycle_animated.set_rotation(Vector3(0,0.5,0))
				bicycle_animated.rotate_y(deg_to_rad(187-steering_limit/2))
				#bicycle_animated.rotate_x(deg_to_rad(steering_limit))
				right_lean = false
	if drifting and not Input.is_action_pressed("KANSAI DRIFTO"):
		if timer.time_left > 0:
			timer.stop()
			#print("timer stop by not shifting")
		drifting = false
		if left_lean:
			bicycle_animated.set_rotation(Vector3(0,0.5,0))
			bicycle_animated.rotate_y(deg_to_rad(187-steering_limit/2))
			#bicycle_animated.rotate_x(deg_to_rad(steering_limit))
			left_lean = false
		if right_lean:
			bicycle_animated.set_rotation(Vector3(0,0.5,0))
			bicycle_animated.rotate_y(deg_to_rad(187-steering_limit/2))
			#bicycle_animated.rotate_x(deg_to_rad(steering_limit))
			right_lean = false
	# case for increasing lean angle while continuing drift
	if drifting and velocity.length()>slip_speed and steer_angle != 0 and Input.is_action_pressed("KANSAI DRIFTO"):
		drift_time=0.4
		drift_time -= timer.time_left
		total_rotation=bicycle_animated.get_rotation_degrees()
		#print(total_rotation)
		#print(drift_time," and ",timer.time_left)
		#if drift_time==0:
		#	drifting=false
		if abs(total_rotation.z) < 20:
			if left_lean and drifting:
				bicycle_animated.rotate_object_local(Vector3(0, 0, 1),-deg_to_rad(12) * delta)
			if right_lean and drifting:
				bicycle_animated.rotate_object_local(Vector3(0, 0, 1),deg_to_rad(12) * delta)
	var traction = traction_fast if drifting else traction_slow
	#print(new_heading)
	var d = new_heading.dot(velocity.normalized())
	if d > 0:
		velocity = lerp(velocity, new_heading * velocity.length(), traction)
	if d < 0:
		velocity = -new_heading * min(velocity.length(), max_speed_reverse)
	rotate_y(0.5 * steer_angle)
	look_at(transform.origin + new_heading, transform.basis.y)

#func _process(delta: float) -> void:
	#print(velocity.length())
	#$CameraPivot/arrow.look_at(Goal.global_position)
@onready var arrow: Node3D = $CameraPivot/arrow

func set_cam(a):
	arrow.look_at(a)
func _input(event):
	if event is InputEventMouseMotion:
		# rotation.y -= event.relative.x / sensitivity
		$CameraPivot.rotation.y -= event.relative.x / sensitivity
		$CameraPivot.rotation.x -= event.relative.y / sensitivity
		$CameraPivot.rotation.x = clamp($CameraPivot.rotation.x, deg_to_rad(-45), deg_to_rad(90))
		
func get_input():
	turn = Input.get_action_strength("turn_left")
	turn -= Input.get_action_strength("turn_right")
	steer_angle = turn * deg_to_rad(steering_limit)
	acceleration = Vector3.ZERO
	if Input.is_action_pressed("pedal"):
		#print("pedalling")
		acceleration = -transform.basis.z * engine_power
		$bicycle_Animated/AnimationPlayer.play("Animation")
	if Input.is_action_pressed("back_pedal"):
		$bicycle_Animated/AnimationPlayer.play_backwards("Animation")
		acceleration += -transform.basis.z * braking
	if velocity == Vector3.ZERO:
		$bicycle_Animated/AnimationPlayer.pause()
