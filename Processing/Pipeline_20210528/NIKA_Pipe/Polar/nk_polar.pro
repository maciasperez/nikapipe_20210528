;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: nk_polar
;
; CATEGORY: general, launcher
;
; CALLING SEQUENCE:
;         nk_polar, scan_list, param, info
; 
; PURPOSE: 
;        This is the main procedure of the NIKA offline analysis
;        software. It launches the reduction of each scan of scan_list
;        and averages the output maps into the final one using inverse
;        variance noise weighting.
; 
; INPUT: 
;        - scan_list : e.g. ['20140221s0024', '20140221s0025', '20140221s0026']
;        - param: the pipeline parameters
;        - info: must be passed in input to allow for mask_source
; 
; OUTPUT: 
;        - info
; 
; KEYWORDS:
;        - filing: if set, we run the pipeline in a mode where it processes only
;          files for which a companion with prefix UP_ exists.
;        - polar: set to make the intensity I and polarization Q,U maps
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 17/06/2014: creation (Nicolas Ponthieu, Rémi Adam, Alessia Ritacco). The NIKA offline reduction (mainly
;        nika_pipe_launch.pro and nika_anapipe_launch.pro) are put
;        together in this software
;-

pro nk_polar, scan_list_in, output_maps, kidpar, param=param, info=info, filing=filing,$
              polar=polar

if n_params() lt 1 then begin
   message, info, "Calling sequence:"
   print, "nk_polar, scan_list_in, param, output_maps, filing=filing"
   return
endif


;; Check if the scans are fine and returns the good scans
nk_check_scan_list, scan_list_in, scan_list, day, scan_num,$
                    antenna_file, raw_file, FORCE=FORCE
nscans = n_elements(scan_list)
if nscans eq 0 then begin
   nk_error, info, "No valid scans were selected"
   return
endif

if not keyword_set(param) then nk_default_param,   param
if keyword_set(polar) then begin
   if not keyword_set(info)  then nk_init_info, param, info, /polar
endif else begin
   if not keyword_set(info)  then nk_init_info, param, info
endelse
;;---------------------------------------------------------------------------------
;; Main loop
for iscan=0, nscans-1 do begin

   ;; Check if the file has already been processed or not.
   ;; Wether if was actually processed with the same parameters will be checked
   ;; in nk_average_maps.
   process_file = 1             ; init
   if keyword_set(filing) then nk_check_filing, scan_list[iscan], process_file

   if process_file ne 0 then begin
      ;; Update param for the current scan
      nk_update_scan_param, scan_list[iscan], param, info
      
      ;; Get the data and KID parameters
      nk_getdata, param, info, data, kidpar ;, /plot
      
      ;; test
      ;; power_spec, data.toi[0]  - my_baseline(data.toi[0]),!nika.f_sampling, pw,  freq
      ;; wind, 1, 1, /free, /large
      ;; !p.multi=0
      ;; plot_oo, freq, pw, /xs
      
      ;; ===============
      ;; If we are running a simulation, then modify data and kidpar accordingly
      if keyword_set(simpar) then begin
         nks_data, simpar, data, kidpar
         
         ;; bypass opacity correction at this stage in simulations
         param.no_opacity_correction = 1
      endif
      ;; ===============
      
      ;; Process data and computes the contribution of this scan to the
      ;; final maps
      
      if keyword_set(polar) then begin
         ;; if keyword_set(pix1) then begin
            check_nk_data_coadd_polar, param, info, data, kidpar,$
                                       map_1mm=map_1mm, map_q_1mm=map_q_1mm,$
                                       map_u_1mm=map_u_1mm,map_2mm=map_2mm, $
                                       map_q_2mm=map_q_2mm, map_u_2mm=map_u_2mm,$
                                       /add_simu,/plot 
            
            ;; Save results of this scan for future use
            nk_save_scan_results_polar, param, info, data, kidpar,$
                                        map_1mm=map_1mm, map_q_1mm=map_q_1mm, $
                                        map_u_1mm=map_u_1mm, map_2mm=map_2mm, $
                                        map_q_2mm=map_q_2mm, map_u_2mm=map_u_2mm,$
                                        filing=filing
         ;; endif
         ;; if keyword_set(pix2) then begin
         ;;    check_nk_data_coadd_polar, param, info, data, kidpar,$
         ;;                               map_1mm=map_1mm, map_q_1mm=map_q_1mm,$
         ;;                               map_u_1mm=map_u_1mm,map_2mm=map_2mm, $
         ;;                               map_q_2mm=map_q_2mm, map_u_2mm=map_u_2mm,$
         ;;                               /add_simu,/plot,/pix2
            
         ;;    ;; Save results of this scan for future use      
         ;;    nk_save_scan_results_polar, param, info, data, kidpar,$
         ;;                                map_1mm=map_1mm, map_q_1mm=map_q_1mm, $
         ;;                                map_u_1mm=map_u_1mm, map_2mm=map_2mm, $
         ;;                                map_q_2mm=map_q_2mm, map_u_2mm=map_u_2mm,$
         ;;                                filing=filing
         ;; endif
         
      endif else begin
         nk_data_coadd, param, info, data, kidpar, map_1mm=map_1mm,$
                        map_2mm=map_2mm
         
         ;; Save results of this scan for future use
         nk_save_scan_results, param, info, data, kidpar,$
                               map_1mm=map_1mm, map_2mm=map_2mm, $
                               filing=filing
      endelse
   endif
endfor

end
