
;+
;
; SOFTWARE:
;; NIKA pipeline / Polarization
;
; NAME: 
; nk_hwp_rm_4
;
; CATEGORY:
;
; CALLING SEQUENCE:
;     nk_hwp_rm_4, param, kidpar, data, amplitudes
; 
; PURPOSE: 
;        Estimate the HWP parasitic signal as a sum of harmonics of the
;rotation frequency and subtract it from data.toi
; 
; INPUT: 
;    - param, kidpar, data
; 
; OUTPUT: 
;    - amplitudes
;    - data.toi is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - NP
;        - changed the matrix multiplication to improve speed,
;          Feb. 2016 (NP)
;        - deal with my_interpol differently from nk_hwp_rm_2,
;          NP. Nov. 2017
;        - do not remove the edges of data anymore, NP. Jan 2019
;-

pro nk_hwp_rm_4, param, info, data, kidpar, amplitudes, plot=plot, debug=debug, $
                 hwpss=hwpss

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nkids = n_elements( kidpar)

w1     = where(kidpar.type eq 1, nw1)

;; Changed the definition of womeag to start from the first sample
;; womega = where( data.position eq min(data.position), nwomega)
;; womega = where( data.position eq data[0].position, nwomega)
;; Nov. 26th, 2017: Take data.synchros as a reference now that
;; data.position comes from an interpolation and is not strictly equal
;; from period to the next.
womega = where( abs(data.synchro-median(data.synchro)) gt 3*stddev(data.synchro), nwomega)

;; Kill the end of the scan after the last data[0].position, otherwise
;; the interpolation below will leave the toi untouched and create a
;; huge jump
;; data = temporary(data[0:womega[nwomega-1]])
;; Nov. 26th, 2017
;;data = temporary( data[womega[0]:womega[nwomega-1]])
;;womega = womega - womega[0]
nsn = n_elements(data)
t = dindgen(nsn)/!nika.f_sampling
index = lindgen(nsn)

wfit = where( index ge womega[0] and $
              index le womega[nwomega-1], nwfit)

if nwfit eq 0 then begin
   message, /info, "No sample with all kid flags = 0 to determine the hwp template"
   amplitudes = dblarr( nkids, ncoeff)
   return
endif

;; ncoeff = 4*param.polar_n_template_harmonics
;; amplitudes = dblarr( nkids, ncoeff)
;; 
;; ;; Fitting template, only on good positions
;; temp = dblarr( ncoeff, nwfit)
;; for i=0, param.polar_n_template_harmonics-1 do begin
;;    temp[ i*4,     *] =         cos( (i+1)*data[wfit].position)
;;    temp[ i*4 + 1, *] = t[wfit]*cos( (i+1)*data[wfit].position)
;;    temp[ i*4 + 2, *] =         sin( (i+1)*data[wfit].position)
;;    temp[ i*4 + 3, *] = t[wfit]*sin( (i+1)*data[wfit].position)
;; endfor
;; 
;; ;; Global template for the reconstruction
;; outtemp = dblarr( ncoeff, nsn)
;; for i=0, param.polar_n_template_harmonics-1 do begin
;;    outtemp[ i*4,     *] =   cos( (i+1)*data.position)
;;    outtemp[ i*4 + 1, *] = t*cos( (i+1)*data.position)
;;    outtemp[ i*4 + 2, *] =   sin( (i+1)*data.position)
;;    outtemp[ i*4 + 3, *] = t*sin( (i+1)*data.position)
;; endfor

ncoeff = 2*param.polar_n_template_harmonics
amplitudes = dblarr( nkids, ncoeff)

;; Fitting template, only on good positions
temp = dblarr( ncoeff, nwfit)
for i=0, param.polar_n_template_harmonics-1 do begin
   temp[ i*2,     *] = cos( (i+1)*data[wfit].position)
   temp[ i*2 + 1, *] = sin( (i+1)*data[wfit].position)
endfor

;; Global template for the reconstruction
outtemp = dblarr( ncoeff, nsn)
for i=0, param.polar_n_template_harmonics-1 do begin
   outtemp[ i*2,     *] = cos( (i+1)*data.position)
   outtemp[ i*2 + 1, *] = sin( (i+1)*data.position)
endfor

ata   = matrix_multiply( temp, temp, /btranspose)
atam1 = invert(ata)

my_interpol = dblarr(nw1, nsn)
for i=0, nwomega-2 do begin
   dx    = double(womega[i+1] - womega[i])
   dy    = data[womega[i+1]].toi[w1] - data[womega[i]].toi[w1]
   n     = womega[i+1]-womega[i]+1
   slope = (dblarr(n)+1) ## (dy/dx)
   c     = (dblarr(n)+1) ## data[womega[i]].toi[w1]
   xx    = dindgen(n)
   my_interpol[*,womega[i]:womega[i+1]] = c + slope*(xx##(dblarr(nw1)+1))
endfor

;; before womega[0] and after womega[nwomega-1], my_interpol is
;; zero anyway, so we can subtract it here everywhere for convenience
toi = data[wfit].toi[w1] - my_interpol[*,wfit]
   
;; Ditto here, the constant is computed on the correct range but
;; can be subtracted everywhere
;; a = avg( data[womega[0]:womega[nwomega-1]].toi[w1], 1)
;; data.toi[w1] -= (dblarr(nsn)+1)##a
a = avg( toi, 1)
toi -= (dblarr(nwfit)+1)##a

;; Derive amplitudes on wfit
atd        = transpose(temp) ## toi
amplitudes = atam1##atd

;; Build template on the whole sample range
hwpss    = outtemp##amplitudes

if keyword_set(plot) then begin
   wind, 1, 1, /free, /large
   my_multiplot, 1, 3, pp, pp1, /rev, xmax=0.7
   plot, data.toi[w1[0]], /xs, position=pp1[0,*]
   oplot, wfit, data[wfit].toi[w1[0]], col=150
   oplot, my_interpol[0,*], col=250, thick=3
   oplot, womega, data[womega].toi[w1[0]], psym=8, syms=0.5, col=70
   
   plot, toi[0,*], /xs, position=pp1[1,*], /noerase
   
   plot, data.toi[w1[0]]-hwpss[0,*], /xs, /ys, position=pp1[2,*], /noerase

   my_multiplot, 1, 2, pp, pp1, xmin=0.7
   plot, [0,10], [0,10], /nodata, position=pp1[0,*], /noerase
   legendastro, strtrim(amplitudes[0,*],2)
endif

;; Subtract HWPSs from the TOI's
data.toi[w1]  -= hwpss

if param.cpu_time then nk_show_cpu_time, param

end
