@tool
extends Camera3D

## CinematicCamera.gd
## Smoothly travels through a list of waypoints (Node3D / Empty nodes).
## 
## SETUP
## -----
## 1. Add this script to a Camera3D node.
## 2. Create child Node3D nodes (Empties) and name them however you like.
##    Their position AND rotation define each camera keyframe.
## 3. Assign those nodes to the `waypoints` array in the Inspector.
## 4. Press Play (or call `start_sequence()` from another script).

# ── Inspector settings ──────────────────────────────────────────────────────

@export var waypoints: Array[Node3D] = []## Ordered list of Empty nodes to visit
@export var dots: Node3D
@export_group("Movement")
@export var travel_time: float = 2.0## Seconds to move between each waypoint
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT
@export var trans_type: Tween.TransitionType = Tween.TRANS_CUBIC

@export_group("Rotation")
@export var rotation_time: float = 2.0 ## Seconds to rotate between each waypoint (can differ from travel)
@export var use_look_at: bool = false## If true, camera looks at the NEXT waypoint instead of copying its rotation

@export_group("Playback")
@export var auto_play: bool = true## Start automatically when the scene loads
@export var loop: bool = false## Loop back to the first waypoint after the last
@export var start_index: int = 0## Which waypoint to begin at

# ── Signals ─────────────────────────────────────────────────────────────────

signal sequence_started
signal arrived_at_waypoint(index: int)
signal sequence_finished

# ── Internal state ───────────────────────────────────────────────────────────

var _current_index: int = 0
var _tween: Tween = null
var _is_playing: bool = false

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if waypoints.is_empty():
		push_warning("CinematicCamera: No waypoints assigned!")
		return
	_current_index = clampi(start_index, 0, waypoints.size() - 1)
	_snap_to_waypoint(_current_index)
	if auto_play:
		start_sequence()

# ── Public API ───────────────────────────────────────────────────────────────

## Begin the camera sequence from the current waypoint.
func start_sequence() -> void:
	if waypoints.size() < 2:
		push_warning("CinematicCamera: Need at least 2 waypoints to travel.")
		return
	_is_playing = true
	emit_signal("sequence_started")
	_travel_to_next()

## Pause the active tween mid-flight.
func pause() -> void:
	if _tween:
		_tween.pause()

## Resume a paused tween.
func resume() -> void:
	if _tween:
		_tween.play()

## Immediately jump to a specific waypoint index and (re)start from there.
func jump_to(index: int) -> void:
	_stop_tween()
	_current_index = clampi(index, 0, waypoints.size() - 1)
	_snap_to_waypoint(_current_index)
	if _is_playing:
		_travel_to_next()

## Stop playback and snap to the nearest waypoint.
func stop() -> void:
	_stop_tween()
	_is_playing = false

## Returns true while the sequence is running.
func is_playing() -> bool:
	return _is_playing

# ── Internal helpers ─────────────────────────────────────────────────────────

func _travel_to_next() -> void:
	var next_index: int = _current_index + 1
	if next_index == 3:
		dots.rotation.x = deg_to_rad(-82.3)
	# Handle end of sequence
	if next_index >= waypoints.size():
		if loop:
			next_index = 0
		else:
			_is_playing = false
			emit_signal("sequence_finished")
			return

	var target: Node3D = waypoints[next_index]
	if target == null:
		push_warning("CinematicCamera: Waypoint %d is null, skipping." % next_index)
		_current_index = next_index
		_travel_to_next()
		return

	_stop_tween()
	_tween = create_tween()
	_tween.set_parallel(true)# position & rotation animate simultaneously

	# ── Position ──
	_tween.tween_property(self, "global_position", target.global_position, travel_time)\
		.set_ease(ease_type)\
		.set_trans(trans_type)

	# ── Rotation ──
	if use_look_at and next_index + 1 < waypoints.size():
		# Rotate toward the waypoint AFTER the target so the camera anticipates direction
		var look_target: Vector3 = waypoints[next_index + 1].global_position
		var target_basis: Basis = _look_at_basis(target.global_position, look_target)
		_tween.tween_method(_set_basis_slerp.bind(global_basis, target_basis), 0.0, 1.0, rotation_time)\
			.set_ease(ease_type)\
			.set_trans(trans_type)
	else:
		# Copy the waypoint's own rotation (artist-controlled)
		_tween.tween_method(_set_basis_slerp.bind(global_basis, target.global_basis), 0.0, 1.0, rotation_time)\
			.set_ease(ease_type)\
			.set_trans(trans_type)

	# ── On complete ──
	var done_time: float = maxf(travel_time, rotation_time)
	_tween.chain().tween_callback(func():
		_current_index = next_index
		emit_signal("arrived_at_waypoint", _current_index)
		_travel_to_next()
	).set_delay(done_time - minf(travel_time, rotation_time))

func _snap_to_waypoint(index: int) -> void:
	if index < 0 or index >= waypoints.size():
		return
	var wp: Node3D = waypoints[index]
	if wp == null:
		return
	global_position = wp.global_position
	global_basis = wp.global_basis

func _stop_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null

## Callback used by tween_method to slerp the camera's global basis.
func _set_basis_slerp(t: float, from_basis: Basis, to_basis: Basis) -> void:
	global_basis = from_basis.slerp(to_basis, t)

## Build a Basis that looks from `eye` toward `target` (Godot -Z forward).
func _look_at_basis(eye: Vector3, target: Vector3) -> Basis:
	var forward: Vector3 = (target - eye).normalized()
	if forward.is_zero_approx():
		return global_basis
	var right: Vector3 = Vector3.UP.cross(forward).normalized()
	if right.is_zero_approx():
		right = Vector3.RIGHT
	var up: Vector3 = forward.cross(right).normalized()
	return Basis(-right, up, -forward)# Godot Camera3D looks down -Z
