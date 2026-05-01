extends Node3D

@export var otherPortal: Node3D
@export var cameraToMove : Camera3D


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
	#if self.rotation.y >= 0:
		#cameraToMove.rotation = Vector3(0,0, 0)
	#
	#else:
		#cameraToMove.rotation = Vector3(0,0, 0)
	#$SubViewport2/Camera3D.fov = curentCamera.fov
	
	#$CSGBox3D.set_instance_shader_parameter("texture_albedo")
