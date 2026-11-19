extends Control
## O GameSession mostra esta tela e recebe a escolha pelos sinais abaixo.

signal retry_requested
signal restart_requested

@onready var _subtitle: Label = %Subtitle
@onready var _falls_label: Label = %Falls
@onready var _allies_label: Label = %Allies
@onready var _retry_button: Button = %RetryButton
@onready var _restart_button: Button = %RestartButton
@onready var _spores: Control = $Spores

var _falls: int = 0
var _allies: int = 0
var _reason: String = ""
var _time: float = 0.0
var _input_delay: float = 0.3
var _buttons_ready: bool = false
var _choice_made: bool = false
var _spore_origins: Array[Vector2] = []


func setup(falls: int, allies: int, reason: String = "") -> void:
	_falls = maxi(0, falls)
	_allies = maxi(0, allies)
	_reason = reason
	if is_node_ready():
		_refresh_text()


func _ready() -> void:
	# Continua animando e recebendo botões mesmo com a partida pausada.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for spore: ColorRect in _spores.get_children():
		_spore_origins.append(spore.position / Vector2(288.0, 208.0))
	_retry_button.pressed.connect(_on_retry_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_refresh_text()


func _refresh_text() -> void:
	_subtitle.text = _reason if not _reason.is_empty() else "A floresta ainda precisa da sua luz."
	_falls_label.text = "%02d  QUEDAS" % _falls
	_allies_label.text = "%d / 5  ALIADOS" % _allies


func _process(delta: float) -> void:
	_time += delta
	# Pequenos quadrados luminosos: só a interface se move, não o mundo pausado.
	for index: int in _spore_origins.size():
		var spore := _spores.get_child(index) as ColorRect
		var origin: Vector2 = _spore_origins[index] * size
		spore.position = Vector2(
			origin.x + sin(_time * 0.6 + index) * 4.0,
			fposmod(origin.y - _time * (2.0 + index % 3), maxf(size.y, 1.0))
		).round()
		spore.modulate.a = 0.55 + sin(_time * 1.4 + index) * 0.3
	if _buttons_ready or _choice_made:
		return
	_input_delay -= delta
	# Soltar o salto/aceitar evita que o último comando da queda acione o retry.
	if _input_delay <= 0.0 and not Input.is_action_pressed("ui_accept") and not Input.is_action_pressed("jump"):
		_buttons_ready = true
		_retry_button.disabled = false
		_restart_button.disabled = false
		_retry_button.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if not _buttons_ready and (event.is_action("ui_accept") or event.is_action("jump")):
		get_viewport().set_input_as_handled()


func _lock_buttons() -> bool:
	if not _buttons_ready or _choice_made:
		return false
	_choice_made = true
	_retry_button.disabled = true
	_restart_button.disabled = true
	return true


func _on_retry_pressed() -> void:
	if _lock_buttons():
		retry_requested.emit()


func _on_restart_pressed() -> void:
	if _lock_buttons():
		restart_requested.emit()
