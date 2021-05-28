;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_tel_gain_cor
;
; CATEGORY: 
;        calibration
;
; CALLING SEQUENCE:
;         nk_tel_gain_cor, param, info, data, kidpar
; 
; PURPOSE: 
;        Corrects for the elevation dependent gain of the telescope
;        see Astron. Astrophys. Suppl. Ser. 132, 413{416 (1998).
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the general NIKA strucutre containing time ordered information
;        - kidpar: the general NIKA structure containing kid related information
; 
; OUTPUT: 
;        - data: data.toi is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 6th, 2014: creation (Nicolas Ponthieu and Remi Adam)
;        - Dec. 6th, 2017: Added NIKA2 (preliminary) curve
;-

pro nk_tel_gain_cor, param, info, data, kidpar, extent_source=extent_source, undo=undo

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_tel_gain_cor, param, info, data, kidpar, extent_source=extent_source, undo=undo"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then  message, /info, "info.status = 1 from the beginning => exiting"
   return
endif


if param.do_tel_gain_corr eq 0 then begin
   return
endif else begin
   nk_list_kids, kidpar, lambda=1, valid=w1mm, nvalid=nw1mm
   nk_list_kids, kidpar, lambda=2, valid=w2mm, nvalid=nw2mm
   elev = data.el*180/!pi

;;--------------------------------------------
   if param.do_tel_gain_corr eq 1 then begin
      ;; EMIR
      freqs_ghz = !const.c/(!nika.lambda*1e-3) * 1d-9
      
      ;; Parameters of the fitted model  
      elmax1mm = 1.567E-06 * freqs_ghz[0]^3 -1.233E-03 * freqs_ghz[0]^2 + 3.194E-01 * freqs_ghz[0] + 2.203E+01
      elmax2mm = 1.567E-06 * freqs_ghz[1]^3 -1.233E-03 * freqs_ghz[1]^2 + 3.194E-01 * freqs_ghz[1] + 2.203E+01
      
      ;; Gain model
      rms_El         = 2.5523E-02 * elev^2 - 2.5534 * elev + 1.1937E+02
      Aeff0_El       = 8.8466E-06 * elev^2 - 1.2523E-03 * elev + 6.9608E-01
      rms_Elmax1mm   = 2.5523E-02 * elmax1mm^2 - 2.5534 * elmax1mm + 1.1937E+02
      Aeff0_Elmax1mm = 8.8466E-06 * elmax1mm^2 - 1.2523E-03 * elmax1mm + 6.9608E-01
      rms_Elmax2mm   = 2.5523E-02 * elmax2mm^2 - 2.5534 * elmax2mm + 1.1937E+02
      Aeff0_Elmax2mm = 8.8466E-06 * elmax2mm^2 - 1.2523E-03 * elmax2mm + 6.9608E-01
      
      Aeff_El1mm    = Aeff0_EL * exp(-(4*!dpi*rms_el*1d-3/!nika.lambda[0])^2)
      Aeff_El2mm    = Aeff0_EL * exp(-(4*!dpi*rms_el*1d-3/!nika.lambda[1])^2)
      Aeff_Elmax1mm = Aeff0_ELmax1mm * exp(-(4*!dpi*rms_elmax1mm*1d-3/!nika.lambda[0])^2)
      Aeff_Elmax2mm = Aeff0_ELmax2mm * exp(-(4*!dpi*rms_elmax2mm*1d-3/!nika.lambda[1])^2)
      
      G1mm = Aeff_El1mm / Aeff_Elmax1mm
      G2mm = Aeff_El2mm / Aeff_Elmax2mm
      
      if keyword_set(extent_source) then begin ;correct for source extension
         theta = [0,   1,   2,   3,   4,  5,   6,   7,   8,   12, 1000]
         ;; measured by eye from Fig.3 but it is a correction of the correction so it should be OK
         L_ext = [1,0.98,0.93,0.75,0.45,0.3,0.25,0.18,0.12, 0.05, 0.0]
         L1mm_ext = interpol(L_ext, theta, extent_source/!nika.fwhm_nom[0])
         L2mm_ext = interpol(L_ext, theta, extent_source/!nika.fwhm_nom[1])
         G1mm = 1 - L1mm_ext * (1 - G1mm)
         G2mm = 1 - L2mm_ext * (1 - G2mm)
      endif
   endif

;;--------------------------------------------
   if param.do_tel_gain_corr eq 2 then begin
      ;; NIKA2 model, Dec. 6th, 2017
      G1mm = 0.68966122 + 0.012449726*elev - 0.00012494462*elev^2
      G2mm = 0.96843661 + 0.0016058897*elev -2.0426208e-05*elev^2
   endif      

   if nw1mm ne 0 then G1mm = G1mm ## (dblarr(nw1mm) + 1)
   if nw2mm ne 0 then G2mm = G2mm ## (dblarr(nw2mm) + 1)

;; Gain correction
   if keyword_set(undo) then begin ; for simulations
      if nw1mm ne 0 then data.toi[w1mm] *= G1mm
      if nw2mm ne 0 then data.toi[w2mm] *= G2mm
   endif else begin
      if nw1mm ne 0 then data.toi[w1mm] /= G1mm
      if nw2mm ne 0 then data.toi[w2mm] /= G2mm
   endelse
endelse

;; if not param.silent then begin
;;    message, /info, 'Gain-elevation correction applied at 1mm : / '+strtrim(median(G1mm), 2)
;;    message, /info, 'Gain-elevation correction applied at 2mm : / '+strtrim(median(G2mm), 2)
;;    message, /info, 'Median elevation : '+strtrim(median(elev),2)+' degrees'
;; endif


end
