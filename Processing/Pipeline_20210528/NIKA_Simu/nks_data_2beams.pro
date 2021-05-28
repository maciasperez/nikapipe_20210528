;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME: nks_data_2beams
;
; CATEGORY: general,launcher
;
; CALLING SEQUENCE:
;         nks_data_2beams, simpar, data, kidpar
; 
; PURPOSE: 
;        Produces the simulated data structure to be processed by the analysis pipeline
; 
; INPUT: 
;        - simparam: the simulation parameter structure
;        - info: the data info structure
;        - data: the original data taken from a real observation scan or
;          produced by another extra simulation routine from scratch.
;        - kidpar: the original kid structure from a real observation scan or
;          produced by another extra simulation routine from scratch.
; 
; OUTPUT: 
;        - data
;        - kidpar
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Sep 15th, 2014: creation (Alessia Ritacco, Nicolas Ponthieu & Remi Adam - ritacco@lpsc.in2p3.fr)
;-

pro nks_data_2beams, param, simpar, info, data, kidpar, map_struct

;;========== Calling sequence
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nks_data_2beams, simpar, data, kidpar"
   return
endif
  
; init
;; nks_init, simpar
if simpar.reset ne 0 then data.toi = 0.d0

if simpar.uniform_fwhm eq 1 then begin
   for lambda=1, 2 do begin
      w = where( kidpar.array eq lambda, nw)
      if lambda eq 1 then fwhm = simpar.fwhm_1mm else fwhm = simpar.fwhm_2mm
      if nw ne 0 then begin
         kidpar[w].fwhm    = fwhm
         kidpar[w].sigma_x = fwhm*!fwhm2sigma
         kidpar[w].sigma_y = fwhm*!fwhm2sigma
      endif
   endfor
endif


;; Build timelines from the input map
nks_map2toi, param, simpar, info, data, kidpar
;power_spec, data.toi[0], !nika.f_sampling, pw_raw, freq

nk_toi2map_2beams, param, info, data, kidpar, map_struct
;; Add point sources directly to the timelines
nks_add_source, param, simpar, info, data, kidpar

;; Undo the telescope gain correction
nk_tel_gain_cor, param, info, data, kidpar, extent_source=extent_source, /undo
;power_spec, data.toi[0], !nika.f_sampling, pw2

;; Add 1/f+white noise (uncorrelated from one kid to another)
nks_add_uncorr_noise, param, simpar, info, data, kidpar
;power_spec, data.toi[0], !nika.f_sampling, pw3

;; wind, 1, 1, /free
;; plot_oo, freq, pw_raw
;; oplot,   freq, pw2, col=70
;; oplot,   freq, pw3, col=250
;; stop

;;     ;;========== Add glitches in the timelines
;;     nks_add_glitch, param, data, kidpar
;;
;;     ;;========== Add pulse tube lines in the timelines
;;     nks_add_pulsetube, param, data, kidpar
;;
;;     ;;========== Add the atmospheric noise in the timelines
;;     nks_add_atmo, param, data, kidpar
;;
;;     ;;========== Add the electronic noise in the timelines
;;     nks_add_elec, param, data, kidpar
;;     
;;     ;;========== Save the data as FITS files
;;     nks_save_data
;;     
;;     ;;========== Provide some info the the user
;;     message, /info, 'Data computed for the scan '+strtrim(iscan+1,2)+'/'+strtrim(nscans,2)
;;     
;;  endfor

;;--------------------------------------------------------------------------------------------------
;; Sanity check on the simulated TOI:
w1 = where( kidpar.type eq 1, nw1)
for i=0, nw1-1 do begin
   ikid = w1[i]
   if total( finite(data.toi[ikid]))/n_elements(data) lt 1 then begin
      message, /info, "There are NaN values in the simulated TOI (ikid = "+strtrim(ikid,2)
      stop
   endif
endfor

  
end

