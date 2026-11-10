extends Area2D

@onready var coin_sound: AudioStreamPlayer = $CoinSound
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var speed := -215.0
var collected := false

func _ready() -> void:
	animated_sprite.play("spin")

func _process(delta: float) -> void:
	position.x += speed * delta
	if position.x < -200.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not collected:
		collected = true
		speed = 0.0
		coin_sound.play()
		animated_sprite.visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		get_tree().call_group("game", "add_coin")
		await coin_sound.finished
		queue_free()

func stop() -> void:
	speed = 0.0
