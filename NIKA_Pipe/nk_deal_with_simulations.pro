
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_deal_with_simulations
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_deal_with_simulations, param, info, data, kidpar, grid, simpar
; 
; PURPOSE: 
;        Runs all signal and noise specific operations in nk_scan_preproc
; 
; INPUT: 
;        - param, info, data, kidpar, grid, simpar
; 
; OUTPUT: 
;        - data
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Feb. 2019: Extracted from nk_scan_preproc to be cleaner, NP.

pro nk_deal_with_simulations, param, info, data, kidpar, grid, simpar, astr=astr
;-

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_deal_with_simulations'
   return
endif

if param.log then nk_log, info, "dealing with simulations"


;; Default init
noise_toi = 0.d0

nsn      = n_elements(data)
nkids    = n_elements(kidpar)

;; if noise has already been generated, restore it, else generate it
noise_file = !nika.preproc_dir+"/noise_"+param.scan+".save" 
if param.noise_preproc eq 1 and file_test(noise_file) then begin
   message, /info, "Restoring "+strtrim(noise_file,2)
   restore, noise_file
endif else begin
   
   if simpar.quick_noise_sim eq 1 then begin
      simpar.reset = 1
      noise_toi = reform( randomn( seed, nkids*nsn), nkids, nsn)
   endif else begin

      ;; compute the noise common mode if requested before replacing the
      ;; data by the simulated correlated and white noise
      ;; Do it before nks_data that may replace the TOI's by
      ;; pure simulated timelines.
      if simpar.add_one_corr_and_white_noise eq 1 then begin
         ;;stop
         w1 = where( kidpar.type eq 1, nw1)
;;         nk_get_cm_sub_3, param, info, data.toi[w1], $
;;                          data.off_source[w1], kidpar[w1], $
;;                          common_mode
;         stop
         ;; make sure for here that there is no hole in the common mode
         param1 = param
         param1.interpol_common_mode = 1
         off_source = data.off_source[w1]*0 + 1
         nk_get_cm_sub_2, param1, info, data.toi[w1], data.flag[w1], $
                          off_source, kidpar[w1], $
                          common_mode

         power_spec, common_mode-my_baseline(common_mode,base=0.01), !nika.f_sampling, pw, freq
         w = where( freq lt 1 and freq ne 0)
         fit = linfit( alog(freq[w]), alog(pw[w]))
         pure_beta = -fit[1]
         nks_noise_1d, nsn, !nika.f_sampling, noise, pure_beta=pure_beta
         scale = (max(common_mode)-min(common_mode))/(max(noise)-min(noise))
         noise *= scale


;;           wind, 1, 1, /free, /large
;;           my_multiplot, 2, 1, pp, pp1
;;           plot_oo, freq, pw, /xs, /ys, position=pp1[1,*]
;;           oplot, freq, exp(fit[0])*freq^fit[1], col=250
;;           legendastro, 'beta = '+strtrim(fit[1],2), textcol=250
;;           power_spec, noise, !nika.f_sampling, pw_noise
;;           oplot, freq, pw_noise, col=70
;;  
;;           plot, common_mode, /xs, /ys, position=pp1[0,*], /noerase
;;           oplot, noise, col=70
;;           stop
          
         common_mode = noise

         nsn      = n_elements(data)
         my_white_noise = reform( randomn( seed, nw1*nsn), nw1, nsn)
         ;; my_common_mode_and_noise = dblarr(nw1,nsn)
         noise_toi = dblarr(nkids, nsn)
         for i=0, nw1-1 do begin
            ikid = w1[i]
            fit = linfit( common_mode, data.toi[ikid])
            power_spec, data.toi[ikid]-my_baseline(data.toi[ikid],base_frac=0.01), !nika.f_sampling, pw, freq
            w = where( freq gt 5.)
            pw_wn = avg( pw[ where(freq gt 5.)])
            sigma2 = pw_wn^2*!nika.f_sampling/2.
            ;; my_common_mode_and_noise[i,*] = fit[0] + fit[1]*common_mode + my_white_noise[i,*]*sqrt(sigma2)
            noise_toi[ikid,*] = fit[0] + fit[1]*common_mode + my_white_noise[i,*]*sqrt(sigma2)
         endfor

         if param.dmm_simu eq 1 then begin
            noise_toi = randomn( seed, nkids, nsn) * 0.01
         endif else begin
            for i=0, nw1-1 do begin
               ikid = w1[i]
;;               fit = linfit( common_mode, data.toi[ikid])
               fit = randomu( seed, 2)*0.2 + 1
               power_spec, data.toi[ikid]-my_baseline(data.toi[ikid],base_frac=0.01), !nika.f_sampling, pw, freq
               w = where( freq gt 5.)
               pw_wn = avg( pw[ where(freq gt 5.)])
               sigma2 = pw_wn^2*!nika.f_sampling/2.

               if param.dmm_simu eq 2 then begin
                  sigma2 = 1d-4
                  fit[0] = 0
                  fit[1] = 1
               endif

               if param.dmm_simu eq 3 then begin
                  sigma2 = 1d-4
               endif

               ;; my_common_mode_and_noise[i,*] = fit[0] + fit[1]*common_mode + my_white_noise[i,*]*sqrt(sigma2)
               noise_toi[ikid,*] = fit[0] + fit[1]*common_mode + my_white_noise[i,*]*sqrt(sigma2)
            endfor
         endelse
      endif

      ;; Instrumental and additional white noise
      ;; @ {\tt nks_add_uncorr_noise} adds noise that is uncorrelated
      ;; between detectors (if requested in simpar)
      nks_gen_uncorr_noise, nsn, param, simpar, info,  kidpar, noise_toi1
      if defined(noise_toi1) then noise_toi += noise_toi1

;      help, simpar.quick_noise_sim, simpar.add_one_corr_and_white_noise, $
;            simpar.white_noise, simpar.kid_net, simpar.kid_fknee, $
;            simpar.kid_alpha_noise, noise_toi, noise_toi1

      if param.noise_preproc eq 1 then begin
         save, noise_toi, file=noise_file
         message, /info, "just saved noise_toi in "+strtrim(noise_file,2)
      endif
   endelse
endelse

;; Scientific data
;; @ {\tt nks_data} first simulates (or adds) scientific data timelines
nks_data, param, simpar, info, data, kidpar, astr=astr

;; Add noise (maybe zero) to data tois
data.toi += noise_toi

;; Simulate the effect a wrong offset in Nasmyth coordinates
if simpar.nas_x_offset ne 0 then kidpar.nas_x += simpar.nas_x_offset
if simpar.nas_y_offset ne 0 then kidpar.nas_y += simpar.nas_y_offset

if simpar.nsample_ptg_shift ne 0 then begin
   ;; Simulate the effect of fixed time delay between the telescope
   ;; and NIKA
   nsn = n_elements(data)
   tags = ["ofs_az", "ofs_el", "el", "paral", "lst", "mjd"]
   for i=0, n_elements(tags)-1 do begin
      w = where( strupcase(tag_names(data)) eq strupcase(tags[i]), nw)
      if nw eq 0 then begin
         message, /info, "There's no "+tags[i]+" tag in the data structure"
         info.status = 1
         return
      endif else begin
         data.(w) = shift( data.(w), simpar.nsample_ptg_shift)
      endelse
   endfor
   nk_add_flag, data, 8, wsample=[lindgen(simpar.nsample_ptg_shift+1), $
                                  lindgen(simpar.nsample_ptg_shift+1)-simpar.nsample_ptg_shift-1+nsn]
endif

if param.cpu_time then nk_show_cpu_time, param

end
