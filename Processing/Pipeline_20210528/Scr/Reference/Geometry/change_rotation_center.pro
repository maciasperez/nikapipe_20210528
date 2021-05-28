pro change_rotation_center, kp_in_file, kp_out_file, center_coord

  kp = mrdfits( kp_in_file, 1)
  
  kp.nas_center_x = center_coord[0]
  kp.nas_center_y = center_coord[1]
  
  nk_write_kidpar, kp, kp_out_file
  
end
