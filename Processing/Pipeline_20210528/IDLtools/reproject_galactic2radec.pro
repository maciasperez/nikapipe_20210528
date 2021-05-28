;+
; PURPOSE:
;       Reproject a map with galactic coordinates onto a map with
;       radec coordinates. This is very approximated so do not use it
;       for science.
;
; AUTHOR: R. ADAM
;-

pro reproject_galactic2radec, map_in, head_in, map_out, head_out
  
  ;;--------- Get galactic coordinates
  extast, head_in, astr_in

  nx_in = astr_in.NAXIS[0]
  ny_in = astr_in.NAXIS[1]
  reso_in = astr_in.CDELT[1]
  cpixx_in = astr_in.CRPIX[0]
  cpixy_in = astr_in.CRPIX[1]
  cvx_in = astr_in.CRVAL[0]
  cvy_in = astr_in.CRVAL[1]  

  gl = (dindgen(nx_in)+1 - cpixx_in) * reso_in + cvx_in
  gb = (dindgen(ny_in)+1 - cpixy_in) * reso_in + cvy_in

  euler, gl[nx_in/2.0], gb[ny_in/2.0], cvx_out, cvy_out, 2
  euler, gl, gb, ra, dec, 2


  angle0 = atan((gb[n_elements(gb)-1] - gb[0]) / (gl[n_elements(gl)-1] - gl[0]))*180/!pi
  angle1 = atan((dec[n_elements(dec)-1] - dec[0]) / (ra[n_elements(ra)-1] - ra[0]))*180/!pi

  angle = angle1-angle0
  
  map_out = rot(map_in, angle, /interp, missing=0) 

  astr_out = astr_in
  
  astr_out.crval = [cvx_out, cvy_out]
  astr_out.ctype = ['RA---TAN','DEC--TAN']
  
  mkhdr, head_out, map_out
  putast, head_out, astr_out, equinox=2000, cd_type=0 

  return
end
