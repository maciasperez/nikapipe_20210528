;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
;  nk_toi2map
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_toi2map, all_scans_param, all_scans_info, data, kidpar, simpar=simpar
; 
; PURPOSE: 
;        This is the main procedure of the NIKA offline analysis
;        software that reduces the timelines to maps.
; 
; INPUT: 
;        - param: the reduction parameter structure.
;        - info: the information structure to be filled
; 
; OUTPUT: 
;        - data: the data structure of the latest scan
;        - kidpar: the kid structure of the latest scan
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

pro nk_toi2map, param, info, data, kidpar, simpar=simpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_toi2map, param, info, data, kidpar, simpar=simpar"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

;; Get the data and KID parameters
nk_getdata, param, info, data, kidpar

;;=========================================================================
;; If we are running a simulation, then modify data and kidpar accordingly
if keyword_set(simpar) then begin
   nks_data, simpar, data, kidpar
   
   ;; bypass opacity correction at this stage in simulations
   param.no_opacity_correction = 1
endif
;; =========================================================================

;; Process data and computes the contribution of this scan to the final maps
;; By default, info.mask_source is modified at each iteration in
;; nk_data_coadd (otherwise it makes no sense to iterate in the current
;; decorrelation methods).
;; For each scan, info.mask_source is initialized when we do info =
;; info[iscan] at the beginning of this loop.
;; 
;; To use a common predefined mask for all scans, then pass it to
;; info from the beginning and set param.niter=1
nk_data_coadd, param, info, data, kidpar, map_1mm=map_1mm, map_2mm=map_2mm

;; Average maps over scans
w = where( info.map_w8_1mm ne 0, nw)
if nw ne 0 then begin
   info.map_1mm[w]     = map_1mm
   info.map_var_1mm[w] = 1.d0/info.map_w8_1mm[w]
endif
w = where( info.map_w8_2mm ne 0, nw)
if nw ne 0 then begin
   info.map_2mm[w]     = map_2mm
   info.map_var_2mm[w] = 1.0d0/info.map_w8_2mm[w]
endif

wind, 1, 1, /free, /xlarge, iconic = param.iconic
my_multiplot, 2, 1, pp, pp1
imview, info.map_1mm,     xmap=info.xmap, ymap=info.ymap, title='1mm total', position=pp1[0,*]
imview, info.map_2mm,     xmap=info.xmap, ymap=info.ymap, title='2mm total', position=pp1[1,*], /noerase

  
end
