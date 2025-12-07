extends Node3D
class_name CombatActor

# Data resources (one or the other)
@export var player_data: PlayerData
@export var enemy_data: EnemyData

# Optional actor root for telegraphs / offsets
@export var actor_root_path: NodePath
@onready var actor_root: Node3D = get_node_or_null(actor_root_path) if actor_root_path != NodePath("") else self

# Combat visuals / telegraph config
@export var telegraph_scene: PackedScene
@export var telegraph_duration: float = 0.6
@export var telegraph_size: Vector3 = Vector3(2, 0.2, 2)

# Runtime enemy-only health
var _enemy_current_health: int = 0

# Signals
signal health_changed(current: int, max: int)
signal dying

func _ready() -> void:
	if player_data:
		if player_data.max_health == 0:
			if player_data.base_stats.has("vitality"):
				player_data.max_health = int(player_data.base_stats["vitality"])*10
			else:
				player_data.max_health = 40
		if player_data.health == 0:
			player_data.health = player_data.max_health
		emit_signal("health_changed", player_data.health, player_data.max_health)
	elif enemy_data:
		_enemy_current_health = enemy_data.max_health
		emit_signal("health_changed", _enemy_current_health, enemy_data.max_health)
	else:
		_enemy_current_health = 100
		emit_signal("health_changed", _enemy_current_health, _enemy_current_health)

# ----------------------------
# Health helpers
# ----------------------------
func get_max_health() -> int:
	if player_data: return player_data.max_health
	if enemy_data: return enemy_data.max_health
	return _enemy_current_health

func get_current_health() -> int:
	if player_data: return player_data.health
	if enemy_data: return _enemy_current_health
	return _enemy_current_health

func get_attack_power() -> int:
	if player_data and player_data.base_stats.has("strength"):
		return int(player_data.base_stats["strength"])
	if enemy_data:
		return enemy_data.attack_power
	return 1

# ----------------------------
# Damage / dying
# ----------------------------
func take_damage(amount: int) -> void:
	var current: int
	if player_data:
		player_data.health = max(player_data.health - amount, 0)
		current = player_data.health
	elif enemy_data:
		_enemy_current_health = max(_enemy_current_health - amount, 0)
		current = _enemy_current_health
	else:
		_enemy_current_health = max(_enemy_current_health - amount, 0)
		current = _enemy_current_health

	var maximum: int = get_max_health()
	emit_signal("health_changed", current, maximum)

	print("%s took %d damage -> %d / %d" % [name, amount, current, maximum])

	if current <= 0:
		emit_signal("dying")
		_on_die()

func _on_die() -> void:
	print("%s is dying (CombatActor)" % name)

# ----------------------------
# Attacking
# ----------------------------
func perform_attack():
	var dmg := get_attack_power()
	if telegraph_scene and actor_root:
		var forward_offset := Transform3D(Basis(), Vector3(0, 0, 2))
		spawn_attack_telegraph(telegraph_scene, forward_offset, dmg)
	else:
		print("%s performs a raw attack for %d" % [name, dmg])

func spawn_attack_telegraph(scene: PackedScene, offset: Transform3D = Transform3D(), dmg: int = 10) -> void:
	if not actor_root:
		push_error("CombatActor actor_root is null. Cannot spawn telegraph.")
		return
	if scene == null:
		push_error("Telegraph scene is null. Assign telegraph_scene on CombatActor.")
		return
	var tele := scene.instantiate() as Telegraph
	tele.owner_actor = self
	tele.damage = dmg
	tele.duration = telegraph_duration
	tele.shape_size = telegraph_size
	tele.color = Color(1, 0, 0, 0.45)
	actor_root.add_child(tele)
	tele.transform = offset
	tele.show()
