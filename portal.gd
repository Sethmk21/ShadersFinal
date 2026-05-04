extends Node3D

@export var otherPortal: Node3D
@export var cameraToMove : Camera3D
@export var viewport : SubViewport
@export var PortalVisual : CSGBox3D
@export var isRot: bool

func _ready() -> void:
	if self.rotation.y == 180:
		isRot = true

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

	cameraToMove.rotation = Vector3(0,-cameraToMove.rotation.y + self.rotation.y, 0)
	cameraToMove.cull_mask = curentCamera.cull_mask
	#cameraToMove.set_cull_mask_value(otherPortal.cull_layer, false)
	
	viewport.size = get_viewport().get_visible_rect().size
	viewport.msaa_3d = get_viewport().msaa_3d
	viewport.screen_space_aa = get_viewport().screen_space_aa
	viewport.use_taa = get_viewport().use_taa
	viewport.use_debanding = get_viewport().use_debanding
	viewport.use_occlusion_culling = get_viewport().use_occlusion_culling
	viewport.mesh_lod_threshold = get_viewport().mesh_lod_threshold
	#if self.rotation.y >= 0:
		#cameraToMove.rotation = Vector3(0,0, 0)
	#
	#else:
		#cameraToMove.rotation = Vector3(0,0, 0)
	
	
	
