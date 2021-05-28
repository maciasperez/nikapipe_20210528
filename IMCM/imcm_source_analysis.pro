
;+
pro imcm_source_analysis, iscan, input_txt_file, scan_list_file, iter, $
                          iscan_min=iscan_min, $
                          noheader=noheader, cp=cp, $
                          SelfScanIteration=SelfScanIteration
;-

if n_params() lt 1 then begin
   dl_unix, 'imcm_source_analysis'
   return
endif

;; Get input parameters
@read_imcm_input_txt_file
param.project_dir = dir_basename+"/iter"+strtrim(iter,2)
param.imcm_iter = iter
;;;print, param.map_xsize, ' arcsec for the map 1'

;; for the slurm log file
print, param.project_dir

if keyword_set(cp) then begin
   ; FXD 12 nov 2020, needed sometimes
   if not file_test( dir_basename, /dir) then spawn, 'mkdir -p '+dir_basename 
   ;; print, iscan, ' ', "\cp "+input_txt_file+" "+dir_basename+"/."
   spawn, "\cp "+input_txt_file+" "+dir_basename+"/."
   spawn, "\cp "+scan_list_file+" "+dir_basename+"/."
endif

;; Get list of scans
;; get_scan_list, source, scan_list, g2_tau_max=g2_tau_max, nscans_max=nscans_max, laurence=laurence
readcol, scan_list_file, scan_list, format='A', comment='#', /silent

pastart = param
infostart = info
if not keyword_set(noheader) then begin
;; Init projection header and update param and info
   if defined(output_fits_header_file) then begin
      ;; LP fits_extension needs to be defined
      ;; fits_extension = 0
      ;; NP: double fix :) Need to check for existence in input_txt_file
      if defined(fits_extension) eq 0 then fits_extension = 0
      junk = mrdfits( output_fits_header_file, fits_extension, nkheader)
      if defined(nkheader) eq 0 then  begin
          fits_extension=0
          junk = mrdfits( output_fits_header_file, fits_extension, nkheader)
      endif    
      delvarx, junk
      extast, nkheader, astr
      nk_astr2param, astr, param
   endif else begin
      get_source_header, source, nkheader, param=param, info=info
   endelse

   ;; In case a different header is requested at 2mm
   if defined(output_fits_second_header_file) then begin
      junk = mrdfits( output_fits_second_header_file, fits_extension, second_header)
      delvarx, junk
   endif
endif

if param.new_method eq "NEW_DECOR_ATMB_PER_ARRAY" then begin
   ; reinstate wanted parameters
   param.map_xsize = pastart.map_xsize
   param.map_ysize = pastart.map_ysize
   info.longobj = infostart.longobj
   info.latobj = infostart.latobj
endif

;;; print, param.map_xsize, ' arcsec for the map 2'

;; Need iscan_min to maintain capacity to use "split_for" in IDL
;; parallelization mode (see imcm.pro)
iscan_effective = iscan
if keyword_set(iscan_min) then iscan_effective += iscan_min

if defined(reset_preproc_data) then begin
   if reset_preproc_data eq 1 and param.imcm_iter eq 0 then begin
      spawn, "rm -f "+param.preproc_dir+"/data_"+scan_list[iscan_effective]+".save"
      spawn, "rm -rf "+param.project_dir+"/v_1/"+scan_list[iscan_effective]
   endif
endif

if defined(reset_noise) then begin
   if reset_noise eq 1 and iter eq 0 then spawn, "rm -f "+param.preproc_dir+"/noise_"+scan_list[iscan_effective]+".save"
endif

;; Retrieve subtract_maps if needed
if keyword_set(SelfScanIteration) then begin
   previous_map_file = param.project_dir+"/v_"+strtrim(param.version,2)+"/"+ $
                       scan_list[iscan]+"/results.save"
endif else begin
   previous_map_file = dir_basename+"/subtract_maps_"+ $
                       strtrim(param.imcm_iter-1,2)+".save"
   if param.imcm_iter eq 0 and strlen( param.atmb_init_subtract_file) gt 0 then $
      previous_map_file = param.atmb_init_subtract_file
   lf_decor_map =  0            ; default init
   lf_mapin_fileh = ''
   lf_mapin_filev = ''
   
   if keyword_set( param.split_horver) and param.imcm_iter gt 0 then begin
      lf_mapin_filejk = dir_basename+"/map_JK_"+ $
                       strtrim(param.imcm_iter-1,2)+".save"
      lf_mapin_fileh = dir_basename+"/map_HOR_"+ $
                       strtrim(param.imcm_iter-1,2)+".save"
      lf_mapin_filev = dir_basename+"/map_VER_"+ $
                       strtrim(param.imcm_iter-1,2)+".save"
      info_csv_file = dir_basename+"/iter"+strtrim(param.imcm_iter-1,2)+ $
                      '/v_'+ strtrim(param.version, 2)+'/' + $
                      scan_list[iscan]+'/info.csv'
      if file_test(info_csv_file) then begin
         nk_read_csv_2, info_csv_file, infoscan
         hor = infoscan.scan_angle gt param.split_hor1 and $
               infoscan.scan_angle lt param.split_hor2
                                ; hor 1 means it is a horizontal scan
      endif else begin
         if param.imcm_iter ge 1 then begin
            message, /info, $
                     'That scan could not be processed, missing '+ info_csv_file
            return
         endif
      endelse
      if param.split_horver eq 3 then begin  ; special case
         info_all_csv_file = dir_basename+'/iter'+strtrim(param.imcm_iter-1,2)+ $
                             '/info_all_'+ param.source+ $
                             '_v'+ strtrim(param.version, 2)+'.csv'
         message, /info, 'info_all_csv_file '+ info_all_csv_file
         nk_read_csv_3, info_all_csv_file, inforead
         hor_all = inforead.scan_angle gt param.split_hor1 and $
               inforead.scan_angle lt param.split_hor2
         nk_jk_horver_scan_assign, hor_all, pindex1, jksign1
     endif
      
   endif                        ; end HorVer case
                                ; end no self scan interaction
endelse 

;message, /info, 'HorVer option: '+ lf_mapin_fileh

if file_test( previous_map_file) then restore, previous_map_file else $
   if param.imcm_iter ge 1 then $
      message, /info, 'Warning: this file should exist '+ previous_map_file $
   else $
      if strlen( param.atmb_init_subtract_file) gt 0 then $
         message, /info, 'Warning: this file should exist '+ previous_map_file         

if keyword_set( param.split_horver) and param.imcm_iter gt 0 then begin
   case param.split_horver of
      1: begin
; case when we read the vertical map for the horizontal scans (hor=1) and vice versa
         if file_test( lf_mapin_fileh) then restore, lf_mapin_fileh else $
            message, 'This file is missing, cannot go on '+ lf_mapin_fileh
         if file_test( lf_mapin_filev) then restore, lf_mapin_filev else $
            message, 'This file is missing, cannot go on '+ lf_mapin_filev
         if hor then lf_decor_map = map_ver else lf_decor_map = map_hor
;; The defilter option needs to add the vertical low frequency signal
;; back to the decorrelated TOI, so the sign is +
      ;; lf_decor_map.map_i1    =  -lf_decor_map.map_i1    
      ;; lf_decor_map.map_i2    =  -lf_decor_map.map_i2   
      ;; lf_decor_map.map_i3    =  -lf_decor_map.map_i3  
      ;; lf_decor_map.map_i_1mm =  -lf_decor_map.map_i_1mm
      ;; lf_decor_map.map_i_2mm =  -lf_decor_map.map_i_2mm
      end
      2: begin
         restore, lf_mapin_filejk
         lf_decor_map = map_jk  ; made of (HOR-VER)/2
         if hor then fact = -2 else fact = +2 ; change sign of signal and multiply by 2. Yes but only for scanning strategy with 2 directions of scans only.
                                ; we need to add the vertical and
                                ; subtract the horizontal (for a
                                ;HOR scan) (Careful: Hor-Ver is 2*map_JK !)
         lf_decor_map.map_i1    =  fact*lf_decor_map.map_i1    
         lf_decor_map.map_i2    =  fact*lf_decor_map.map_i2   
         lf_decor_map.map_i3    =  fact*lf_decor_map.map_i3  
         lf_decor_map.map_i_1mm =  fact*lf_decor_map.map_i_1mm
         lf_decor_map.map_i_2mm =  fact*lf_decor_map.map_i_2mm
      end  
      3: begin
                                ; restore the partner of the pair
         if pindex1[0] ne (-1) then $
         pair_file = dir_basename+'/iter'+strtrim(param.imcm_iter-1,2)+ $
                     '/v_'+ strtrim(param.version, 2)+'/' + $
                     inforead[ pindex1[ iscan_effective]].scan+'/results.save' else pair_file = 'NONE'
         
         if file_test( pair_file) then begin
            message, /info, 'For scan '+ scan_list[iscan_effective]
            message, /info, 'Restoring the partner map '+ pair_file
            restore, pair_file
            ; that restores param1, info1,kidpar1,grid1,header
            lf_decor_map = grid1
            if keyword_set( param.noiseup) then begin
                  ; New (more accurate) method, FXD, 28 Apr 2021
                                ; Map has been multiplied by a factor
                                ; (see nk_w8, option 5) which has to
                                ; be undone here
               parloc = param
               parloc.imcm_iter = parloc.imcm_iter-1 ; to avoid not counting nharm here:
               Np1 = nk_atmb_count_param( info1,  parloc, 1) ; 1 or 2mm
               Np2 = nk_atmb_count_param( info1,  parloc, 2) ; 1 or 2mm
               Nsub_sa = infoscan.subscan_arcsec/infoscan.median_scan_speed* $
                         !nika.f_sampling ; a median subscan in samples
               fact1 = nk_atmb_harm_filter(Nsub_sa, infoscan.subscan_arcsec/Nsub_sa, $
                                          !nika.fwhm_nom[0], (Np1-1)/2.)
               fact2 = nk_atmb_harm_filter(Nsub_sa, infoscan.subscan_arcsec/Nsub_sa, $
                                          !nika.fwhm_nom[1], (Np2-1)/2.)
               lf_decor_map.map_i1    =  fact1*lf_decor_map.map_i1    
               lf_decor_map.map_i2    =  fact2*lf_decor_map.map_i2   
               lf_decor_map.map_i3    =  fact1*lf_decor_map.map_i3  
               lf_decor_map.map_i_1mm =  fact1*lf_decor_map.map_i_1mm
               lf_decor_map.map_i_2mm =  fact2*lf_decor_map.map_i_2mm
            endif 
         endif else begin
            lf_decor_map = 0
            message, /info, 'Warning: could not find the partner map '+ pair_file
         endelse
      end
   endcase
   
                                ; Compute truncation map
;;   aux = subtract_maps  ; subtract maps is already truncated
;;   nk_truncate_filter_map, param, info, aux, truncate_map = truncate_map
   ; Apply it to the correction map NO (as the HOR maps are not truncated)
;;;;   nk_truncate_filter_map, param, info, lf_decor_map, truncate_map = truncate_map
endif else begin
   lf_decor_map = 0
endelse

;; Force the mask to the requested input (if any) (TBD for horver case)
if defined(force_mask_file) then begin
   restore, force_mask_file
   nk_default_info, info
   if defined(subtract_maps) eq 0 then begin
      extast, nkheader, astr
      nk_init_grid_2, param, info, subtract_maps, astr=astr
   endif

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
if defined( snr_iter_arr) then begin
                                ; Mechanism to alter the threshold
                                ; above which the map is subtracted
                                ; from the TOI. This threshold can go
                                ; down as the iterations progress
   param.keep_only_high_snr = $
      snr_iter_arr[ param.imcm_iter < (n_elements( snr_iter_arr)-1)]
endif

;; for logfiles
message, /info, param.source+", "+strtrim( long(param.method_num),2)+ $
         ", iter "+strtrim(long(param.imcm_iter),2)

if parity ne 0 then parity = (-1)^iscan_effective

;; Reduce scan
nk, scan_list[iscan_effective], param=param, $
    header=nkheader, grid=grid, $
    subtract_maps=subtract_maps, $
    lf_decor_map = lf_decor_map, simpar=simpar, $
    parity=parity, polar=polar, second_header=second_header

end
