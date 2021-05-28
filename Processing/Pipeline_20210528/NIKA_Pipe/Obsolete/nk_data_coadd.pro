;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_data_coadd
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;         nk_data_coadd, param, info, data, kidpar, map_1mm=map_1mm, map_2mm=map_2mm
; 
; PURPOSE: 
;        This is the main procedure of the NIKA offline analysis
;        software that reduces the timelines to maps. It works on a single scan.
;        info.map_1mm and info.map_2mm can be passed to nk_average_maps to
;        produce the combined map of several scans.
; 
; INPUT: 
;        - param: the reduction parameters array of structures (one per scan)
;        - info: the array of information structure to be filled (one
;          per scan)
; 
; OUTPUT: 
;        - info.mapXX are modified
;        - map_1mm, map_2mm: maps of this scan
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 05/03/2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-
;=========================================================================================================

pro nk_data_coadd, param, info, data, kidpar, map_1mm=map_1mm, map_2mm=map_2mm
  
if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif


;; Calibrate the data 
nk_calibration, param, info, data, kidpar

;; Deglitch the data
nk_deglitch, param, info, data, kidpar

;; Remove jumps from the data
;;nk_jump, param, info, data, kidpar

;; Flag KIDs
;; nk_flag_bad_kid, param, info, data, kidpar

;; Produce calibrated data in fits files
;; nk_toi2fits, param, info, data, kidpar

;; ;; Loop over iterations
;; data_copy = data
;; info_copy = info
;; for iiter=0, param.niter - 1 do begin
;;    
;;    ;; Restore un-decorrelated data at each iteration for now
;;    data = data_copy
;; 
;;    ;; Reset maps at each iteration
;;    info.map_1mm     = 0.d0
;;    info.nhits_1mm   = 0.d0
;;    info.map_w8_1mm  = 0.d0
;;    info.map_var_1mm = 0.d0
;;    info.map_2mm     = 0.d0
;;    info.nhits_2mm   = 0.d0
;;    info.map_w8_2mm  = 0.d0
;;    info.map_var_2mm = 0.d0

;; Define which parts of the maps must be masked for common mode estimation
;; info.mask_source must be 1 outside the source, 0 on source
nk_mask_source, param, info, data, kidpar

;;----------------------------------------------------------------------------------------------
;; Treat the noise (decorrelation and filtering)
if param.do_plot ne 0 then begin
   if not param.plot_ps then wind, 1, 1, /free, /large, iconic = param.iconic
   my_multiplot, 2, 2, pp, pp1, /rev
   outplot, file=param.output_dir+"/toi_decor", png=param.plot_png, ps=param.plot_ps
   for lambda=1, 2 do begin
      nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
      if nw1 ne 0 then begin
         ikid = w1[0]
         plot, data.toi[ikid], /xs, position=pp[lambda-1,0,*], /noerase, thick=2
         legendastro, ["!7k!3="+strtrim(lambda,2)+"mm", $
                       "Raw data", $
                       "ikid="+strtrim(ikid,2)], box=0
      endif
   endfor
endif

nk_decor, param, info, data, kidpar

if param.do_plot ne 0 then begin
   for lambda=1, 2 do begin
      nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
      if nw1 ne 0 then begin
         ikid = w1[0]
         plot, data.toi[ikid], /xs, position=pp[lambda-1,1,*], /noerase, thick=2
         legendastro, ["!7k!3="+strtrim(lambda,2)+"mm", $
                       "After decorrelation", $
                       "ikid="+strtrim(ikid,2)], box=0
      endif
   endfor
   outplot, /close
endif
;;----------------------------------------------------------------------------------------------

;; Re-deglitch the data to improve after atmosphere subtraction
nk_deglitch, param, info, data, kidpar

;; Zero level
;; nk_0level, param, info, data, kidpar

;; Compute inverse variance weights for TOIs
nk_w8, param, info, data, kidpar

;; Project the data onto maps
nk_projection, param, info, data, kidpar

;; Show maps if requested
if info.status ne 1 then begin

   nk_coadd2maps, param, info, info.coadd_1mm, info.map_w8_1mm, map_1mm, map_var_1mm
   nk_coadd2maps, param, info, info.coadd_2mm, info.map_w8_2mm, map_2mm, map_var_2mm
   
   if param.do_plot ne 0 then begin
      if not param.plot_ps then wind, 1, 1, /free, /xlarge, iconic = param.iconic
      my_multiplot, 3, 1, pp, pp1
      outplot, file=param.output_dir+"/maps", png=param.plot_png, ps=param.plot_ps
      imview, map_1mm,          xmap=info.xmap, ymap=info.ymap, title = param.scan+' 1mm',  position=pp1[0,*], nsigma=4
      imview, map_2mm,          xmap=info.xmap, ymap=info.ymap, title = param.scan+' 2mm',  position=pp1[1,*], nsigma=4, /noerase
      imview, info.mask_source, xmap=info.xmap, ymap=info.ymap, title = param.scan+' mask', position=pp1[2,*], nsigma=4, /noerase
      outplot, /close
   endif
endif

;; ;; Update the output info
;; ;; Do NOT update info_copy.mask_source to preserve its input value that may be
;; ;; common to other scans
;; info_copy.status        = info.status
;; info_copy.error_message = info.error_message
;; 
;; info_copy.map_1mm      += info.map_1mm
;; info_copy.nhits_1mm    += info.nhits_1mm
;; info_copy.map_w8_1mm   += info.map_w8_1mm
;; info_copy.map_var_1mm  += info.map_var_1mm
;; info_copy.map_2mm      += info.map_2mm
;; info_copy.nhits_2mm    += info.nhits_2mm
;; info_copy.map_w8_2mm   += info.map_w8_2mm
;; info_copy.map_var_2mm  += info.map_var_2mm
;; 
;; info = info_copy

  
end
