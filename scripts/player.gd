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
var _skin_loop_id := 0
var _skin_flap_tween: Tween
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
	_skin_loop_id += 1
	if _skin_flap_tween and _skin_flap_tween.is_running():
		_skin_flap_tween.kill()
	animation_player.stop(true)
	sprite.frame = 0

	if skin_id == "default" or skin_id not in SKIN_TEXTURES:
		_skin_mid = null

		sprite.hframes = 3
		sprite.vframes = 1
		sprite.texture = load("res://assets/textures/bird.png")
		sprite.region_enabled = false
		sprite.frame = 0
		sprite.scale = Vector2(0.82, 0.82)

		animation_player.play("idle") # Restore idle animation for the default bird
	else:
		var data: Dictionary = SKIN_TEXTURES[skin_id]

		_skin_mid = load(data["mid"])
		_skin_down = load(data["down"])
		_skin_up = load(data["up"])

		sprite.hframes = 1
		sprite.vframes = 1
		sprite.texture = _skin_mid
		sprite.region_enabled = false
		sprite.frame = 0
		sprite.scale = data.get("scale", Vector2.ONE)

		if not started:
			_start_continuous_skin_flap()


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
	_skin_loop_id += 1
	if _skin_flap_tween and _skin_flap_tween.is_running():
		_skin_flap_tween.kill()
	started = true
	gravity_scale = 1.0
	if _skin_id == "default":
		animation_player.stop()
	sprite.position.y = 0
	game_started.emit()

func flap() -> void:
	linear_velocity.y = flap_force
	angular_velocity = flap_angular_force
	flap_sound.play()

	if _skin_id == "default":
		animation_player.play("flap")
	else:
		_do_skin_flap()

func _do_skin_flap() -> void:
	if _skin_flap_tween and _skin_flap_tween.is_running():
		_skin_flap_tween.kill()

	var skin_id := _skin_id
	var skin_scale: Vector2 = SKIN_TEXTURES[skin_id].get("scale", Vector2.ONE)

	sprite.texture = _skin_up
	sprite.scale = skin_scale

	_skin_flap_tween = create_tween()
	_skin_flap_tween.tween_callback(func():
		if _skin_id == skin_id and _skin_mid:
			sprite.texture = _skin_mid
	).set_delay(0.12)
	_skin_flap_tween.tween_callback(func():
		if _skin_id == skin_id and _skin_down:
			sprite.texture = _skin_down
	).set_delay(0.12)
	_skin_flap_tween.tween_callback(func():
		if _skin_id == skin_id and _skin_mid:
			sprite.texture = _skin_mid
	).set_delay(0.16)


func _start_continuous_skin_flap() -> void:
	_skin_loop_id += 1
	var loop_id := _skin_loop_id
	_do_continuous_skin_flap(loop_id)


func _do_continuous_skin_flap(loop_id: int) -> void:
	while loop_id == _skin_loop_id and not started and _skin_id in SKIN_TEXTURES:
		_do_skin_flap()
		await get_tree().create_timer(0.4).timeout


func die() -> void:
	if is_alive:
		is_alive = false
		died.emit()
		hit_sound.play()

func score_point() -> void:
	if is_alive:
		scored.emit()
		score_sound.play()
#
