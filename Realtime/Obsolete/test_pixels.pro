pro test_pixel_ref, day, scan_num, pix1mm, pix2mm, size = size, reso = reso

  if not keyword_set(size) then size = 100.0
  if not keyword_set(reso) then reso = 4.0
  
  old_common_mode = 0
  two_mm_only = 0
  one_mm_only = 0
  png         = 1

  numdet1     = pix1mm          ; ref pixel at 1mm
  numdet2     = pix2mm          ; ref pixel at 2mm
  force = 1
  noskydip = 1
; day to day says : 0.3, 1.4

  nika_pipe_default_param, scan_num, day, param
  param.map.size_ra    = size
  param.map.size_dec   = size
  param.map.reso       = reso
  param.decor.method   = 'COMMON_MODE_KIDS_OUT' ; 'median_simple'
  param.decor.common_mode.d_min = 20.
  param.decor.iq_plane.apply = 'no'
  ;param.kid_file.a = !nika.off_proc_dir+"/kidpar_ref_1mm.fits"
  ;param.kid_file.b = !nika.off_proc_dir+"/kidpar_ref_2mm.fits"
  param.kid_file.a = !nika.off_proc_dir+"/kidpar_ref_1mm_20130612_0143.fits"
  param.kid_file.b = !nika.off_proc_dir+"/kidpar_ref_2mm_20130612_0143.fits"

  cross, scan_num, day, numdet1, numdet2, off1, off2, two_mm_only=two_mm_only, png=png, param=param, $
         check=check, tau_force=tau_force, fast=fast, logbook=logbook, old_common_mode=old_common_mode, force=force, noskydip=noskydip,  /nomap

end
