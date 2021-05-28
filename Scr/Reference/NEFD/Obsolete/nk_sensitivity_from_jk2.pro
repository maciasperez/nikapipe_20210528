;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_sensitivity_from_jk
;
; CATEGORY: map analysis
;
; CALLING SEQUENCE:
;         nk_sensitivity_from_jk2, param, scan_list
; 
; PURPOSE: 
;        Compute the jack-knife maps and use them to compute sensitivity
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - scan_list: the list of scans to use to compute jack-knife maps
; 
; OUTPUT: 
; 
; KEYWORDS:
;        - NIKA1: set to 1 if you are in a NIKA1 configuration (2 arrays)
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - September 26th, 2016: Creation based on nk_sensitivity_from_jk
;          routines (Florian Ruppin - ruppin@lpsc.in2p3.fr)
;-

pro nk_sensitivity_from_jk2, param, scan_list, NIKA1=NIKA1

  ;; Number of standard deviations to consider the fitted beams independent
  ;;======================================================================
  n_sigma = 5.
  ;;======================================================================

  fmt = '(1F8.1)'               ; Output format for NEFDs

  nk_average_scans, param, scan_list, coadded_map

  beam_1mm = 12.0
  beam_2mm = 18.2
  sigma_1mm = beam_1mm/(2 * sqrt((2 * alog(2))))
  sigma_2mm = beam_2mm/(2 * sqrt((2 * alog(2))))

  tab_beam = [beam_1mm,beam_2mm,beam_1mm]
  tab_sigma = [sigma_1mm,sigma_2mm,sigma_1mm]

  map_A1 = (coadded_map.map_i1)
  var_A1 = (coadded_map.map_var_i1)
  time_A1 = (coadded_map.nhits_1/!nika.f_sampling)
  map_A2 = (coadded_map.map_i2)
  var_A2 = (coadded_map.map_var_i2)
  time_A2 = (coadded_map.nhits_2/!nika.f_sampling)
  map_A3 = (coadded_map.map_i3)
  var_A3 = (coadded_map.map_var_i3)
  time_A3 = (coadded_map.nhits_3/!nika.f_sampling)

  nmap = n_elements(scan_list)
  nx = n_elements(map_A1[*,0])
  ny = n_elements(map_A1[0,*])

  map_jy_per_scan_A1 = dblarr(nx,ny,nmap)
  map_jy_per_scan_A2 = dblarr(nx,ny,nmap)
  map_jy_per_scan_A3 = dblarr(nx,ny,nmap)
  map_var_per_scan_A1 = dblarr(nx,ny,nmap)
  map_var_per_scan_A2 = dblarr(nx,ny,nmap)
  map_var_per_scan_A3 = dblarr(nx,ny,nmap)

  for iscan = 0, nmap-1 do begin
     dir = param.project_dir+"/v_"+strtrim(param.version,2)+"/"+strtrim(scan_list[iscan], 2)
     ;; Check if the requested result file exists
     file_save = dir+"/results.save"
     if file_test(file_save) eq 0 then begin
        message, /info, file_save+" not found"
     endif else begin
        ;; Restore results of each individual scan
        restore, file_save
        map_jy_per_scan_A1[*,*,iscan] = grid1.map_i1
        map_jy_per_scan_A2[*,*,iscan] = grid1.map_i2
        map_jy_per_scan_A3[*,*,iscan] = grid1.map_i3
        map_var_per_scan_A1[*,*,iscan] = grid1.map_var_i1
        map_var_per_scan_A2[*,*,iscan] = grid1.map_var_i2
        map_var_per_scan_A3[*,*,iscan] = grid1.map_var_i3
     endelse
  endfor

  ;;==================== Sensitivity computed using Jack-Knifes
  if nmap gt 1 then begin
     ;;------- Get the J-K
     ordre = sort(randomn(seed, nmap))
     map_jk_A1 = nk_jackknife(map_jy_per_scan_A1[*,*,ordre], map_var_per_scan_A1[*,*,ordre])
     map_jk_A2 = nk_jackknife(map_jy_per_scan_A2[*,*,ordre], map_var_per_scan_A2[*,*,ordre])
     map_jk_A3 = nk_jackknife(map_jy_per_scan_A3[*,*,ordre], map_var_per_scan_A3[*,*,ordre])
     map_jk_A1 *= 0.5
     map_jk_A2 *= 0.5
     map_jk_A3 *= 0.5
     
     ;;------- Histo of sensitivity from JK
     map_sens_A1 = map_jk_A1*sqrt(time_A1) 
     map_sens_A2 = map_jk_A2*sqrt(time_A2)
     map_sens_A3 = map_jk_A3*sqrt(time_A3)

     npix = nx
     reso = param.map_reso
     xmap = (dindgen(npix)-npix/2)*reso # replicate(1, npix)
     ymap = (dindgen(npix)-npix/2)*reso ## replicate(1, npix)
     rmap = sqrt(xmap^2+ymap^2)   
 
     wsens_A1 = where(finite(map_sens_A1) eq 1 and time_A1 gt 0 and map_jk_A1 ne 0 and rmap gt param.decor_cm_dmin,nwsens_A1,comp=wnosens_A1,ncomp=nwnosens_A1)
     wsens_A2 = where(finite(map_sens_A2) eq 1 and time_A2 gt 0 and map_jk_A2 ne 0 and rmap gt param.decor_cm_dmin,nwsens_A2,comp=wnosens_A2,ncomp=nwnosens_A2)
     wsens_A3 = where(finite(map_sens_A3) eq 1 and time_A3 gt 0 and map_jk_A3 ne 0 and rmap gt param.decor_cm_dmin,nwsens_A3,comp=wnosens_A3,ncomp=nwnosens_A3)
   
     if nwsens_A1 eq 0 then message, 'No pixel available for Jack-Knife'
     if nwsens_A2 eq 0 then message, 'No pixel available for Jack-Knife'
     if not keyword_set(NIKA1) then begin
        if nwsens_A3 eq 0 then message, 'No pixel available for Jack-Knife'
     endif

     map_sens_A1_clean = map_sens_A1*0.
     map_sens_A2_clean = map_sens_A2*0.
     map_sens_A3_clean = map_sens_A3*0.

     map_sens_A1_clean[wsens_A1] = map_sens_A1[wsens_A1]
     map_sens_A2_clean[wsens_A2] = map_sens_A2[wsens_A2]
     if not keyword_set(NIKA1) then map_sens_A3_clean[wsens_A3] = map_sens_A3[wsens_A3]

     map_sens_A1_clean *= 1e3
     map_sens_A2_clean *= 1e3
     map_sens_A3_clean *= 1e3
  
     tab_map_sens = dblarr(npix,npix,3)
     tab_map_sens[*,*,0] = map_sens_A1_clean
     tab_map_sens[*,*,1] = map_sens_A2_clean
     tab_map_sens[*,*,2] = map_sens_A3_clean

     map_fit_beam = dblarr(npix,npix,3)
     sensitivity = dblarr(3)
     
     for iarray=0, 2 do begin
        radmax = npix/2. * reso - n_sigma*tab_sigma[iarray]
        irad = 1
        r_fit_center = param.decor_cm_dmin + irad*n_sigma*tab_sigma[iarray]
        
        while r_fit_center lt radmax do begin
           perimeter = 2.*!pi*r_fit_center
           n_beam_fit = fix(perimeter/(2.*n_sigma*tab_sigma[iarray]))
           
           for ibeam=0,n_beam_fit-1 do begin
              pos = [cos(ibeam*2.*!pi/n_beam_fit+(!pi/4.))*r_fit_center,sin(ibeam*2.*!pi/n_beam_fit+(!pi/4.))*r_fit_center]
              nika_pipe_fit_beam, tab_map_sens[*,*,iarray], reso, var=map_sens_A1_clean*0.+1., /CIRCULAR, center=pos, FWHM=tab_beam[iarray], $
                                  coeff=coeff_mc, best_fit=model_mc, err_coeff=err_coeff_mc, /sil
              if irad eq 1 and ibeam eq 0 then begin
                 tab_fluxes = coeff_mc[1]
              endif else begin
                 tab_fluxes = [tab_fluxes,coeff_mc[1]]
              endelse
              map_fit_beam[*,*,iarray] += model_mc - coeff_mc[0]
           endfor
           irad += 2
           r_fit_center = param.decor_cm_dmin + irad*n_sigma*tab_sigma[iarray]
        endwhile
        sensitivity[iarray] = nk_stddev(tab_fluxes)
     endfor

     mask = rmap * 0. + 1.
     wmask = where(abs(xmap) le param.decor_cm_dmin and abs(ymap) le param.decor_cm_dmin)
     mask[wmask] = 0.

     map_width = npix * reso
     frame_pos = [npix/2. * reso, npix/2. * reso]
     map_fit_beam2 = dblarr(npix,npix,3)
     sensitivity2 = dblarr(3)

     for iarray=0, 2 do begin
        N_intervals = fix((map_width-2.*n_sigma*tab_sigma[iarray])/(2.*n_sigma*tab_sigma[iarray]))
        dx = (map_width - N_intervals*2.*n_sigma*tab_sigma[iarray])/2.
        dy = dx

        shift_test = n_sigma*tab_sigma[iarray]/reso
        shift_test_diag = (shift_test/sqrt(2.))/reso

        for i=0, N_intervals do begin
           for j=0, N_intervals do begin
              pos_x = dx + i*2.*n_sigma*tab_sigma[iarray]
              pos_y = dy + j*2.*n_sigma*tab_sigma[iarray]
              pos_x_center = pos_x - frame_pos[0]
              pos_y_center = pos_y - frame_pos[1]
              pos_x_center_pix = pos_x/reso
              pos_y_center_pix = pos_y/reso

              if (i eq 0 or j eq 0 or i eq N_intervals or j eq N_intervals) then begin
                 pos = [pos_x_center,pos_y_center]
                 nika_pipe_fit_beam, tab_map_sens[*,*,iarray], reso, var=map_sens_A1_clean*0.+1., /CIRCULAR, center=pos, FWHM=tab_beam[iarray], $
                                     coeff=coeff_mc, best_fit=model_mc, err_coeff=err_coeff_mc, /sil
                 if i eq 0 and j eq 0 then begin
                    tab_fluxes2 = coeff_mc[1]
                 endif else begin
                    tab_fluxes2 = [tab_fluxes2,coeff_mc[1]]
                 endelse
                 map_fit_beam2[*,*,iarray] += model_mc - coeff_mc[0]
              endif else if ((mask[pos_x_center_pix,pos_y_center_pix] ne 0.) and (mask[pos_x_center_pix+shift_test,pos_y_center_pix] ne 0.) $
                             and (mask[pos_x_center_pix,pos_y_center_pix+shift_test] ne 0.) and (mask[pos_x_center_pix-shift_test,pos_y_center_pix] ne 0.) $
                             and (mask[pos_x_center_pix,pos_y_center_pix-shift_test] ne 0.) and (mask[pos_x_center_pix+shift_test_diag,pos_y_center_pix+shift_test_diag] ne 0.) $
                             and (mask[pos_x_center_pix-shift_test_diag,pos_y_center_pix+shift_test_diag] ne 0.) and (mask[pos_x_center_pix-shift_test_diag,pos_y_center_pix-shift_test_diag] ne 0.) $
                             and (mask[pos_x_center_pix+shift_test_diag,pos_y_center_pix-shift_test_diag] ne 0.)) then begin
                 pos = [pos_x_center,pos_y_center]
                 nika_pipe_fit_beam, tab_map_sens[*,*,iarray], reso, var=map_sens_A1_clean*0.+1., /CIRCULAR, center=pos, FWHM=tab_beam[iarray], $
                                     coeff=coeff_mc, best_fit=model_mc, err_coeff=err_coeff_mc, /sil
                 tab_fluxes2 = [tab_fluxes2,coeff_mc[1]]
                 map_fit_beam2[*,*,iarray] += model_mc - coeff_mc[0]
              endif
           endfor
        endfor
        sensitivity2[iarray] = nk_stddev(tab_fluxes2)
     endfor

     if n_elements(tab_fluxes) gt n_elements(tab_fluxes2) then begin
        print, '=========================================='
        print, '======= Mean sensitivity found from Jack-Knife: '
        print, '=======    1 mm A1: '+string(sensitivity[0], format = fmt)+' mJy.sqrt(s)/Beam'
        print, '=======    2 mm A2: '+string(sensitivity[1], format = fmt)+' mJy.sqrt(s)/Beam'
        print, '=======    1 mm A3: '+string(sensitivity[2], format = fmt)+' mJy.sqrt(s)/Beam'
        print, '=========================================='
     endif else begin
        print, '=========================================='
        print, '======= Mean sensitivity found from Jack-Knife: '
        print, '=======    1 mm A1: '+string(sensitivity2[0], format = fmt)+' mJy.sqrt(s)/Beam'
        print, '=======    2 mm A2: '+string(sensitivity2[1], format = fmt)+' mJy.sqrt(s)/Beam'
        print, '=======    1 mm A3: '+string(sensitivity2[2], format = fmt)+' mJy.sqrt(s)/Beam'
        print, '=========================================='
     endelse

     position1 = [0.05,0.05,0.25,0.95]
     position2 = [0.375,0.05,0.575,0.95]
     position3 = [0.675,0.05,0.875,0.95]
     
     window,2,XSIZE=1200, YSIZE=500
     imview,map_sens_A1_clean,coltable=39,beam=12./2.,unitsbar='mJy.sqrt(s)', $
title='Sensitivity map A1',position=position1, /noerase, /noclose, xcharsize=0.7, ycharsize=0.7,charbar=0.7,charsize=0.7
     imview,map_sens_A2_clean,coltable=39,beam=18./2.,unitsbar='mJy.sqrt(s)', $
title='Sensitivity map A2',position=position2, /noerase, /noclose, xcharsize=0.7, ycharsize=0.7,charbar=0.7,charsize=0.7
     imview,map_sens_A3_clean,coltable=39,beam=12./2.,unitsbar='mJy.sqrt(s)', $
title='Sensitivity map A3',position=position3, /noerase, /noclose, xcharsize=0.7, ycharsize=0.7,charbar=0.7,charsize=0.7

     window,3,XSIZE=1200, YSIZE=500
     imview,map_fit_beam[*,*,0],coltable=39,beam=12./2.,unitsbar='mJy.sqrt(s)', $
title='Sensitivity per beam A1',position=position1, /noerase, /noclose, xcharsize=0.7, ycharsize=0.7,charbar=0.7,charsize=0.7
     imview,map_fit_beam[*,*,1],coltable=39,beam=18./2.,unitsbar='mJy.sqrt(s)', $
title='Sensitivity per beam A2',position=position2, /noerase, /noclose, xcharsize=0.7, ycharsize=0.7,charbar=0.7,charsize=0.7
     imview,map_fit_beam[*,*,2],coltable=39,beam=12./2.,unitsbar='mJy.sqrt(s)', $
title='Sensitivity per beam A3',position=position3, /noerase, /noclose, xcharsize=0.7, ycharsize=0.7,charbar=0.7,charsize=0.7

     window,4,XSIZE=1200, YSIZE=500
     imview,map_fit_beam2[*,*,0],coltable=39,beam=12./2.,unitsbar='mJy.sqrt(s)', $
title='Sensitivity per beam A1',position=position1, /noerase, /noclose, xcharsize=0.7, ycharsize=0.7,charbar=0.7,charsize=0.7
     imview,map_fit_beam2[*,*,1],coltable=39,beam=18./2.,unitsbar='mJy.sqrt(s)', $
title='Sensitivity per beam A2',position=position2, /noerase, /noclose, xcharsize=0.7, ycharsize=0.7,charbar=0.7,charsize=0.7
     imview,map_fit_beam2[*,*,2],coltable=39,beam=12./2.,unitsbar='mJy.sqrt(s)', $
title='Sensitivity per beam A3',position=position3, /noerase, /noclose, xcharsize=0.7, ycharsize=0.7,charbar=0.7,charsize=0.7
     
     stop
   
  endif else begin
   nk_error, info, "You need to give more than one map to compute a Jack-knife"
  endelse

  return
end
