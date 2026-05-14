extends Node3D

@export var otherPortal: Node3D
@export var cameraToMove : Camera3D
@export var camera : Camera3D
@export var viewport : SubViewport
@export var PortalVisual : CSGBox3D
@export var isRot: bool
@export var startRot: float


func _process(delta):

	update_camera_to_other_portal()

func update_camera_to_other_portal():
	var curentCamera = get_viewport().get_camera_3d()
	#print(curentCamera.global_position)
	if not curentCamera:
		return
	
	var CC_rel_transform_to_portal = self.global_transform.affine_inverse() * curentCamera.global_transform
	var moved_to_other_portal = otherPortal.global_transform * CC_rel_transform_to_portal
	cameraToMove.global_transform = moved_to_other_portal
	viewport.size = get_viewport().get_visible_rect().size
	viewport.msaa_3d = get_viewport().msaa_3d
	viewport.screen_space_aa = get_viewport().screen_space_aa
	viewport.use_taa = get_viewport().use_taa
	viewport.use_debanding = get_viewport().use_debanding
	viewport.use_occlusion_culling = get_viewport().use_occlusion_culling
	viewport.mesh_lod_threshold = get_viewport().mesh_lod_threshold

	
	
	
