extends Area2D

signal chest_opened(reward_type: String)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collect_sound: AudioStreamPlayer = $CollectSound
@onready var particles: GPUParticles2D = $Particles
@onready var label_popup: Label = $LabelPopup

var base_scale: Vector2 = Vector2(2.0, 2.0)

const REWARD_SLOW = "slow"
const REWARD_COINS = "coins"
const REWARD_SCORE = "score"

var base_speed := -215.0
var speed := -215.0
var collected := false

var _bob_origin := 0.0
var _bob_time := 0.0
var _pulse_time := 0.0

const REWARD_DATA := {
	"slow":  {"text": "0.5× SPEED!", "color": Color(0.4, 0.9, 1.0),  "pitch": 0.85},
	"coins": {"text": "+10 COINS!",  "color": Color(1.0, 0.85, 0.1), "pitch": 1.25},
	"score": {"text": "+10 SCORE!",  "color": Color(0.5, 1.0, 0.4),  "pitch": 1.1},
}

func _ready() -> void:
	base_scale = animated_sprite.scale
	label_popup.visible = false
	label_popup.modulate.a = 0.0
	# Start with closed animation
	animated_sprite.play("closed")
	# Defer so global_position is set by spawner before we record origin
	call_deferred("_init_bob")

func _init_bob() -> void:
	_bob_origin = position.y

func _process(delta: float) -> void:
	position.x += speed * delta
	if position.x < -200.0:
		queue_free()
		return

	if not collected:
		# Bob
		_bob_time += delta
		position.y = _bob_origin + sin(_bob_time * TAU / 1.4) * 7.0
		# Pulse brightness
		_pulse_time += delta
		var t := (sin(_pulse_time * TAU / 1.2) + 1.0) * 0.5
		animated_sprite.modulate = Color(1.0 + t * 0.2, 1.0 + t * 0.15, 1.0 - t * 0.1)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not collected:
		collected = true
		speed = 0.0
		$CollisionShape2D.set_deferred("disabled", true)

		# Switch to open animation
		animated_sprite.play("open")

		var reward := _pick_reward()
		_apply_reward(reward)
		_play_open_animation(reward)
		chest_opened.emit(reward)

func _pick_reward() -> String:
	var r := randf()
	if r < 0.34:
		return REWARD_SLOW
	elif r < 0.67:
		return REWARD_COINS
	else:
		return REWARD_SCORE

func _apply_reward(reward: String) -> void:
	match reward:
		REWARD_SLOW:  get_tree().call_group("game", "apply_slow_powerup")
		REWARD_COINS: get_tree().call_group("game", "add_chest_coins", 10)
		REWARD_SCORE: get_tree().call_group("game", "add_bonus_score", 10)

func _play_open_animation(reward: String) -> void:
	var data: Dictionary = REWARD_DATA[reward]
	var color: Color = data["color"]

	if particles.process_material is ParticleProcessMaterial:
		var mat := particles.process_material.duplicate() as ParticleProcessMaterial
		mat.color = color
		particles.process_material = mat
	particles.restart()
	particles.emitting = true

	collect_sound.pitch_scale = data.get("pitch", 1.0)
	collect_sound.play()

	# In-world floating popup at the chest location
	label_popup.text = data["text"]
	label_popup.label_settings.font_color = color
	label_popup.visible = true
	label_popup.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label_popup, "modulate:a", 1.0, 0.08)
	tween.tween_property(label_popup, "position:y", label_popup.position.y - 100.0, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_property(label_popup, "modulate:a", 0.0, 0.15)
	await tween.finished

	# Wait a moment for the open animation to be visible, then disappear
	await get_tree().create_timer(0.001).timeout
	var fade := create_tween()
	fade.tween_property(animated_sprite, "modulate:a", 0.0, 0.3)
	await fade.finished
	queue_free()

func stop() -> void:
	speed = 0.0

func set_speed_scale(speed_scale: float) -> void:
	if not collected:
		speed = base_speed * speed_scale
