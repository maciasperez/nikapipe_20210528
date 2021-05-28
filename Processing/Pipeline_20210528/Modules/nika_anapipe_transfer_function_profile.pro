;+
;PURPOSE: Compute the transfer function based on input and output
;simulated maps assuming spherical symmetrie. It is done as the ratio
;of output/input profile (not in Fourier) 
;
;INPUT: A parameter structure containing what you want to compute
;
;OUTPUT: Plot of the transfer function
;
;LAST EDITION: 
;   05/02/2014: creation
;   29/07/2014: compute both profile and integrated profile transfer functions
;-

pro nika_anapipe_transfer_function_profile, param, anapar
  
  mydevice = !d.name

  ;;------- Restore the output maps
  map_out_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',0,head_1mm,/SIL)+anapar.cor_zerolevel.a
  map_out_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',0,head_2mm,/SIL)+anapar.cor_zerolevel.b
  noise_out_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',2,head_1mm,/SIL)
  noise_out_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',2,head_2mm,/SIL)
  
  EXTAST, head_2mm, astr
  reso = astr.cdelt[1]*3600
  nx = astr.naxis[0]
  ny =  astr.naxis[1]
  coord_ref = astr.crval        ;coord of ref pixel (deg)
  refpix = astr.crpix           ;reference pixel
  coord_map = coord_ref + [refpix[0]-((nx-1)/2.0+1), -refpix[1]+((ny-1)/2.0+1)]*reso/3600.0
  
  ;;------- Restore the input map
  map_in_1mm = mrdfits(anapar.trans_func_prof.map_in.a, 0, h_in, /SILENT)
  map_in_2mm = mrdfits(anapar.trans_func_prof.map_in.b, 0, h_in, /SILENT)
  
  ;;------- Get the center of the map
  if anapar.trans_func_prof.method eq 'offset' then center = anapar.trans_func_prof.offset
  if anapar.trans_func_prof.method eq 'coord' then begin
     center = [-ten(anapar.trans_func_prof.coord.ra[0],anapar.trans_func_prof.coord.ra[1],anapar.trans_func_prof.coord.ra[2])*15.0 + coord_map[0], $
               ten(anapar.trans_func_prof.coord.dec[0],anapar.trans_func_prof.coord.dec[1],anapar.trans_func_prof.coord.dec[2]) - coord_map[1]]*3600.0
  endif
  
  ;;------- Get the profiles of the maps in and out
  outs_1mm = {Jy:map_out_1mm, var:noise_out_1mm^2}
  outs_2mm = {Jy:map_out_2mm, var:noise_out_2mm^2}
  ins_1mm = {Jy:map_in_1mm, var:noise_out_1mm^2}
  ins_2mm = {Jy:map_in_2mm, var:noise_out_2mm^2}
  nika_pipe_profile, reso, outs_1mm, prof_out_1mm, nb_prof=anapar.trans_func_prof.nb_pt, center=center, /no_nan
  nika_pipe_profile, reso, outs_2mm, prof_out_2mm, nb_prof=anapar.trans_func_prof.nb_pt, center=center, /no_nan
  nika_pipe_profile, reso, ins_1mm, prof_in_1mm, nb_prof=anapar.trans_func_prof.nb_pt, center=center, /no_nan
  nika_pipe_profile, reso, ins_2mm, prof_in_2mm, nb_prof=anapar.trans_func_prof.nb_pt, center=center, /no_nan
  
  T1mm = prof_out_1mm.y/prof_in_1mm.y
  Terr1mm = sqrt(prof_out_1mm.var)/prof_in_1mm.y
  T2mm = prof_out_2mm.y/prof_in_2mm.y
  Terr2mm = sqrt(prof_out_2mm.var)/prof_in_2mm.y
  radius = prof_out_1mm.r
  
  ;;------- Idem for the integrated flux
  int_rad = dindgen(anapar.trans_func_prof.nb_pt)/(anapar.trans_func_prof.nb_pt-1)*max(radius)
  phi_in_1mm = nika_pipe_integmap(map_in_1mm, reso, int_rad, center=center, var=noise_out_1mm^2)
  phi_in_2mm = nika_pipe_integmap(map_in_2mm, reso, int_rad, center=center, var=noise_out_2mm^2)
  phi_out_1mm = nika_pipe_integmap(map_out_1mm, reso, int_rad, center=center, var=noise_out_1mm^2, err=phi_err_1mm)
  phi_out_2mm = nika_pipe_integmap(map_out_2mm, reso, int_rad, center=center, var=noise_out_2mm^2, err=phi_err_2mm)
  
  Tint_1mm = phi_out_1mm/phi_in_1mm
  Tint_err_1mm = phi_err_1mm/phi_in_1mm
  Tint_2mm = phi_out_2mm/phi_in_2mm
  Tint_err_2mm = phi_err_2mm/phi_in_2mm

  ;;========== Plots
  set_plot, 'ps'
  ;;------- Plot the profile
  wfx = where(finite(anapar.trans_func_prof.xr) eq 1, nwfx)
  wfy1mm = where(finite(anapar.trans_func_prof.yr1mm) eq 1, nwfy1mm)
  wfy2mm = where(finite(anapar.trans_func_prof.yr2mm) eq 1, nwfy2mm)
  if nwfx ne 2 then xr = [0, max(radius)] else xr = anapar.trans_func_prof.xr
  if nwfy1mm ne 2 then yr1mm = minmax([T1mm-3*Terr1mm, T1mm+3*Terr1mm], /nan) else yr1mm = anapar.trans_func_prof.yr1mm
  if nwfy2mm ne 2 then yr2mm = minmax([T2mm-3*Terr2mm, T2mm+3*Terr2mm], /nan) else yr2mm = anapar.trans_func_prof.yr2mm

  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_transfer_function_profile_1mm.ps'
  plot, radius, T1mm, xr=xr, yr=yr1mm, xstyle=1, ystyle=1, $
        xtitle='r (arcsec)', ytitle='T(r)', /nodata, charsize=1.5, charthick=3
  oploterror, radius, T1mm, radius*0 + (radius[5]-radius[4])/2, Terr1mm, col=250, errcol=250, psym=8, symsize=0.7
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_transfer_function_profile_1mm'

  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_transfer_function_profile_2mm.ps'
  plot, radius, T2mm, xr=xr, yr=yr2mm, xstyle=1, ystyle=1, $
        xtitle='r (arcsec)', ytitle='T(r)', /nodata, charsize=1.5, charthick=3
  oploterror, radius, T2mm, radius*0 + (radius[5]-radius[4])/2, Terr2mm, col=250, errcol=250, psym=8, symsize=0.7
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_transfer_function_profile_2mm'
  
  ;;------- Plot the integrated profile
  wfx = where(finite(anapar.trans_func_prof.xr) eq 1, nwfx)
  wfy1mm = where(finite(anapar.trans_func_prof.yr1mm) eq 1, nwfy1mm)
  wfy2mm = where(finite(anapar.trans_func_prof.yr2mm) eq 1, nwfy2mm)
  if nwfx ne 2 then xr = [0, max(radius)] else xr = anapar.trans_func_prof.xr
  if nwfy1mm ne 2 then yr1mm = minmax([Tint_1mm-3*Tint_err_1mm, Tint_1mm+3*Tint_err_1mm], /nan) else yr1mm = anapar.trans_func_prof.yr1mm
  if nwfy2mm ne 2 then yr2mm = minmax([Tint_2mm-3*Tint_err_2mm, Tint_2mm+3*Tint_err_2mm], /nan) else yr2mm = anapar.trans_func_prof.yr2mm

  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_transfer_function_int_profile_1mm.ps'
  plot, int_rad, Tint_1mm, xr=xr, yr=yr1mm, xstyle=1, ystyle=1, $
        xtitle='r (arcsec)', ytitle='T(r)', /nodata, charsize=1.5, charthick=3
  oploterror, int_rad, Tint_1mm, int_rad*0 + (int_rad[5]-int_rad[4])/2, Tint_err_1mm, col=250, errcol=250, psym=8, symsize=0.7
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_transfer_function_int_profile_1mm'

  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_transfer_function_int_profile_2mm.ps'
  plot, int_rad, Tint_2mm, xr=xr, yr=yr2mm, xstyle=1, ystyle=1, $
        xtitle='r (arcsec)', ytitle='T(r)', /nodata, charsize=1.5, charthick=3
  oploterror, int_rad, Tint_2mm, int_rad*0 + (int_rad[5]-int_rad[4])/2, Tint_err_2mm, col=250, errcol=250, psym=8, symsize=0.7
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_transfer_function_int_profile_2mm'
  
  set_plot, mydevice
  
  ;;========== Save result as fits file
  if anapar.trans_func_prof.make_fits eq 'yes' then begin
     tf_r_1mm = [[T1mm], [Terr1mm]]
     mkhdr, head1mm, tf_r_1mm
     mwrfits, tf_r_1mm, param.output_dir+'/Transfer_Function_Profile_1mm_'+param.name4file+'.fits', head1mm, /create, /silent
     tf_r_2mm = [[T2mm], [Terr2mm]]
     mkhdr, head2mm, tf_r_2mm
     mwrfits, tf_r_2mm, param.output_dir+'/Transfer_Function_Profile_2mm_'+param.name4file+'.fits', head2mm, /create, /silent
  endif
  
  return

end
