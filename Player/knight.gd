extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -650.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity 		= 2 * ProjectSettings.get_setting("physics/2d/default_gravity")
var can_dash 		= false
var dashing 		= false
var on_wall 		= false
var wall_jump 		= false
var rotated 		= false
var attack 			= false
var direction 		= 0
var input_x 		= 0
var collide_side 	= 0

var particle

@onready var timer    		= get_node("Timer")
@onready var wall_timer    	= get_node("Wall_Timer")
@onready var sprite 		= get_node("KnightSprite")
@onready var sweep 			= get_node("SweepSprite")
@onready var animator 		= get_node("AnimationPlayer")
@onready var sweep_anim 	= get_node("AnimationSweep")
@onready var sweep_area 	= get_node("SweepSprite/SweepTrigger")

func _on_area_2d_body_entered(body):	
	if body.is_in_group("Wall") :
		var dic = global_position.x - body.global_position.x
		if dic < 0 :
			collide_side = 1
		else:
			collide_side = -1
		on_wall = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("Wall"):
		collide_side = 0
		on_wall = false

func _on_sweep_trigger_area_shape_entered(area_rid, area, area_shape_index, local_shape_index):
	if  area.is_in_group("Hitpoint"):
		var particle_instance = particle.instantiate()
		particle_instance.global_position = (global_position + area.global_position) / 2
		get_tree().current_scene.add_child(particle_instance)
		#for hitfeeling
		Engine.time_scale = 0.15
		timer.start()
		
		if Input.is_action_pressed("Down"):
			velocity.y = JUMP_VELOCITY
			can_dash = true

func _on_wall_timer_timeout():
	wall_jump = false
	wall_timer.stop()

func _on_timer_timeout():
	Engine.time_scale = 1.0
	timer.stop()

func _ready():
	timer.wait_time = 0.019
	wall_timer.wait_time = 0.12
	sweep_area.monitoring = false
	particle = preload("res://particle.tscn")
	sweep_anim.play("Idle")

func _physics_process(delta):
	input_x = Input.get_axis("ui_left", "ui_right")
	
	if wall_jump == false and dashing == false:
		if on_wall:
			direction = collide_side
			can_dash = true
		elif input_x:
			direction = Input.get_axis("ui_left", "ui_right")
	  
	if not is_on_floor():
		if on_wall and velocity.y > 0:
			velocity.y += gravity * delta * 0.5
		else:
			velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("Dash") and can_dash:
		if on_wall:
			direction = -direction
		dashing = true
		can_dash = false
		animator.play("Dash")
	elif sprite.animation == "Dash" and sprite.frame == 6 or sprite.animation != "Dash":
		dashing = false

	if Input.is_action_just_pressed("Jump") and (is_on_floor() or on_wall):
		if on_wall :
			wall_jump = true
			direction = -direction
			wall_timer.start()
		velocity.y = JUMP_VELOCITY
		animator.play("Jump")
	if Input.is_action_pressed("Jump") and velocity.y < 0:
		velocity.y -= gravity * 0.5 * delta
	
	if Input.is_action_just_pressed("Attack"):
		attack = true
		sweep_anim.play("Sweep")
		sweep_area.monitoring = true
		
		if Input.is_action_pressed("Up"):
			#Radian
			sweep.global_rotation = -1.5707
			rotated = true
		elif Input.is_action_pressed("Down") and !is_on_floor():
			sweep.global_rotation = 1.5707
			rotated = true
		else: 
			sweep.rotation = 0.0
			rotated = false
	elif sweep.frame == 4:
		sweep_area.monitoring = false
		sweep_anim.play("Idle")
		sweep.rotation = 0.0
		rotated = false
		attack = false
		
	if dashing:
		velocity.x = 3 * direction * SPEED
	else:
		if wall_jump: 
			velocity.x = 2 * direction * SPEED
		else:
			velocity.x = input_x * SPEED
		
		if velocity.y == 0:
			if on_wall :
				direction = -direction
				on_wall = false
				
			if attack:
				animator.play("Attack")
			elif input_x != 0:
				animator.play("Walk")
				can_dash = true
			else :
				velocity.x = move_toward(velocity.x, 0, SPEED)
				animator.play("Idle")
				on_wall  = false
				can_dash = true
		if velocity.y > 0:
			if on_wall:
				animator.play("Climb")
			elif attack:
				animator.play("Attack")
			else:
				animator.play("Fall")
		elif attack:
				animator.play("Attack")
		
	if direction == -1:
		sprite.flip_h = true
		if on_wall or rotated:
			sweep.flip_h = false
			sweep.position.x = 0
		else:
			sweep.flip_h = true
			sweep.position.x = -106			
	elif direction == 1:
		sprite.flip_h = false
		if on_wall and !rotated:
			sweep.flip_h = true
			sweep.position.x = -106
		else:
			sweep.flip_h = false
			sweep.position.x = 0
			
	move_and_slide()
