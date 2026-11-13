extends RigidBody2D
class_name Player

signal game_started
signal died
signal scored

@onready var score_sound: AudioStreamPlayer = $ScoreSound
@onready var hit_sound: AudioStreamPlayer = $HitSound
@onready var flap_sound: AudioStreamPlayer = $FlapSound
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

var started := false
var is_alive := true

var flap_force := -340.0
var flap_angular_force := -8.0

var maximum_rotation_up := -30.0
var maximum_rotation_down := 90.0
var falling_angular_velocity = 5.0

# Skin support: "default" uses the spritesheet (bird.png), others use 3 separate textures
var _skin_id := "default"
var _skin_mid: Texture2D = null
var _skin_down: Texture2D = null
var _skin_up: Texture2D = null

const SKIN_TEXTURES := {
	"blue": {
		"mid":  "res://assets/textures/skins/bluebird-midflap.png",
		"down": "res://assets/textures/skins/bluebird-downflap.png",
		"up":   "res://assets/textures/skins/bluebird-upflap.png",
		"scale": Vector2(1.2, 1.2),
	},
	"red": {
		"mid":  "res://assets/textures/skins/redbird-midflap.png",
		"down": "res://assets/textures/skins/redbird-downflap.png",
		"up":   "res://assets/textures/skins/redbird-upflap.png",
		"scale": Vector2(1.2, 1.2),
	},
}

# Called by game.gd after load
func apply_skin(skin_id: String) -> void:
	_skin_id = skin_id

	# Pause animation player first to prevent it from applying frame changes
	animation_player.pause()

	if skin_id == "default" or skin_id not in SKIN_TEXTURES:
		# Set up the default yellow bird with spritesheet
		sprite.hframes = 3
		sprite.vframes = 1
		sprite.texture = load("res://assets/textures/bird.png")
		sprite.scale = Vector2(0.82, 0.82)
		sprite.frame = 1
		_skin_mid = null
		# Resume and play animation for default bird
		animation_player.play("idle")
	else:
		# For custom skins, keep animation paused
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.frame = 0

		var data = SKIN_TEXTURES[skin_id]
		_skin_mid  = load(data["mid"])
		_skin_down = load(data["down"])
		_skin_up   = load(data["up"])
		sprite.texture = _skin_mid
		sprite.scale = data.get("scale", Vector2.ONE)

		# Start flapping animation for custom skins in idle state
		if !started:
			_do_continuous_skin_flap()

func _process(_delta: float) -> void:
	if !started:
		# Animate idle flying with bobbing motion
		sprite.position.y = -5 + sin(Time.get_ticks_msec() * 0.008) * 6.0
	elif started:
		sprite.position.y = 0

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("flap") and is_alive:
		if !started:
			if get_viewport().gui_get_hovered_control() != null:
				return
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
	if _skin_id == "default":
		animation_player.stop()
	sprite.position.y = 0
	game_started.emit()

func flap() -> void:
	linear_velocity.y = flap_force
	angular_velocity = -8.0
	flap_sound.play()
	if _skin_id == "default":
		animation_player.play("flap")
	else:
		_do_skin_flap()

func _do_skin_flap() -> void:
	var skin_scale = SKIN_TEXTURES[_skin_id].get("scale", Vector2.ONE) if _skin_id in SKIN_TEXTURES else Vector2.ONE
	# up → mid → down → mid over ~0.4 s using a short tween
	sprite.texture = _skin_up
	sprite.scale = skin_scale
	var tw := create_tween()
	tw.tween_callback(func():
		if _skin_mid:
			sprite.texture = _skin_mid
			sprite.scale = skin_scale
	).set_delay(0.12)
	tw.tween_callback(func():
		if _skin_down:
			sprite.texture = _skin_down
			sprite.scale = skin_scale
	).set_delay(0.12)
	tw.tween_callback(func():
		if _skin_mid:
			sprite.texture = _skin_mid
			sprite.scale = skin_scale
	).set_delay(0.16)

func _do_continuous_skin_flap() -> void:
	if !started and _skin_id in SKIN_TEXTURES:
		_do_skin_flap()
		# Loop the flapping animation every 0.4 seconds
		await get_tree().create_timer(0.4).timeout
		_do_continuous_skin_flap()

func die() -> void:
	if is_alive:
		is_alive = false
		died.emit()
		hit_sound.play()

func score_point() -> void:
	if is_alive:
		scored.emit()
		score_sound.play()
