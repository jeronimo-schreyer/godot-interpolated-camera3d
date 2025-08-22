# Copyright © 2020-present Hugo Locurcio and contributors - MIT License
# Updated by Jeronimo Schreyer - 2025
# See `LICENSE.md` included in the source distribution for details.
@icon("interpolated_camera_3d.svg")
extends Camera3D
class_name InterpolatedCamera3D


## Base speed for translation interpolation
@export_range(0, 100, 0.01, "hide_slider") var translate_speed := 5.0
## Easing curve for translation interpolation
@export_exp_easing("attenuation") var translate_ease := 1.0

## Base speed for rotation interpolation
@export_range(0, 100, 0.01, "hide_slider") var rotate_speed := 5.0
## Easing curve for rotation interpolation
@export_exp_easing("attenuation") var rotate_ease := 1.0

## Base speed for FOV interpolation
@export_range(0, 100, 0.01, "hide_slider") var fov_speed := 5.0
## Easing curve for FOV interpolation
@export_exp_easing("attenuation") var fov_ease := 1.0

## Base speed for Z near/far plane distance interpolation
@export_range(0, 100, 0.01, "hide_slider") var near_far_speed := 5
## Easing curve for Z near/far plane distance interpolation
@export_exp_easing("attenuation") var near_far_ease := 1.0

# The node to target.
# Can optionally be a Camera3D to support smooth FOV and Z near/far plane distance changes.
@export var target: Node3D


func _physics_process(delta: float) -> void:
	if not target is Node3D:
		return

	# ease speeds
	var translate_factor := ease(translate_speed * delta, translate_ease)
	var rotate_factor := ease(rotate_speed * delta, rotate_ease)
	
	# Interpolate the origin and basis separately so we can have different translation and rotation
	# interpolation speeds.
	var local_transform_only_origin = lerp(get_global_position(), target.get_global_position(), translate_factor)
	var local_transform_only_basis = lerp(get_global_basis(), target.get_global_basis(), rotate_factor)
	set_global_transform(Transform3D(local_transform_only_basis, local_transform_only_origin))

	if target is Camera3D:
		var camera := target as Camera3D
		# The target node can be a Camera3D, which allows interpolating additional properties.
		# In this case, make sure the "Current" property is enabled on the InterpolatedCamera3D
		# and disabled on the Camera3D.
		if camera.projection == projection:
			# Interpolate the near and far clip plane distances.
			var near_far_factor := ease(clampf(near_far_speed * delta, 0, 1), near_far_ease)
			var fov_factor := ease(clampf(fov_speed * delta, 0, 1), fov_ease)
			var new_near := lerp(near, camera.near, near_far_factor) as float
			var new_far := lerp(far, camera.far, near_far_factor) as float

			# Interpolate size or field of view.
			if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
				var new_size := lerp(size, camera.size, fov_factor) as float
				set_orthogonal(new_size, new_near, new_far)
			else:
				var new_fov := lerp(fov, camera.fov, fov_factor) as float
				set_perspective(new_fov, new_near, new_far)
