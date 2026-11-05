extends RigidBody2D
class_name Player

signal game_started
signal died
signal scored

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var started := false

var is_alive := true


var flap_force := -340.0
var flap_angular_force := -8.0

var maximum_rotation_up := -30.0
var maximum_rotation_down := 90.0
var falling_angular_velocity = 5.0

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("flap") && is_alive:
		if !started:
			start_game()
		flap()
		
	if rotation_degrees <= maximum_rotation_up:
		rotation_degrees = maximum_rotation_up
		angular_velocity = 0.0
		
	if linear_velocity.y > 0.0:
		if rotation_degrees <= maximum_rotation_down:
			angular_velocity = falling_angular_velocity
		else:
			angular_velocity = 0.0

func start_game() -> void:
	started = true
	gravity_scale = 1.0
	game_started.emit()

func flap() -> void:
	linear_velocity.y = flap_force
	angular_velocity = -8.0
	animation_player.play("flap")
	
func die() -> void:
	if is_alive:
		is_alive = false
		died.emit()
		
func score_point() -> void:
	if is_alive:
		scored.emit()
