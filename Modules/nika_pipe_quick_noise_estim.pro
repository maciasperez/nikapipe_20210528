
;; Rough estimate of the noise above 1Hz for monitoring along a campaign.
;; simple on purpose to account for both white noise and noise lines

pro nika_pipe_quick_noise_estim, param, data, kidpar, mjy=mjy

;; Force to an even number of samples to speed up FFT
nsn = n_elements(data)
if (nsn mod 2) ne 0 then nsn = nsn-1

p = 0 ; counter
for ikid=0, n_elements(kidpar)-1 do begin
   if kidpar[ikid].type eq 1 then begin

      toi = data[0:nsn-1].rf_didq[ikid]
      toi = toi - my_baseline(toi)
      power_spec, toi, !nika.f_sampling, pw, freq

      if p eq 0 then begin
         wf = where( freq ge 1.d0, nwf)
         if nwf eq 0 then begin
            message, /info, "No frequency larger than 1Hz in this timelines ?!"
            stop
         endif
         p  = 1
      endif

      kidpar[ikid].noise = avg(pw[wf]) ; in data units/sqrt(Hz)
   endif
endfor

;; data are calibrated in Jy, set /mJy to do the conversion
if keyword_set(mjy) then kidpar.noise = kidpar.noise * 1000

;; Write kidpars in the scan output directory
scan_name = strtrim(param.day,2)+"s"+strtrim(param.scan_num,2)
w = where( kidpar.array eq 1, nw)
if nw ne 0 then nika_write_kidpar, kidpar[w], param.output_dir+"/kidpar_"+scan_name+"_1mm.fits", /silent
w = where( kidpar.array eq 2, nw)
if nw ne 0 then nika_write_kidpar, kidpar[w], param.output_dir+"/kidpar_"+scan_name+"_2mm.fits", /silent

end
