extends RigidBody2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var started := false

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("flap"):
		if !started:
			start_game()
		flap()
		
	if linear_velocity.y > 0.0:
		if rotation_degrees <= 90.0:
			angular_velocity = 5.0
		else:
			angular_velocity = 0.0

func start_game() -> void:
	started = true
	gravity_scale = 1.0

func flap() -> void:
	animation_player.play("flap")
