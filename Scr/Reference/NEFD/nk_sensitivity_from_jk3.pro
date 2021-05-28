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
;        - January, 2017: clean up, NP.
;-

pro nk_sensitivity_from_jk3, param, scan_list, nefd_center_res, $
                             map_jy_1, map_jy_2, $
                             map_var_1, map_var_2, $
                             NIKA1=NIKA1, jk_tgb=jk_tgb, noplot=noplot
  
;; Number of standard deviations to consider the fitted beams independent
n_sigma = 5.

;; Init result
nefd_center_res = dblarr(4)
jk_tgb = dblarr(4)

;; Generate average map from all the scans
nk_average_scans, param, scan_list, coadded_map, noplot=noplot
nscans = n_elements(scan_list)

;; Restore results of each individual scan
map_jy_per_scan  = dblarr( coadded_map.nx, coadded_map.ny, 4, nscans)
map_var_per_scan = dblarr( coadded_map.nx, coadded_map.ny, 4, nscans)
p = 0
for iscan = 0, nscans-1 do begin
   dir = param.project_dir+"/v_"+strtrim(param.version,2)+"/"+strtrim(scan_list[iscan], 2)
   file_save = dir+"/results.save"
   if file_test(file_save) eq 0 then begin
      message, /info, file_save+" not found"
   endif else begin
      restore, file_save
      for iarray=1, 4 do begin
         case iarray of
            1: begin
               map_jy_per_scan[  *, *, iarray-1, p] = grid1.map_i1
               map_var_per_scan[ *, *, iarray-1, p] = grid1.map_var_i1
            end
            2: begin
               map_jy_per_scan[  *, *, iarray-1, p] = grid1.map_i2
               map_var_per_scan[ *, *, iarray-1, p] = grid1.map_var_i2
            end
            3: begin
               map_jy_per_scan[  *, *, iarray-1, p] = grid1.map_i3
               map_var_per_scan[ *, *, iarray-1, p] = grid1.map_var_i3
            end
            4: begin            ; combined 1mm map
               map_jy_per_scan[  *, *, iarray-1, p] = grid1.map_i_1mm
               map_var_per_scan[ *, *, iarray-1, p] = grid1.map_var_i_1mm
            end
         endcase
      endfor
      p++
   endelse
endfor

;; Discard empty maps if any
if p ne nscans then begin
   map_jy_per_scan  = map_jy_per_scan[  *,*,*,0:p-1]
   map_var_per_scan = map_var_per_scan[ *,*,*,0:p-1]
   nscans = p
endif

;;==================== Sensitivity computed using Jack-Knifes
if nscans gt 1 then begin
   ordre = sort(randomn(seed, nscans))

   npix = min( [coadded_map.nx, coadded_map.ny])

   if not keyword_set(noplot) then begin
      wind, 1, 1, /free, /xlarge
      my_multiplot, 4, 1, pp, pp1, /rev
   endif
   
   for iarray=1, 4 do begin
      delvarx, xlist, ylist
      case iarray of
         1: nhits = coadded_map.nhits_1 ; /!nika.f_sampling
         2: nhits = coadded_map.nhits_2
         3: nhits = coadded_map.nhits_3
         4: nhits = coadded_map.nhits_1mm
      endcase
      if iarray le 3 then begin
         fwhm = !nika.fwhm_array[iarray-1]
         grid_step = !nika.grid_step[iarray-1]
      endif else begin
         ;; Do not define time_map with nhits_1mm otherwise
         ;; it's about twice too much (see 'human_obs_time'
         ;; in nk_grid2info)
         fwhm = !nika.fwhm_array[0]
         grid_step = !nika.grid_step[0]
         nhits = coadded_map.nhits_1
         w = where( nhits eq 0 and coadded_map.nhits_3 ne 0, nw)
         if nw ne 0 then nhits[w] = coadded_map.nhits_3[w]
      endelse
      
      time_map = nhits/!nika.f_sampling

      ;; ------- Get the J-K
      ;; Need to reshape arrays for nk_jackknive
      map_all_scans = reform( map_jy_per_scan[*,*,iarray-1,ordre], $
                              coadded_map.nx, coadded_map.ny, nscans)
      map_var_all_scans = reform( map_var_per_scan[*,*,iarray-1,ordre], $
                                  coadded_map.nx, coadded_map.ny, nscans)
      map_jk = 0.5*nk_jackknife( map_all_scans, map_var_all_scans, map_jy_1, map_jy_2, $
                                 map_var_1, map_var_2, map_var_out=map_var)

      ;;------- Histo of sensitivity from JK
      map_sens = map_jk*sqrt(time_map) 

      rmap = sqrt(coadded_map.xmap^2+coadded_map.ymap^2)   
      wsens = where(finite(map_sens) eq 1 and time_map gt 0 and map_jk ne 0 and $
                    rmap gt param.decor_cm_dmin, nwsens, comp=wnosens, ncomp=nwnosens)

      ;; check if maps are well behaved and if array 3 is present (NIKA2 vs NIKA1)
      if nwsens ne 0 then begin
         ;; Define the location of point where a flux will be measured
         sigma_beam = fwhm*!fwhm2sigma
         radmax = npix/2. * coadded_map.map_reso - n_sigma*sigma_beam
         irad = 1
         r_fit_center = param.decor_cm_dmin + irad*n_sigma*sigma_beam
         while r_fit_center lt radmax do begin
            perimeter = 2.*!pi*r_fit_center
            n_beam_fit = fix(perimeter/(2.*n_sigma*sigma_beam))
            for ibeam=0,n_beam_fit-1 do begin
               x = cos(ibeam*2.*!pi/n_beam_fit+(!pi/4.))*r_fit_center
               y = sin(ibeam*2.*!pi/n_beam_fit+(!pi/4.))*r_fit_center
               if defined(xlist) then xlist = [xlist, x] else xlist=[x]
               if defined(ylist) then ylist = [ylist, y] else ylist=[y]
            endfor
            irad += 2
            r_fit_center = param.decor_cm_dmin + irad*n_sigma*sigma_beam
         endwhile

         beam_pos_list = dblarr(n_elements(xlist),2)
         beam_pos_list[*,0] = xlist
         beam_pos_list[*,1] = ylist
         if iarray le 3 then title = 'JK map, A'+strtrim(iarray,2) else title='Combined A1 & A3'
         if defined(pp1) then position=pp1[iarray-1,*]
         nk_map_photometry, map_jk, map_var, nhits, coadded_map.xmap, coadded_map.ymap, fwhm, $
                            flux, sigma_flux, $
                            sigma_bg, output_fit_par, output_fit_par_error, $
                            bg_rms_source, flux_center, sigma_flux_center, sigma_bg_center, $
                            sigma_beam_pos=sigma_beam_pos, grid_step=grid_step, $
                            /educated, $
                            map_flux=map_flux, map_var_flux=map_var_flux, $
                            position=position, $
                            title=title, param=param, $
                            NEFD_source=NEFD_source, NEFD_center=NEFD_center, $
                            ps_file=ps_file, $
                            sigma_flux_center_toi=sigma_flux_center_toi, map_sn_smooth = map_sn_smooth, $
                            coltable = coltable, $
                            charsize=charsize, inside_bar=inside_bar, $
                            short_legend=short_legend, nobar=nobar, noplot=noplot, $
                            charbar=charbar, extra_leg_txt=extra_leg_txt, extra_leg_col=extra_leg_col, $
                            source=param.source, ata_fit_beam_rmax=ata_fit_beam_rmax, $
                            best_model=best_model, $
                            time_matrix_center=time_matrix_center, t_gauss_beam=t_gauss_beam
         
         fmt = "(F6.2)"
         if iarray le 3 then begin
            print, '            A'+strtrim(iarray,2)+': NEFD Center on Jack-knife map : '+$
                   strtrim( string( NEFD_center*1000, format = fmt), 2)+' mJy.sqrt(s)/Beam'
         endif else begin
            print, 'Combined A1+A3: NEFD Center on Jack-knife map : '+$
                   strtrim( string( NEFD_center*1000, format = fmt), 2)+' mJy.sqrt(s)/Beam'
         endelse
         nefd_center_res[iarray-1] = NEFD_center*1000

;;         if iarray le 3 then begin
;;            print, '            A'+strtrim(iarray,2)+': sigma_flux_center*sqrt(time_matrix_center): '+$
;;                   strtrim( string( sigma_flux_center*sqrt(time_matrix_center)*1000, format = fmt), 2)+' mJy.sqrt(s)/Beam'
;;         endif else begin
;;            print, 'Combined A1+A3: sigma_flux_center*sqrt(time_matrix_center): ', $
;;                   strtrim( string( sigma_flux_center*sqrt(time_matrix_center)*1000, format = fmt), 2)+' mJy.sqrt(s)/Beam'
;;         endelse

         if iarray le 3 then begin
            print, '            A'+strtrim(iarray,2)+': sigma_flux_center*sqrt(t_gauss_beam): '+$
                   strtrim( string( sigma_flux_center*sqrt(t_gauss_beam)*1000, format = fmt), 2)+' mJy.sqrt(s)/Beam'
         endif else begin
            print, 'Combined A1+A3: sigma_flux_center*sqrt(t_gauss_beam): ', $
                   strtrim( string( sigma_flux_center*sqrt(t_gauss_beam)*1000, format = fmt), 2)+' mJy.sqrt(s)/Beam'
         endelse
         jk_tgb[iarray-1] = sigma_flux_center*sqrt(t_gauss_beam)*1000
      endif
   endfor
   
endif else begin
   nk_error, info, "You need to give more than one map to compute a Jack-knife"
endelse

end
