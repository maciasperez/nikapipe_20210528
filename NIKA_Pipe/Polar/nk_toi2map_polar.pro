;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: nk_toi2map_polar
;
; CATEGORY: general, launcher
;
; CALLING SEQUENCE:
;         nk_toi2map_polar, param, info
; 
; PURPOSE: 
;        This is the main procedure of the NIKA offline analysis
;        software that reduces the timelines to maps.
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
; 
; OUTPUT: 
;        - FITS maps 
;        - Calibrated Time Ordered Data (optional)
;        - Calibration products: beam, bandpass, unit conversion
;          (optional)
;        - pdf check plots (optional)
;        - log file of the terminal (optional)
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 05/03/2014: creation (Nicolas Ponthieu & Alessia Ritacco)
;-
;=========================================================================================================

pro nk_toi2map_polar, all_scans_param, all_scans_info, data, kidpar, simpar=simpar
  
if all_scans_info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "all_scans_info.status = 1 from the beginning => exiting"
   return
endif

nscans = n_elements(all_scans_param.scan_list) ;Number of scans

;; Loop over all scans
for iscan=0, nscans - 1 do begin

   ;; Need to redefine param and info per subscan to allow e.g. info.status to
   ;; be passed correctly from routine to routine, and preserve the global all_scans_info.map_xx
   param = all_scans_param[iscan]
   info  = all_scans_info[iscan]


   ;; Get the data and KID parameters
   nk_getdata, param, info, data, kidpar
   nsn = n_elements(data)

   ;;=========================================================================
   ;; If we are running a simulation, then modify data and kidpar accordingly
   if keyword_set(simpar) then begin
      nks_data, simpar, data, kidpar
      
      ;; bypass opacity correction at this stage in simulations
      param.no_opacity_correction = 1
   endif
   ;; =========================================================================
   nk_coadd_polar, param, info, data, kidpar, map_1mm=map_1mm, $
                   map_q_1mm=map_q_1mm, map_u_1mm=map_u_1mm, $
                   map_2mm=map_2mm, map_q_2mm=map_q_2mm,$
                   map_u_2mm=map_u_2mm

;; Gather all maps per scan (not normalized yet)
   all_scans_info.map_1mm    += info.map_1mm
   all_scans_info.map_q_1mm  += info.map_q_1mm
   all_scans_info.map_u_1mm  += info.map_u_1mm
   all_scans_info.map_2mm    += info.map_2mm
   all_scans_info.map_q_2mm  += info.map_q_2mm
   all_scans_info.map_u_2mm  += info.map_u_2mm
   all_scans_info.map_w8_1mm += info.map_w8_1mm
   all_scans_info.map_w8_2mm += info.map_w8_2mm
   all_scans_info.nhits_1mm  += info.nhits_1mm
   all_scans_info.nhits_2mm  += info.nhits_2mm

endfor                          ; scan loop

;; Average maps over scans
w = where( all_scans_info.map_w8_1mm ne 0, nw)
if nw ne 0 then begin
   all_scans_info.map_1mm[w]     = all_scans_info.map_1mm[w]  /$
                                   all_scans_info.map_w8_1mm[w]
   all_scans_info.map_q_1mm[w]   = all_scans_info.map_q_1mm[w]/$
                                   all_scans_info.map_w8_1mm[w]
   all_scans_info.map_u_1mm[w]   = all_scans_info.map_u_1mm[w]/$
                                   all_scans_info.map_w8_1mm[w]
   all_scans_info.map_var_1mm[w] = 1.d0/all_scans_info.map_w8_1mm[w]
endif
w = where( all_scans_info.map_w8_2mm ne 0, nw)
if nw ne 0 then begin
   all_scans_info.map_2mm[w]     = all_scans_info.map_2mm[w]  /$
                                   all_scans_info.map_w8_2mm[w]
   all_scans_info.map_q_2mm[w]   = all_scans_info.map_q_2mm[w]/$
                                   all_scans_info.map_w8_1mm[w]
   all_scans_info.map_u_2mm[w]   = all_scans_info.map_u_2mm[w]/$
                                   all_scans_info.map_w8_1mm[w]
   all_scans_info.map_var_2mm[w] = 1.0d0/all_scans_info.map_w8_2mm[w]
endif

wind, 1, 1, /free, /xlarge
my_multiplot, 3, 3, pp, pp1
imview, all_scans_info.map_1mm,     xmap=all_scans_info.xmap, $
        ymap=all_scans_info.ymap, title='1mm total', position=pp1[0,*]
imview, all_scans_info.map_q_1mm,     xmap=all_scans_info.xmap, $
        ymap=all_scans_info.ymap, title='Q_1mm', position=pp1[1,*], /noerase
imview, all_scans_info.map_u_1mm,     xmap=all_scans_info.xmap,$
        ymap=all_scans_info.ymap, title='U_1mm', position=pp1[2,*], /noerase
imview, all_scans_info.map_2mm,     xmap=all_scans_info.xmap, $
        ymap=all_scans_info.ymap, title='2mm total', position=pp1[3,*], /noerase
imview, all_scans_info.map_q_2mm,   xmap=all_scans_info.xmap, $
        ymap=all_scans_info.ymap, title='Q_2mm', position=pp1[4,*], /noerase
imview, all_scans_info.map_u_2mm,   xmap=all_scans_info.xmap,$
        ymap=all_scans_info.ymap, title='U_2mm', position=pp1[5,*], /noerase
imview, all_scans_info.mask_source, xmap=all_scans_info.xmap, $
        ymap=all_scans_info.ymap, title='mask', position=pp1[6,*], /noerase

;;========== Save the all_scans_info as FITS
;;  nk_all_scans_info2fits, param, all_scans_info

  
end
