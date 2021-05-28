;+
;PURPOSE: Compute the error that we have for the fixed beam gaussian fit of
;         a point source at the center of the map. Then deduce the
;         NEFD accounting for time of observation.
;
;INPUT: Param structure and maps structure
;
;OUTPUT: Put the NEFD in param.nefd.a,b
;
;LAST EDITION: - 09/01/2014 creation (adam@lpsc.in2p3.fr)
;              - 14/02/2014 save the flux found here
;-

pro nika_pipe_nefd, param, kidpar, maps, from_toi=from_toi, silent=silent
  
  map_1mm = maps.A.Jy
  if not keyword_set(from_toi) then var_1mm = maps.A.noise_map^2 else var_1mm = maps.A.var
  map_2mm = maps.B.Jy
  if not keyword_set(from_toi) then var_2mm = maps.B.noise_map^2 else var_2mm = maps.B.var
  
  reso = param.map.reso
  
  nika_pipe_fit_beam, map_1mm, reso, $
                      coeff=coeff_1mm, $
                      var_map=var_1mm,$
                      /CIRCULAR, center=[0,0], err_coeff=err_coeff_1mm, rchi2=chi2_1mm,$
                      FWHM=!nika.fwhm_nom[0], /silent
  err1mm = err_coeff_1mm[1]

  nika_pipe_fit_beam, map_2mm, reso, $
                      coeff=coeff_2mm, $
                      var_map=var_2mm,$
                      /CIRCULAR, center=[0,0], err_coeff=err_coeff_2mm, rchi2=chi2_2mm,$
                      FWHM=!nika.fwhm_nom[1], /silent
  err2mm = err_coeff_2mm[1]
  
  ;;------- Save the flux found in param
  if not keyword_set(from_toi) then begin
     param.source_flux_jy.A[param.iscan]  = coeff_1mm[1]
     param.source_flux_jy.B[param.iscan]  = coeff_2mm[1]

     param.err_source_flux_jy.A[param.iscan] = err1mm
     param.err_source_flux_jy.B[param.iscan] = err2mm

     param.source_loc.A[param.iscan,*] = coeff_1mm[4:5]
     param.source_loc.B[param.iscan,*] = coeff_2mm[4:5]
  endif  

  ;;------ Now the NEFD is error*sqrt(t_on_source*dist_between_detect^2/reso^2)
  w1mm = where(kidpar.type eq 1 and kidpar.array eq 1, nw1mm)
  w2mm = where(kidpar.type eq 1 and kidpar.array eq 2, nw2mm)
  
  if strmid(param.day[param.iscan], 0, 6) eq '201211' or strmid(param.day[param.iscan], 0, 6) eq '201306' or $
     strmid(param.day[param.iscan], 0, 6) eq '201311' then begin
     distpix1mm = 0.0
     distpix2mm = 0.0
     for ikid=0, nw1mm-1 do begin
        distance = sqrt((kidpar[w1mm[ikid]].nas_x - kidpar[w1mm].nas_x)^2 + $
                        (kidpar[w1mm[ikid]].nas_y - kidpar[w1mm].nas_y)^2)
        distance = mean((distance(sort(distance)))[1:4]) ;mean distance from 1st 4 neighboor
        distpix1mm += distance/nw1mm
     endfor
     for ikid=0, nw2mm-1 do begin
        distance = sqrt((kidpar[w2mm[ikid]].nas_x - kidpar[w2mm].nas_x)^2 + $
                        (kidpar[w2mm[ikid]].nas_y - kidpar[w2mm].nas_y)^2)
        distance = mean((distance(sort(distance)))[1:4]) ;mean distance from 1st 4 neighboor
        distpix2mm += distance/nw2mm
     endfor
  endif else begin
     distpix1mm = median(kidpar[w1mm].grid_step)
     distpix2mm = median(kidpar[w2mm].grid_step)
  endelse
  
  time_map_1mm = maps.A.time
  time_map_2mm = maps.B.time

  nx = (size(time_map_1mm))[1]
  ny = (size(time_map_2mm))[2]
  
  radius = shift(dist(nx, ny), nx/2, ny/2)*param.map.reso
  loc_time_1mm = where(radius lt 20, nloc_time)
  loc_time_2mm = where(radius lt 20, nloc_time)
  
  time1mm = mean(maps.A.time[loc_time_1mm]) * distpix1mm^2/param.map.reso^2
  time2mm = mean(maps.B.time[loc_time_2mm]) * distpix2mm^2/param.map.reso^2

  nefd1mm = err1mm * sqrt(time1mm)
  nefd2mm = err2mm * sqrt(time2mm)

  if not keyword_set(from_toi) then param.nefd_map.A[param.iscan] = nefd1mm $
  else param.nefd_toi.A[param.iscan] = nefd1mm
  if not keyword_set(from_toi) then param.nefd_map.B[param.iscan] = nefd2mm $
  else param.nefd_toi.B[param.iscan] = nefd2mm

  if not keyword_set(from_toi) then wcomp = 'MAP' else wcomp = 'TOI'
  
  if not keyword_set(silent) then begin
     message,/info, 'NEFD from the '+wcomp+' at 1mm: '+strtrim(1000*nefd1mm, 2)+' mJy.sqrt(s)'
     message,/info, '            with chi2/NDF = '+strtrim(chi2_1mm,2)
     message, /info, '            on-source-time/total-time : '+strtrim(time1mm/param.INTEG_TIME[param.iscan], 2)
     message,/info, 'NEFD from the '+wcomp+' at 2mm: '+strtrim(1000*nefd2mm, 2)+' mJy.sqrt(s)'
     message,/info, '            with chi2/NDF = '+strtrim(chi2_2mm,2)
     message, /info, '            on-source-time/total-time : '+strtrim(time2mm/param.INTEG_TIME[param.iscan], 2)
  endif  

  return
end
