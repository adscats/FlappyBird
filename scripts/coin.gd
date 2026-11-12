extends Area2D

@onready var coin_sound: AudioStreamPlayer = $CoinSound
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var particles: GPUParticles2D = $Particles
@onready var label_popup: Label = $LabelPopup

var base_speed := -215.0
var speed := -215.0
var collected := false

var _bob_origin := 0.0
var _bob_time := 0.0

func _ready() -> void:
	animated_sprite.play("spin")
	label_popup.visible = false
	label_popup.modulate.a = 0.0
	call_deferred("_init_bob")

func _init_bob() -> void:
	_bob_origin = position.y

func _process(delta: float) -> void:
	position.x += speed * delta
	if position.x < -200.0:
		queue_free()
		return

	if not collected:
		_bob_time += delta
		position.y = _bob_origin + sin(_bob_time * TAU / 1.1) * 5.0

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not collected:
		collected = true
		speed = 0.0
		$CollisionShape2D.set_deferred("disabled", true)
		animated_sprite.visible = false

		# Pleasant pitch variation
		coin_sound.pitch_scale = randf_range(0.98, 1.06)
		coin_sound.play()

		# Particle sparkle explosion
		particles.restart()
		particles.emitting = true

		get_tree().call_group("game", "add_coin")

		# In-world floating "+1"
		label_popup.visible = true
		label_popup.modulate.a = 0.0
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(label_popup, "modulate:a", 1.0, 0.06)
		tween.tween_property(label_popup, "position:y", label_popup.position.y - 75.0, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.set_parallel(false)
		tween.tween_property(label_popup, "modulate:a", 0.0, 0.15)
		await tween.finished

		queue_free()

func stop() -> void:
	speed = 0.0

func set_speed_scale(speed_scale: float) -> void:
	if not collected:
		speed = base_speed * speed_scale
