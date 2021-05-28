
;+
;
; SOFTWARE:
;; NIKA pipeline / Polarization
;
; NAME: 
; nk_get_hwpss_sub
;
; CATEGORY:
;
; CALLING SEQUENCE:
;  nk_get_hwpss_sub, param, info, toi_in, synchro, position, kidpar, hwpss
;
; PURPOSE: 
;        Estimate the HWP parasitic signal as a sum of harmonics of the
;rotation frequency and subtract it from data.toi
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Feb. 17th, 2019: NP (from nk_hwp_rm_4)

pro nk_get_hwpss_sub, param, info, toi_in, synchro, position, kidpar, hwpss, $
                      plot=plot, off_source=off_source, amplitudes=amplitudes
;-

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_get_hwpss_sub'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nkids  = n_elements( kidpar)
nsn    = n_elements(toi_in[0,*])
t      = dindgen(nsn)/!nika.f_sampling
index  = lindgen(nsn)

;; Restrict the fit to an integer number of HWP full rotations
womega = where( abs(synchro-median(synchro)) gt 3*stddev(synchro), nwomega)

wfit = where( index ge womega[0] and index le womega[nwomega-1], nwfit)

if param.hwp_harmonics_only eq 1 then begin
   ncoeff = 2*param.polar_n_template_harmonics
   ;; Fitting template, only on good positions
   temp = dblarr( ncoeff, nwfit)
   for i=0, param.polar_n_template_harmonics-1 do begin
      temp[ i*2,   *] = cos( (i+1)*position[wfit])
      temp[ i*2+1, *] = sin( (i+1)*position[wfit])
   endfor
   ;; Global template for the reconstruction
   outtemp = dblarr( ncoeff, nsn)
   for i=0, param.polar_n_template_harmonics-1 do begin
      outtemp[ i*2,     *] = cos( (i+1)*position)
      outtemp[ i*2 + 1, *] = sin( (i+1)*position)
   endfor
endif else begin
   ncoeff = 4*param.polar_n_template_harmonics
   temp = dblarr( ncoeff, nwfit)
   ;; Fitting template, only on good positions
   for i=0, param.polar_n_template_harmonics-1 do begin
      temp[ i*4,     *] =         cos( (i+1)*position[wfit])
      temp[ i*4 + 1, *] = t[wfit]*cos( (i+1)*position[wfit])
      temp[ i*4 + 2, *] =         sin( (i+1)*position[wfit])
      temp[ i*4 + 3, *] = t[wfit]*sin( (i+1)*position[wfit])
   endfor
   ;; Global template for the reconstruction
   outtemp = dblarr( ncoeff, nsn)
   for i=0, param.polar_n_template_harmonics-1 do begin
      outtemp[ i*4,     *] =   cos( (i+1)*position)
      outtemp[ i*4 + 1, *] = t*cos( (i+1)*position)
      outtemp[ i*4 + 2, *] =   sin( (i+1)*position)
      outtemp[ i*4 + 3, *] = t*sin( (i+1)*position)
   endfor
endelse

amplitudes = dblarr( nkids, ncoeff)

ata   = matrix_multiply( temp, temp, /btranspose)
atam1 = invert(ata)

my_interpol = dblarr(nkids, nsn)
for i=0, nwomega-2 do begin
   dx    = double(womega[i+1] - womega[i])
   dy    = toi_in[*,womega[i+1]] - toi_in[*,womega[i]]
   n     = womega[i+1]-womega[i]+1
   slope = (dblarr(n)+1) ## (dy/dx)
   c     = (dblarr(n)+1) ## toi_in[*,womega[i]]
   xx    = dindgen(n)
   my_interpol[*,womega[i]:womega[i+1]] = c + slope*(xx##(dblarr(nkids)+1))
endfor

;; before womega[0] and after womega[nwomega-1], my_interpol is
;; zero anyway, so we can subtract it on all wfit for convenience
toi4fit = toi_in[*,wfit] - my_interpol[*,wfit]

;; Subtract also a constant to be closer to periodic boundary
;; conditions for the harmonics fit and because there's no
;; guarantee that womega fall on the average. More likely on an
;; offset.
;;
;; Mask out the source to avoid ringing induced by the subtraction of
;; the average level
;; a = avg( toi4fit, 1)
tt = toi4fit
w = where( off_source[*,wfit] eq 0, nw)
if nw ne 0 then tt[w] = !values.d_nan
a = avg( tt, 1, /nan)
delvarx, tt
toi4fit -= (dblarr(nwfit)+1)##a

wind, 1, 1, /free, /large
my_multiplot, 1, 3, pp, pp1, /rev
ikid = 0
plot, wfit, toi_in[ikid,wfit], /xs, yra=array2range( toi_in[ikid,wfit]), /ys, position=pp1[0,*]
oplot, my_interpol[ikid,wfit], col=250
plot, toi4fit[ikid,*], /xs, position=pp1[1,*], /noerase
w = where( off_source[ikid,wfit] eq 1, nw)
if nw ne 0 then oplot, [w], toi4fit[ikid,w], psym=1, col=70
oplot, [-1,1]*1d10, [1,1]*avg(toi4fit[ikid,*]), col=200
oplot, [-1,1]*1d10, [1,1]*median(toi4fit[ikid,*]), col=250
legendastro, ['avg: '+strtrim(avg(toi4fit[ikid,*]),2), $
              'median: '+strtrim(median(toi4fit[ikid,*]),2)], textcol=[200,250]
plot, toi4fit[ikid,*], /xs, position=pp1[2,*], /noerase
oplot, [-1,1]*1d10, [1,1]*avg(toi4fit[ikid,*]), col=200
legendastro, 'avg(toi4fit): '+strtrim(avg(toi4fit[ikid,*]),2), textcol=200
stop

;; Derive amplitudes on wfit
atd        = transpose(temp) ## toi4fit
amplitudes = atam1##atd

;; Build template on the whole sample range
hwpss = outtemp##amplitudes

if keyword_set(plot) then begin
   wind, 1, 1, /free, /large
   my_multiplot, 2, 3, pp, pp1, /rev, xmax=0.7

   yra = array2range(toi_in[0,*], margin=0.4)
   plot, toi_in[0,*], /xs, xra=xra, yra=yra, /ys, position=pp[0,0,*]
   oplot, wfit, toi_in[0,wfit], col=150
   oplot, my_interpol[0,*], col=250, thick=3
   oplot, womega, toi_in[0,womega], psym=-8, syms=0.5, col=70
   legendastro, ['TOI_in', 'TOI_in (wfit)', 'my_interpol', 'womega'], $
                textcol=[!p.color, 150, 250, 70]
   
   plot, toi4fit[0,*], /xs, position=pp[0,1,*], /noerase, xra=xra
   legendastro, 'TOI4fit = toi_in - my_interpol (wfit)'
   
   plot, toi_in[0,*]-hwpss[0,*], /xs, /ys, position=pp[0,2,*], /noerase, xra=xra
   legendastro, 'TOI_in[0,*] - hwpss[0,*]'

   plot, toi_in[0,*], /xs, position=pp[1,0,*], xra=xra, yra=yra, /ys, /noerase
   oplot, toi_in[0,*]-hwpss[0,*], col=250

   power_spec, toi_in[0,*]-my_baseline(toi_in[0,*],base=0.1), !nika.f_sampling, pw, freq
   y = toi_in[0,*]-hwpss[0,*]-a[0]
   power_spec, y-my_baseline(y,base=0.1), !nika.f_sampling, pw1
   plot_oo, freq, pw, /xs, position=pp[1,1,*], /noerase
   oplot, freq, pw1, col=250
   stop
;;    my_multiplot, 1, 2, pp, pp1, xmin=0.7
;;    plot, [0,10], [0,10], /nodata, position=pp1[0,*], /noerase, xs=4, ys=4
;;    legendastro, ['Amplitudes:', strtrim(reform(amplitudes[0,*]),2)]
endif

if param.cpu_time then nk_show_cpu_time, param

end
