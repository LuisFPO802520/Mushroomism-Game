# Origem: elaborado com ajuda de IA (OpenAI/Codex).
extends Control
## Cada cabeca acesa representa um ponto de vida. O contador e ligado ao resgate.

@onready var life_icons: HBoxContainer = %HealthIcons
@onready var party_count: Label = %PartyCount


func update_values(current_health: int, allies: int) -> void:
	for index: int in range(life_icons.get_child_count()):
		var icon := life_icons.get_child(index) as TextureRect
		icon.modulate = Color.WHITE if index < current_health else Color(0.22, 0.30, 0.40, 0.60)
	party_count.text = "%d/5" % clampi(allies, 0, 5)
