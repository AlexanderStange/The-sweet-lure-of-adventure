# res://ui/HealthBar.gd
extends Control
class_name HealthBar

@onready var back: ColorRect = $Back
@onready var fill: ColorRect = $Front
@onready var label: Label = $Label

# runtime references
var _actor: CombatActor = null          # CombatActor node (preferred)
var _pdata: PlayerData = null           # optional PlayerData resource fallback

func init(target: Variant) -> void:
	print("HealthBar children: ", get_children())
	"""
	Initialize the health bar.
	`target` can be:
	 - CombatActor (preferred)  -> bar auto-updates via signals
	 - Node with CombatActor child
	 - PlayerData (resource)     -> one-time init (no signals)
	"""
	_disconnect_actor()

	if target == null:
		push_warning("HealthBar.init: target is null")
		return

	# Direct CombatActor instance
	if target is CombatActor:
		_actor = target
		_pdata = null
		_connect_actor_signals()
		_on_health_changed(_actor.get_current_health(), _actor.get_max_health())
		return

	# Node that might have a CombatActor child
	if target is Node:
		var ca: CombatActor = target.get_node_or_null("CombatActor") as CombatActor
		if ca:
			_actor = ca
			_pdata = null
			_connect_actor_signals()
			_on_health_changed(_actor.get_current_health(), _actor.get_max_health())
			return

	# PlayerData resource fallback (one-shot)
	if target is PlayerData:
		_pdata = target
		_actor = null
		_update_from_playerdata()
		return

	push_warning("HealthBar.init: unsupported target type %s" % [typeof(target)])


func _connect_actor_signals() -> void:
	if not _actor:
		return
	if not _actor.is_connected("health_changed", Callable(self, "_on_health_changed")):
		_actor.connect("health_changed", Callable(self, "_on_health_changed"))
	if not _actor.is_connected("dying", Callable(self, "_on_dying")):
		_actor.connect("dying", Callable(self, "_on_dying"))


func _disconnect_actor() -> void:
	if _actor:
		if _actor.is_connected("health_changed", Callable(self, "_on_health_changed")):
			_actor.disconnect("health_changed", Callable(self, "_on_health_changed"))
		if _actor.is_connected("dying", Callable(self, "_on_dying")):
			_actor.disconnect("dying", Callable(self, "_on_dying"))
	_actor = null


func _on_health_changed(current: int, maximum: int) -> void:
	_update_ui(current, maximum)


func _update_from_playerdata() -> void:
	if not _pdata:
		return
	else :
		print(_pdata.health)
		_update_ui(int(_pdata.health), int(_pdata.max_health))


func _update_ui(current: int, maximum: int) -> void:
	if maximum <= 0:
		return
	
	print(back)
	# If the Control hasn't had its size assigned yet, defer update
	#if back.size.x <= 0.0:
	#	call_deferred("_update_ui", current, maximum)
	#	return

	#var ratio: float = clamp(float(current) / float(maximum), 0.0, 1.0)

	# Update fill
	#var full_w: float = back.size.x
	#var full_h: float = back.size.y
	#fill.size = Vector2(full_w * ratio, full_h)
	#fill.position.x = 0.0

	# Label
	if label:
		label.text = "%d / %d" % [current, maximum]


func _on_dying() -> void:
	visible = false
