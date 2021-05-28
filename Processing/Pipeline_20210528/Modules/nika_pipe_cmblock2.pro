;+
;PURPOSE: Remove a common mode per block of electronics detectors
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: 05/07/2014
;-

pro nika_pipe_cmblock2, param, data, kidpar, $
                        baseline, $
                        silent=silent

  ;;========== Some info
  if strupcase(param.decor.common_mode.per_subscan) ne 'YES' $
     and strupcase(param.decor.common_mode.per_subscan) ne 'NO' then begin
     message,/info,"You need to tell me if you want to decorrelate per subscan or all the timeline at once"
     message,/info,"For this, set param.decor.common_mode.per_subscan to 'yes' or 'no'"
     message,"Here param.decor.common_mode.per_subscan = '"+strtrim(param.decor.common_mode.per_subscan,2)+"'"
  endif

  if not keyword_set(silent) then begin
     if param.decor.common_mode.x_calib eq 'yes' then message, /info, "Atmospheric calibration far from the source"
     if param.decor.common_mode.x_calib eq 'no' then message, /info, "No atmospheric cross calibration"
  endif

  if param.decor.common_mode.median eq 'yes' then k_median = 1 else k_median=0

  ;;========== Define blocs
  bloc_value = long(kidpar.numdet)/long(80)
  Nbloc = max(bloc_value)
  
  ;;========== Plots
  set_plot, 'ps'
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_Blocks1mm.ps'
  plot, kidpar.nas_x, kidpar.nas_y, $
        psym=8, xr=[-70,70],yr=[-70,70], title='260 GHz', xtitle='arcsec', ytitle='arcsec',/xs,/ys,/nodata,/iso
  for ibloc=0, 4 do begin
     wblok = where(bloc_value eq ibloc, nwblok)
     if nwblok ge 2 then oplot, kidpar[wblok].nas_x, kidpar[wblok].nas_y, col=250 - 50*ibloc, psym=8
  endfor
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_Blocks1mm'

  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_Blocks2mm.ps'
  plot, kidpar.nas_x, kidpar.nas_y, $
        psym=8, xr=[-70,70],yr=[-70,70], title='150 GHz', xtitle='arcsec', ytitle='arcsec',/xs,/ys,/nodata,/iso
  for ibloc=5, 9 do begin
     wblok = where(bloc_value eq ibloc, nwblok)
     if nwblok ge 2 then oplot, kidpar[wblok].nas_x, kidpar[wblok].nas_y,$
                                 col=250 + 50*(5-ibloc), psym=8
  endfor
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_Blocks2mm'
  set_plot, 'x'
  
  ;;========== Build the common mode over the entire scan
  if param.decor.common_mode.per_subscan eq 'no' then begin
     for ibloc = 0, Nbloc do begin
        bloc = where(bloc_value eq ibloc, nkid_bloc)
        if nkid_bloc gt 3 then begin
           w8source = 1 - data.on_source_dec[bloc]
           kidpar_bloc = kidpar[bloc]
           TOI = data.RF_dIdQ[bloc]
           nika_pipe_subtract_common_atm, param, TOI, kidpar_bloc, w8source, $
                                          atm, base, $
                                          elev=data.el, ofs_el=data.ofs_el, k_median=k_median
           data.RF_dIdQ[bloc] = TOI
        endif else begin
           ;;If less than 3 KIDs in the bloc, they are flagged because
           ;;we cannot decorrelate them preoperly
           if nkid_bloc ne 0 then nika_pipe_addflag, data, 6, wkid=bloc
        endelse
     endfor
  endif
  
  ;;========== Build the atmosphere template subscan by subscan
  if param.decor.common_mode.per_subscan eq 'yes' then begin
     ;;---------- Loop over blocs
     for ibloc = 0, Nbloc do begin
        bloc = where(bloc_value eq ibloc, nkid_bloc)
        if nkid_bloc gt 3 then begin
           kidpar_bloc = kidpar[bloc]
           ;;---------- Loop over subscan
           for isubscan=1, max(data.subscan) do begin
              wsubscan = where(data.subscan eq isubscan, nwsubscan)
              if nwsubscan gt long(2.5*!nika.f_sampling) then begin
                 w8source = 1 - data[wsubscan].on_source_dec[bloc]
                 TOI = data[wsubscan].RF_dIdQ[bloc]
                 nika_pipe_subtract_common_atm, param, TOI, kidpar_bloc, w8source, $
                                                atm, base, $
                                                elev=data[wsubscan].el, ofs_el=data[wsubscan].ofs_el, $
                                                k_median=k_median
                 data[wsubscan].RF_dIdQ[bloc] = TOI
              endif
           endfor
        endif else begin
           ;;If less than 3 KIDs in the bloc, they are flagged because
           ;;we cannot decorrelate them preoperly
           if nkid_bloc ne 0 then nika_pipe_addflag, data, 6, wkid=bloc
        endelse
     endfor
  endif
  
  return
end
