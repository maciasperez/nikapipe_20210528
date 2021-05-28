
;; Produce an ascii file with the main characteristics of the matrix as defined
;; with Martino, Alessandro, Alain and Andrea

pro ktn_kidpar2summary, day, kidpar, allkids_file, matrix_file

;;common ktn_common

nkids  = n_elements(kidpar)

;; Matrix summary
;; fields = ["TotalPixel", "GoodPixels", "DoublePixels", "EllipticPixels", $
;;           "MedianPeakAmplitude", "scatterPeakAmplitude", "MedianPixNoiseFromTrace", $
;;           "scatterPixNoiseFromTrace", "MedianPlanetSignal", "scatterPlanetSignal", $
;;           "MedianPixNoiseFromMap", "scatterPixNoiseFromMap", "medianFWHMx", $
;;           "scatterFWHMx", "medianFWHMy", "scatterFWHMy", "medianFWHMtot", $
;;           "scatterFWHMtot", "medianEllipticiyt", "scatterEllipticity"]

fields = ["TotalPixel", "OFFpixels", "GoodPixels", "DoublePixels", $ ; "EllipticPixels", $
          "MedianPeakAmplitude", "scatterPeakAmplitude", $ ;"MedianPixNoiseFromTrace", $
          "MedianPixNoiseFromTrace1HzRaw", "MedianPixNoiseFromTrace1HzDecorr", $
          "MedianPixNoiseFromTrace2HzRaw", "MedianPixNoiseFromTrace2HzDecorr", $
          "MedianPixNoiseFromTrace10HzRaw", "MedianPixNoiseFromTrace10HzDecorr", $
          "scatterPixNoiseFromTrace", "MedianPlanetSignal", "scatterPlanetSignal", $
          ;"MedianPixNoiseFromMap", "scatterPixNoiseFromMap", $
          "medianFWHMx", $
          "scatterFWHMx", "medianFWHMy", "scatterFWHMy", "medianFWHMtot", $
          "scatterFWHMtot", "medianEllipticiyt", "scatterEllipticity"]


;;w1 = where( kidpar.type eq 1, nw1); good kids
w1 = where( kidpar.plot_flag eq 0, nw1) ; keep only valid kids AFTER selection, not only those that are "on"


;; Martino's flag definition
;; 1*(PixelIsGood) + 2*(PixelIsDouble) + 4*(PixelHighlyElliptical) +
;; 8*(PixelHasHighNoise)
ellipt_med      = median( kidpar[w1].ellipt)
noise_med_10hz  = median( kidpar[w1].noise_source_interp_and_decorr_10Hz)

wdouble = where( kidpar.plot_flag eq 2, nwdouble)
flag_valid  = long(kidpar.type eq 1)
flag_double = long(kidpar.plot_flag eq 2)
flag_ellipt = long( abs(kidpar.ellipt-ellipt_med) gt 3*stddev( kidpar[w1].ellipt))
flag_noise  = long( (kidpar.noise_source_interp_and_decorr_10hz-noise_med_10hz) gt 3*stddev(kidpar[w1].noise_source_interp_and_decorr_10hz))

flag = flag_valid + 2*flag_double + 4*flag_ellipt + 8*flag_noise

;;---------------------
get_lun, u
openw,  u, matrix_file
printf, u, "#"+strtrim(day,2)
printf, u, "Run XXX"
printf, u, "Mask ? matrix name ?"
printf, u, "#"
s = "#NONs, NOffs, MedianPeakAmpl, PeakAmplScatter, MedianNoise, NoiseScatter, "
s += "NoiseRawSource1Hz, NoiseSourceDecorr1Hz, NoiseRawSource2Hz, NoiseSourceDecorr2Hz, "
s += "NoiseRawSource10Hz, NoiseSourceDecorr10Hz, MedianCalib, CalibScatter, MedianFWHMx, MedianFWHMy, "
s += "MedianFWHM, FWHMScatter, MedianEllipticity, EllipticityScatter"
printf, u, s
w  = where( kidpar.type ne 0, nw) ; ON pixels
woff = where( kidpar.type eq 2, nwoff) ; OFF pixels
s = strtrim( nw1,2)+", "
s += strtrim( nwoff,2)+", "
s += strtrim( nwdouble,2)+", "
s += strtrim( median( kidpar[w1].a_peak), 2)+", " ; median peak amplitude
s += strtrim( stddev( kidpar[w1].a_peak), 2)+", " ; scatter peak amplitude
s += strtrim( median( kidpar[w1].noise),  2)+", " ; median noise from trace
s += strtrim( median( kidpar[w1].noise_raw_source_interp_1Hz),2)+", "
s += strtrim( median( kidpar[w1].noise_source_interp_and_decorr_1Hz),2)+", "
s += strtrim( median( kidpar[w1].noise_raw_source_interp_2hz),2)+", "
s += strtrim( median( kidpar[w1].noise_source_interp_and_decorr_2hz),2)+", "
s += strtrim( median( kidpar[w1].noise_raw_source_interp_10hz),2)+", "
s += strtrim( noise_med_10hz, 2)+", "
s += strtrim( median( kidpar[w1].calib),  2)+", " ; median planet calib
s += strtrim( stddev( kidpar[w1].calib),  2)+", " ; scatter on planet calib
s += strtrim( median( kidpar[w1].fwhm_x), 2)+", "
s += strtrim( median( kidpar[w1].fwhm_y), 2)+", "
s += strtrim( median( kidpar[w1].fwhm),   2)+", "
s += strtrim( stddev( kidpar[w1].fwhm),   2)+", "
s += strtrim( ellipt_med, 2)+", "
s += strtrim( stddev( kidpar[w1].ellipt), 2)
printf, u, s
close, u
free_lun, u

;; ;; Original list by Martino
;; fields = ["Name", "ToneFrequency(Hz)", "Flag", "PlanetSignal(Normalized)", $
;;           "NoiseFromMap(mJy/beam/sqrt(s)", "PeakAmplitude(Hz)", "NoiseFromTraceAbove4Hz(Hz/sqrt(Hz))", $
;;           "NoiseFromTraceAround1Hz(Hz/sqrt(Hz))", "NoiseFromTraceAround2Hz(Hz/sqrt(Hz))", "NoiseFromTraceAround10Hz(Hz/sqrt(Hz))", $
;;           "FWHMx(arcsec or mm)", "FWHMy(arcsec or mm)", "FWHMtot(arcsec or mm)", "Ellipticity", $
;;           "XcoordOnWafer", "YcoordOnWafer", "NasmythX", "NasmythY"]

;; Noise from map does not seem to me important, and noise from trace should do
;; TBC
fields = ["Name", "ToneFrequency(Hz)", "Flag", "PlanetSignal(Normalized)", $
          "PeakAmplitude(Hz)", "NoiseFromTraceAbove4HzDecorr(Hz/sqrt(Hz))", $
          "NoiseFromTrace1HzRaw(Hz/sqrt(Hz))", "NoiseFromTrace1HzDecorr(Hz/sqrt(Hz))", $
          "NoiseFromTrace2HzRaw(Hz/sqrt(Hz))", "NoiseFromTrace2HzDecorr(Hz/sqrt(Hz))", $
          "NoiseFromTrace10HzRaw(Hz/sqrt(Hz))", "NoiseFromTrace10HzDecorr(Hz/sqrt(Hz))", $
          "FWHMx(arcsec or mm)", "FWHMy(arcsec or mm)", "FWHMtot(arcsec or mm)", "Ellipticity", $
          "XcoordOnWafer", "YcoordOnWafer", "NasmythX", "NasmythY"]
nfields = n_elements(fields)


;; Summarize kid properties
get_lun, u
openw, u, allkids_file
printf, u, "#"+strtrim(day,2)
printf, u, "Run XXX"
printf, u, "Mask ? matrix name ?"
printf, u, "#"
printf, u, "#"
for ikid=0, nkids-1 do begin

   ;; Fields description on the first line
   if ikid eq 0 then begin
      s = fields[0]
      for i=1, n_elements(fields)-2 do s += ", "+strtrim(fields[i],2)
      s += ", "+strtrim(fields[nfields-1],2)
      printf, u, "#"+s
   endif


   ;; Kid parameters
   s  = strtrim(kidpar[ikid].name,2)+", "
   s += strtrim(kidpar[ikid].f_tone,2)+", " ; ftone
   s += strtrim( flag[ikid],2)+", "         ; Martino's definition
   s += strtrim(kidpar[ikid].calib,2)+", "  ; planet amplitude
   ;;s += strtrim(kidpar[ikid].noise,2)+", "  ; noise from trance Hz.Hz^(-1/2)
   s += strtrim(kidpar[ikid].noise_raw_source_interp_1Hz,2)+", "         ; 
   s += strtrim(kidpar[ikid].noise_source_interp_and_decorr_1Hz,2)+", " ; 
   s += strtrim(kidpar[ikid].noise_raw_source_interp_2hz,2)+", "         ; 
   s += strtrim(kidpar[ikid].noise_source_interp_and_decorr_2hz,2)+", " ; 
   s += strtrim(kidpar[ikid].noise_raw_source_interp_10Hz,2)+", "        ; 
   s += strtrim(kidpar[ikid].noise_source_interp_and_decorr_10Hz,2)+", " ; 
   s += strtrim(kidpar[ikid].fwhm_x,2)+", "
   s += strtrim(kidpar[ikid].fwhm_y,2)+", "
   s += strtrim(kidpar[ikid].fwhm,2)+", "
   s += strtrim(kidpar[ikid].ellipt,2)+", "
   s += strtrim(0,2)+", " ; Xcoordwafer
   s += strtrim(0,2)+", " ; ycoordwafer
   s += strtrim(kidpar[ikid].nas_x,2)+", "
   s += strtrim(kidpar[ikid].nas_y,2)

   printf, u, s
endfor
close, u
free_lun, u



end
