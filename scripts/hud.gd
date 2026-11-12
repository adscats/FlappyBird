extends CanvasLayer

signal shop_pressed

@onready var score_label: Label = $ScoreLabel
@onready var start_message: TextureRect = $StartMessage
@onready var shop_button: Button = $ShopButton
@onready var game_over_screen: Control = $GameOverScreen
@onready var bank_label: Label = $BankCoins/BankLabel
@onready var bank_coin_icon: TextureRect = $BankCoins/BankCoinIcon
@onready var powerup_notification: Label = $PowerupNotification
@onready var slow_indicator: Label = $SlowIndicator

var _notification_tween: Tween = null
var _slow_pulse_tween: Tween = null
var _bank_tween: Tween = null
var _bank_ready := false

func _ready() -> void:
	start_message.visible = true
	shop_button.visible = true
	game_over_screen.visible = false
	powerup_notification.visible = false
	powerup_notification.modulate.a = 0.0
	slow_indicator.visible = false
	slow_indicator.modulate.a = 0.0
	_apply_retro_button_style(shop_button, 22)
	shop_button.pressed.connect(func():
		get_viewport().set_input_as_handled()
		shop_pressed.emit()
	)

func _apply_retro_button_style(btn: Button, font_size: int = 20) -> void:
	var font = load("res://assets/fonts/flappyfont.TTF")
	if font:
		btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", font_size)

	var normal_box = StyleBoxFlat.new()
	normal_box.bg_color = Color(0.95, 0.62, 0.1)
	normal_box.border_color = Color(0.2, 0.1, 0.0)
	normal_box.set_border_width_all(3)
	normal_box.corner_radius_top_left = 6
	normal_box.corner_radius_top_right = 6
	normal_box.corner_radius_bottom_left = 6
	normal_box.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", normal_box)

	var hover_box = normal_box.duplicate()
	hover_box.bg_color = Color(1.0, 0.72, 0.2)
	btn.add_theme_stylebox_override("hover", hover_box)

	var pressed_box = normal_box.duplicate()
	pressed_box.bg_color = Color(0.8, 0.5, 0.05)
	btn.add_theme_stylebox_override("pressed", pressed_box)

	var disabled_box = normal_box.duplicate()
	disabled_box.bg_color = Color(0.5, 0.5, 0.5)
	disabled_box.border_color = Color(0.3, 0.3, 0.3)
	btn.add_theme_stylebox_override("disabled", disabled_box)

	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.8))
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7))

func set_score(new_score: int) -> void:
	score_label.text = str(new_score)

func set_bank_coins(amount: int) -> void:
	bank_label.text = str(amount)
	if _bank_ready:
		_punch_bank_coins()
	else:
		_bank_ready = true

func _punch_bank_coins() -> void:
	if _bank_tween:
		_bank_tween.kill()
	bank_coin_icon.pivot_offset = bank_coin_icon.size / 2.0
	_bank_tween = create_tween()
	_bank_tween.tween_property(bank_coin_icon, "scale", Vector2(1.35, 1.35), 0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bank_tween.tween_property(bank_coin_icon, "scale", Vector2(1.0, 1.0), 0.12) \
		.set_trans(Tween.TRANS_SINE)

func hide_start_message() -> void:
	shop_button.visible = false
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(start_message, "modulate:a", 0.0, 0.5)

func show_game_over_screen(score: int, high_score: int, coins_earned: int, bank_total: int) -> void:
	game_over_screen.init_screen(score, high_score, coins_earned, bank_total)
	game_over_screen.modulate.a = 0.0
	game_over_screen.visible = true
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(game_over_screen, "modulate:a", 1.0, 0.5)

# ── Power-Up UI Feedback ─────────────────────────────────────────────────────

func show_powerup_message(msg: String, color: Color = Color.WHITE) -> void:
	if _notification_tween:
		_notification_tween.kill()

	powerup_notification.text = msg
	powerup_notification.label_settings.font_color = color
	powerup_notification.visible = true
	powerup_notification.modulate.a = 0.0
	powerup_notification.scale = Vector2(0.6, 0.6)
	powerup_notification.pivot_offset = powerup_notification.size / 2.0

	_notification_tween = create_tween()
	# Pop in with slight overshoot
	_notification_tween.tween_property(powerup_notification, "modulate:a", 1.0, 0.12)
	_notification_tween.parallel().tween_property(powerup_notification, "scale", Vector2(1.1, 1.1), 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_notification_tween.tween_property(powerup_notification, "scale", Vector2(1.0, 1.0), 0.08)
	# Hold at top of screen above score
	_notification_tween.tween_interval(0.85)
	# Smooth fade out
	_notification_tween.tween_property(powerup_notification, "modulate:a", 0.0, 0.25)
	_notification_tween.parallel().tween_property(powerup_notification, "scale", Vector2(0.85, 0.85), 0.25)
	_notification_tween.tween_callback(func(): powerup_notification.visible = false)

func show_slow_indicator(active: bool) -> void:
	if _slow_pulse_tween:
		_slow_pulse_tween.kill()

	if active:
		slow_indicator.visible = true
		slow_indicator.modulate.a = 1.0
		# Gentle pulsing glow bound to HUD node
		_slow_pulse_tween = create_tween().set_loops()
		_slow_pulse_tween.tween_property(slow_indicator, "modulate:a", 0.4, 0.5).set_trans(Tween.TRANS_SINE)
		_slow_pulse_tween.tween_property(slow_indicator, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	else:
		var fade := create_tween()
		fade.tween_property(slow_indicator, "modulate:a", 0.0, 0.3)
		fade.tween_callback(func(): slow_indicator.visible = false)
