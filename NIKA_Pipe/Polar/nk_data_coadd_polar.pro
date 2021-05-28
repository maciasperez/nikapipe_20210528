;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: nk_data_coadd_polar
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;         nk_data_coadd_polar, param, info, data, kidpar,
;         map_1mm=map_1mm, map_q_1mm=map_q_1mm, map_u_1mm=map_u_1mm,
;         map_2mm=map_2mm, map_q_2mm=map_q_2mm, map_u_2mm=map_u_2mm
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
;        - map_1mm, map_q_1mm, map_u_1mm, map_2mm, map_q_2mm,
;          map_u_2mm : maps of this scan
; 
; KEYWORDS: plot
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 18/06/2014: creation (Nicolas Ponthieu & Alessia Ritacco- ritacco@lpsc.in2p3.fr)
;-
;=========================================================================================================

pro nk_data_coadd_polar, param, info, data, kidpar, map_1mm=map_1mm,$
                         map_q_1mm=map_q_1mm, map_u_1mm=map_u_1mm, $
                         map_2mm=map_2mm, map_q_2mm=map_q_2mm,$
                         map_u_2mm=map_u_2mm, plot=plot
                  
  
if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

;; Check if we are in "total power" or "polarization" mode
nk_get_hwp_angle, param, data, kidpar
synchro_med = median( data.c_synchro)
polar = 0 ; default
if max( abs(data.c_synchro - median( data.c_synchro))) gt 1e5 then polar = 1

data_copy = data
nsn   = n_elements(data)
nkids = n_elements(kidpar)

;; Ensure that data has a convenient number for FFTs

tol = 0.10 ; percent of data ok to discard
primes = [2,3,5,7,11,13]
sn_max = 0
i=0

while (sn_max lt (nsn-1)) and ( (nsn-sn_max)/float(nsn) gt tol) and (i le (n_elements(primes)-1)) do begin
   p = long(alog( nsn-sn_max)/alog( primes[i]))
   print, "p=", p
   sn_max = sn_max + long(primes[i])^p
   i +=1
endwhile

data = data[0:sn_max-1]
nsn                 = n_elements(data)
nsubscans           =  max(data.subscan)-min(data.subscan)+1


;;========== Subtract low frequencies before fiting out the
;;template (it should improve)

low_freq = data.toi*0.d0        ; init
freqhigh = 1.d0
np_bandpass, dblarr(nsn), !nika.f_sampling, freqhigh=freqhigh, filter=filter
for i=0, nkids-1 do begin
   if kidpar[i].type eq 1 then begin
      np_bandpass, data.toi[i], !nika.f_sampling, s_out, filter=filter
      low_freq[i,*]    = s_out
      data.toi[i] -= s_out
   endif
endfor

;; Determine HWP rotation speed
nk_get_hwp_rot_freq, data, rot_freq_hz
param.polar_nu_rot_hwp = rot_freq_hz

;; Subtract HWP template
nk_hwp_rm, param, kidpar, data, amplitudes


;; Restore low frequencies
data.toi += low_freq
delvarx, low_freq               ; save memory


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
   if not param.plot_ps then wind, 1, 1, /free, /large
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

;; Treat the noise (decorrelation and filtering)

;; Decorrelation on Q,U data
nk_decor_polar, param, info, data, kidpar, data_q=data_q, data_u=data_u

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
nk_deglitch, param, info, data_q, kidpar
nk_deglitch, param, info, data_u, kidpar

;; Zero level
;; nk_0level, param, info, data, kidpar

;; Compute inverse variance weights for TOIs
nk_w8, param, info, data, kidpar
nk_w8, param, info, data_q, kidpar
nk_w8, param, info, data_u, kidpar

;;========= Obtain the maps I,Q,U

nk_polar_maps, param, info, data, data_q, data_u, kidpar, /nasmyth

;; Show maps if requested
if info.status ne 1 then begin

   nk_coadd2maps, param, info, info.coadd_1mm,$
                  info.map_w8_1mm, map_1mm, $
                  map_var_1mm   ;I(1mm)
   nk_coadd2maps, param, info, info.coadd_q_1mm,$
                  info.map_w8_1mm, map_q_1mm,$
                  map_var_1mm   ;Q
   nk_coadd2maps, param, info, info.coadd_u_1mm,$
                  info.map_w8_1mm, map_u_1mm,$
                  map_var_1mm   ;U
   nk_coadd2maps, param, info, info.coadd_2mm,  $
                  info.map_w8_2mm, map_2mm, $
                  map_var_2mm   ;I(2mm)
   nk_coadd2maps, param, info, info.coadd_q_2mm,$
                  info.map_w8_2mm, map_q_2mm,$
                  map_var_2mm   ;Q
   nk_coadd2maps, param, info, info.coadd_u_2mm,$
                  info.map_w8_2mm, map_u_2mm, $
                  map_var_2mm   ;U

if keyword_set(plot) then begin
   wind, 1, 1, /free, /large
   my_multiplot, 3, 3, pp, pp1
   imview, map_1mm,          xmap=info.xmap, ymap=info.ymap,$
           title = '1mm',    position=pp1[0,*]
   imview, map_q_1mm,        xmap=info.xmap, ymap=info.ymap,$
           title = 'Q_1mm',  position=pp1[1,*], /noerase
   imview, map_u_1mm,        xmap=info.xmap, ymap=info.ymap,$
           title = 'U_1mm',  position=pp1[2,*], /noerase
   imview, map_2mm,          xmap=info.xmap, ymap=info.ymap,$
           title = '2mm',    position=pp1[3,*], /noerase
   imview, map_q_2mm,        xmap=info.xmap, ymap=info.ymap,$
           title = 'Q_2mm',  position=pp1[4,*], /noerase
   imview, map_u_2mm,        xmap=info.xmap, ymap=info.ymap,$
           title = 'U_2mm',  position=pp1[5,*], /noerase
   imview, info.mask_source, xmap=info.xmap, ymap=info.ymap,$
           title = 'mask',   position=pp1[6,*], /noerase
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

  stop
end
