
;; Version of imcm_source_analysis that works on a single scan and
;; with a user defined "input_dir_basename"
;;
;; It is meant to be used to reduce several single scans with self
;; iterations, without combination between the scans.
;;--------------------------------------------------------------------

;+
pro imcm_aux, iscan, iter, input_txt_file, input_scan_list_file, input_dir_basename, $
              iscan_min=iscan_min, noheader=noheader, noplot=noplot
;-
if n_params() lt 1 then begin
   dl_unix, 'imcm_aux'
   return
endif

;; Get input parameters
@read_imcm_input_txt_file

;; Need iscan_min to maintain capacity to use "split_for" in IDL
;; parallelization mode (see imcm.pro)
iscan_effective = iscan
if keyword_set(iscan_min) then iscan_effective += iscan_min

;; Get list of scans
readcol, input_scan_list_file, scan_list, format='A', comment='#', /silent

if defined(reset_preproc_data) then begin
   if reset_preproc_data eq 1 and iter eq 0 then begin
      spawn, "rm -f "+param.preproc_dir+"/*"+scan_list[iscan_effective]+"*save"
      spawn, "rm -rf "+param.project_dir+"/v_1/"+scan_list[iscan_effective]
   endif
endif
  
;; ;; Reduce scan
;; if parity ne 0 then parity = (-1)^iscan_effective

;; overwrite dir_basename ( != imcm_source_analysis)
dir_basename = input_dir_basename+"_"+strtrim(scan_list[iscan],2)

param.project_dir = dir_basename+"/iter"+strtrim(iter,2)

;;print, param.project_dir

if not keyword_set(noheader) then begin
;; Init projection header and update param and info
   if defined(output_fits_header_file) then begin
      junk = mrdfits( output_fits_header_file, fits_extension, header)
      delvarx, junk
      extast, header, astr
      nk_astr2param, astr, param
   endif else begin
      get_source_header, source, header, param=param, info=info
   endelse

   ;; In case a different header is requested at 2mm
   if defined(output_fits_second_header_file) then begin
      junk = mrdfits( output_fits_second_header_file, fits_extension, second_header)
      delvarx, junk
   endif
endif

;; Retrieve subtract_maps if needed
if defined(previous_map_file) eq 0 then previous_map_file = dir_basename+"/subtract_maps_"+strtrim(iter-1,2)+".save"
if file_test( previous_map_file) then restore, previous_map_file

;; Force the mask to the requested input (if any)
if defined(force_mask_file) then begin
   restore, force_mask_file
   nk_default_info, info
   if defined(subtract_maps) eq 0 then begin
      extast, header, astr
      nk_init_grid_2, param, info, subtract_maps, astr=astr
   endif
;; replace the default mask by the forced one
;;   subtract_maps.iter_mask_1mm = grid_mask.iter_mask_1mm
;;   subtract_maps.iter_mask_2mm = grid_mask.iter_mask_2mm

;; upgrade the default mask with the default one
   w = where( grid_mask.iter_mask_1mm gt 0., nw)
   if nw ne 0 then subtract_maps.iter_mask_1mm[w] = grid_mask.iter_mask_1mm[w]
   w = where( grid_mask.iter_mask_2mm gt 0., nw)
   if nw ne 0 then subtract_maps.iter_mask_2mm[w] = grid_mask.iter_mask_2mm[w]
endif

;; Either add simulated signal on top of data (simpar.parity=0) or
;; remove astro signal (jackknife like) from simulations (simpar.parity=1)
parity = 0
if defined(simpar_file) then begin
   restore, simpar_file
   parity = simpar.parity
endif

;; Process scan
nk, scan_list[iscan_effective], param=param, header=header, grid=grid, $
    subtract_maps=subtract_maps, simpar=simpar, parity=parity, polar=polar, second_header=second_header

;;----------------------------------------------------------------------------------------------------------
;; Build the mask for the next iteration
subtract_maps = grid
subtract_maps.map_i_2mm = subtract_maps.map_i2
subtract_maps.iter_mask_1mm = 1.d0
subtract_maps.iter_mask_2mm = 1.d0
if keyword_set(radius_iter_mask) then begin
   w = where( sqrt( subtract_maps.xmap^2 + subtract_maps.ymap^2) gt radius_iter_mask, nw)
   if nw ne 0 then begin
      subtract_maps.iter_mask_1mm[w] = 0.d0
      subtract_maps.iter_mask_2mm[w] = 0.d0
   endif
endif

np_warning, text="In imcm_aux.pro:"
np_warning, text="uniform mask inside radius "+strtrim(radius_iter_mask,2)+", NO SNR threhold", /add

;; if not keyword_set(snr_thres_1mm) then snr_thres_1mm = 6.d0
;; if not keyword_set(snr_thres_2mm) then snr_thres_2mm = 6.d0
;; if not keyword_set(title_in)      then title_in = ''
;; 
;; map_ext = ['_1mm', '2']
;; hits_ext = ['1mm', '2']
;; snr_thres = [snr_thres_1mm, snr_thres_2mm]
;; my_plot_window = 0
;; sigma_boost_1mm = 0.d0 ; default output
;; sigma_boost_1mm = 0.d0
;; for iext=0, n_elements(map_ext)-1 do begin
;;    junk = execute( "map     = grid.map_i"+map_ext[iext])
;;    junk = execute( "map_var = grid.map_var_i"+map_ext[iext])
;;    junk = execute( "nhits   = grid.nhits_"+hits_ext[iext])
;; 
;;    if max(nhits) gt 0 then begin
;;       nk_map_photometry, map, map_var, nhits, $
;;                          grid.xmap, grid.ymap, !nika.fwhm_array[iext], $
;;                          flux, sigma_flux, grid_step=!nika.grid_step[iext], $
;;                          sigma_boost=sigma_boost, map_var_flux=map_var_flux, $
;;                          map_flux=map_flux, /noplot
;;       if iext eq 0 then sigma_boost_1mm = sigma_boost else sigma_boost_2mm = sigma_boost
;; 
;;       snr = grid.xmap*0.d0
;;       w = where( map_var_flux ne 0, nw)
;;       snr[w] = sqrt( map_flux[w]^2/map_var_flux[w])
;; 
;;       if keyword_set(sz) then begin
;;          ;; Keep negative significant values as signal
;;          mask = double(snr gt snr_thres[iext])
;;       endif else begin
;;          mask = double(snr gt snr_thres[iext] and map_flux gt 0.d0)
;;       endelse
;; 
;;       ;; smooth a bit to take margin
;;       nk_smooth = round( !nika.fwhm_nom[iext]/grid.map_reso)
;;       k = dblarr(nk_smooth,nk_smooth) + 1.d0/nk_smooth^2
;;       mask = convol( mask, k) gt 0.d0
;;       
;;       ;; Take margin on the edges if requested to avoid working on too
;;       ;; high variance regions
;;       if keyword_set(radius_max) then begin
;;          w = where( sqrt(subtract_maps.xmap^2 + subtract_maps.ymap^2) gt radius_max, nw)
;;          if nw ne 0 then mask[w] = 0.d0
;;       endif
;; 
;;       ;; Pass the mask to the output structure
;;       junk = execute( "subtract_maps.iter_mask_"+strtrim(iext+1,2)+"mm = mask")
;; 
;;       ;; Display
;;       if not keyword_set(noplot) then begin
;;          imr_1 = [-1,1]*2*stddev(subtract_maps.map_i_1mm)/50.
;;          imr_2 = [-1,1]*2*stddev(subtract_maps.map_i2)/50.
;;          if my_plot_window eq 0 then wind, 1, 1, /free, /large
;;          my_plot_window = !d.window
;;          my_multiplot, 2, 2, pp, pp1, /rev
;;          junk = execute( "map = subtract_maps.map_i_"+strtrim(iext+1,2)+"mm")
;;          junk = execute( "mask = subtract_maps.iter_mask_"+strtrim(iext+1,2)+"mm")
;;          if iext eq 0 then imr = imr_1 else imr = imr_2
;;          w = where( map ne 0.d0, nw)
;;          imview, map, position=pp[iext,0,*], /noerase, title=strtrim(iext+1,2)+$
;;                  'mm (smoothed 5 arcsec) '+title_in, fwhm=5., imr=[-1,1]*stddev(map[w])
;;          imview, mask, position=pp[iext,1,*], /noerase, title='Mask '+strtrim(iext+1,2)+'mm'
;;       endif
;;    endif
;; endfor

save, subtract_maps, file=dir_basename+"/subtract_maps_"+strtrim(iter,2)+".save"


end
