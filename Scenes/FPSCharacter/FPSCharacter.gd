extends KinematicBody

var height : float = 1.3
var walk_speed : float = 3.0

const ghost_env : Environment = preload("res://Assets/Environments/Ghost.tres")
const player_env : Environment = preload("res://Assets/Environments/Host.tres")

onready var environment : WorldEnvironment = $WorldEnvironment

onready var raycast : RayCast = $RayCast
onready var ghostcast : RayCast = $Cam_y/Cam_x/Camera/GhostCast

onready var cam_y : Spatial = $Cam_y
onready var cam_x : Spatial = $Cam_y/Cam_x

onready var mesh : MeshInstance = $Cam_y/MeshInstance

onready var animplay : AnimationPlayer = $AnimationPlayer

var ghost : Ghost

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if NetHelper.online and not is_network_master():
		# current scene tree is not in control
		set_process_input(false)
		set_physics_process(false)
		$WorldEnvironment.environment = ghost_env
		mesh.visible = true
	else:
		set_process_input(true)
		set_physics_process(true)
		# current scene tree is in control
		mesh.visible = false
		$WorldEnvironment.environment = player_env

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_control(event.relative)

func _physics_process(delta: float) -> void:
	movement(delta)
	
	if raycast.is_colliding():
		var ray_col : Vector3 = raycast.get_collision_point()
		global_transform.origin.y = ray_col.y + height
	
	if get_tree().network_peer:
		rpc_unreliable("set_transform_new", global_transform, cam_y.transform, cam_x.transform)
	
	if ghostcast.is_colliding():
		var ghost : Ghost = ghostcast.get_collider().get_parent() # ew
		if ghost:
			ghost.caught += delta * 2
	
	if ghost:
		var distance : float = global_transform.origin.distance_squared_to(ghost.global_transform.origin)
		distance = clamp(distance, 0, 100)
		distance /= 100
		distance = 1 - distance
		set_audio_speed(distance*0.7 + 1.0)
	else:
		var ghosts = get_tree().get_nodes_in_group("Ghost")
		if ghosts.size() > 0:
			ghost = get_tree().get_nodes_in_group("Ghost")[0]

# movement of the fps object
func movement(delta : float) -> void:
	var movement : Vector3 = Vector3()

	movement.x += Input.get_action_strength("right")
	movement.x -= Input.get_action_strength("left")

	movement.z += Input.get_action_strength("down")
	movement.z -= Input.get_action_strength("up")

	move_and_slide(movement.rotated(Vector3.UP, cam_y.rotation.y) * walk_speed)

# camera movement of the fps object
func camera_control(vector : Vector2) -> void:
	cam_y.rotate_y(-vector.x * 0.01 * Settings.mouse_sens)# * get_physics_process_delta_time())
	cam_x.rotation.x = clamp(cam_x.rotation.x + (-vector.y * 0.01 * Settings.mouse_sens), -1.3, 1.3)

remote func set_transform_new(new : Transform, camy : Transform, camx : Transform) -> void:
	global_transform = new
	cam_y.transform = camy
	cam_x.transform = camx
	#$Cam_y/Cam_x/Camera/SpotLight.global_transform = flash

remotesync func set_audio_speed(new : float):
	animplay.playback_speed = new
