

pro nk_kidpar_outlyers, kidpar, wtest, w_discard, array=array, plot_flag_zero=plot_flag_zero, $
                        fwhm_min=fwhm_min, fwhm_max=fwhm_max, $
                        a_peak_min=a_peak_min, a_peak_max=a_peak_max, $
                        ellipt_max=ellipt_max, $
                        noise_max=noise_max, keep_neg = keep_neg, $
                        nas_x_min = nas_x_min, nas_x_max = nas_x_max, nas_y_min = nas_y_min, $
                        nas_y_max = nas_y_max, az_min = az_min, az_max = az_max, $
                        el_min = el_min, el_max = el_max, snr_min=snr_min
                          
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   message, /info, "No valid kid."
   stop
endif

if not keyword_set(fwhm_min)   then fwhm_min   = 5.
if not keyword_set(fwhm_max)   then fwhm_max   = 40.
if not keyword_set(a_peak_min) then a_peak_min = 0.
if not keyword_set(a_peak_max) then a_peak_max = 1e5
if not keyword_set(ellipt_max) then ellipt_max = 5 ; 2
if not keyword_set(noise_max)  then noise_max  = 100
if not keyword_set(nas_x_min)  then nas_x_min  = -1000
if not keyword_set(nas_x_max)  then nas_x_max  =  1000
if not keyword_set(nas_y_min)  then nas_y_min  = -1000
if not keyword_set(nas_y_max)  then nas_y_max  =  1000
if not keyword_set(az_min)     then az_min  = -1000
if not keyword_set(az_max)     then az_max  =  1000
if not keyword_set(el_min)     then el_min  = -1000
if not keyword_set(el_max)     then el_max  =  1000
if not keyword_set(snr_min)    then snr_min = 3

tags = tag_names(kidpar)

stop

;; keep negative fluxes and allow for negative calibration if
;; requested to fix a temporary but on the acquisition of array 3
;; Nov. 2nd, 2015
if keyword_set(keep_neg) then a_peak_min = min([kidpar.a_peak, kidpar.a_peak_nasmyth])

;; wtest = where( kidpar.type eq 1 and $
;;                kidpar.fwhm ge fwhm_min and kidpar.fwhm le fwhm_max and $
;;                kidpar.a_peak ge a_peak_min and kidpar.a_peak le a_peak_max and $
;;                kidpar.a_peak_nasmyth ge a_peak_min and kidpar.a_peak_nasmyth le a_peak_max and $
;;                kidpar.ellipt le ellipt_max and $
;;                kidpar.noise le noise_max and $
;;                kidpar.nas_x ge nas_x_min and $
;;                kidpar.nas_x le nas_x_max and $
;;                kidpar.nas_y ge nas_y_min and $
;;                kidpar.nas_y le nas_y_max and $
;;                kidpar.x_peak_azel ge az_min and kidpar.x_peak_azel le az_max and $
;;                kidpar.y_peak_azel ge el_min and kidpar.y_peak_azel le el_max and $
;;                kidpar.peak_snr_azel ge snr_min and kidpar.peak_snr_nasmyth ge snr_min, $
;;                nwtest, compl=w_discard, ncompl=nw_discard)

cmd = "wtest = where( kidpar.type eq 1 and "
if keyword_set(array)          then cmd += " kidpar.array eq array and "
if keyword_set(plot_flag_zero) then cmd += " kidpar.plot_flag eq 0 and "
cmd += "kidpar.fwhm ge fwhm_min and kidpar.fwhm le fwhm_max and "+$
       "kidpar.a_peak ge a_peak_min and kidpar.a_peak le a_peak_max and "+$
       "kidpar.a_peak_nasmyth ge a_peak_min and kidpar.a_peak_nasmyth le a_peak_max and "+$
       "kidpar.ellipt le ellipt_max and "+$
       "kidpar.noise le noise_max and "+$
       "kidpar.nas_x ge nas_x_min and "+$
       "kidpar.nas_x le nas_x_max and "+$
       "kidpar.nas_y ge nas_y_min and "+$
       "kidpar.nas_y le nas_y_max and "+$
       "kidpar.x_peak_azel ge az_min and kidpar.x_peak_azel le az_max and "+$
       "kidpar.y_peak_azel ge el_min and kidpar.y_peak_azel le el_max and "+$
       "kidpar.peak_snr_azel ge snr_min and kidpar.peak_snr_nasmyth ge snr_min, "+$
       "nwtest, compl=w_discard, ncompl=nw_discard)"

junk = execute(cmd)


end
