# Origem: elaborado com ajuda de IA (OpenAI/Codex).
extends Control
## A chegada ao ceu encerra a partida; o unico botao inicia outra jornada.

signal restart_requested

@onready var _falls_label: Label = %Falls
@onready var _allies_label: Label = %Allies
@onready var _restart_button: Button = %RestartButton
@onready var _spores: Control = $Spores
@onready var _mush: TextureRect = %Mush

var _falls: int = 0
var _allies: int = 0
var _time: float = 0.0
var _input_delay: float = 0.3
var _button_ready: bool = false
var _choice_made: bool = false
var _spore_origins: Array[Vector2] = []


func setup(falls: int, allies: int) -> void:
	_falls = maxi(0, falls)
	_allies = maxi(0, allies)
	if is_node_ready():
		_refresh_text()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for spore: ColorRect in _spores.get_children():
		_spore_origins.append(spore.position / Vector2(288.0, 208.0))
	_restart_button.pressed.connect(_on_restart_pressed)
	_refresh_text()


func _refresh_text() -> void:
	_falls_label.text = "%02d  QUEDAS" % _falls
	_allies_label.text = "%d / 5  ALIADOS" % _allies


func _process(delta: float) -> void:
	_time += delta
	# O pequeno Mush comemora sem deslocar os personagens da partida pausada.
	var frame := _mush.texture as AtlasTexture
	if frame != null and frame.atlas != null:
		var columns: int = maxi(1, frame.atlas.get_width() / 32)
		frame.region = Rect2((int(_time * 8.0) % columns) * 32, 0, 32, 32)
	for index: int in _spore_origins.size():
		var spore := _spores.get_child(index) as ColorRect
		var origin: Vector2 = _spore_origins[index] * size
		spore.position = Vector2(
			origin.x + sin(_time * 0.6 + index) * 4.0,
			fposmod(origin.y - _time * (2.0 + index % 3), maxf(size.y, 1.0))
		).round()
		spore.modulate.a = 0.65 + sin(_time * 1.4 + index) * 0.25
	if _button_ready or _choice_made:
		return
	_input_delay -= delta
	# O salto usado para chegar ao portal nao pode reiniciar a jornada por engano.
	if _input_delay <= 0.0 and not Input.is_action_pressed("ui_accept") and not Input.is_action_pressed("jump"):
		_button_ready = true
		_restart_button.disabled = false
		_restart_button.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if not _button_ready and (event.is_action("ui_accept") or event.is_action("jump")):
		get_viewport().set_input_as_handled()


func _on_restart_pressed() -> void:
	if not _button_ready or _choice_made:
		return
	_choice_made = true
	_restart_button.disabled = true
	restart_requested.emit()
