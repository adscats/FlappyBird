extends Control

@onready var score_label: Label = $Panel/ScoreLabel
@onready var high_score_label = $Panel/HighScoreLabel
@onready var retry_button: Button = $Panel/RetryButton
func init_screen(score: int, high_score: int, _coins_earned: int, _bank_total: int) -> void:
	score_label.text = "SCORE: " + str(score)
	high_score_label.text = "BEST: " + str(high_score)

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

func _ready() -> void:
	_apply_retro_button_style(retry_button, 48)
	

func _on_retry_button_pressed() -> void:
	get_tree().reload_current_scene()
