
;+
;
; SOFTWARE: NIKA pipeline / Real time analysis
;
; NAME: 
; nk_discard_outlyers
;
; CATEGORY:
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Flags out kids with outlying values of peak, fwhm...
; 
; INPUT: 
;        - kidpar
;
; OUTPUT: 
;         - kidpar_out
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Oct. 11th, 2015: NP
;-
;================================================================================================

pro nk_discard_outlyers, kidpar_in, kidpar, position=position, title=title, charsize=charsize

if n_params() lt 1 then begin
   message, "calling sequence:"
   print, "tbd"
   return
endif

;; init
kidpar = kidpar_in

;; Sub selection of kids if requested
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   message, /info, "No valid kids in kidpar"
   return
endif

xra = [-1,1]*400 ; minmax( kidpar[w1].nas_x)
yra = [-1,1]*400 ; minmax( kidpar[w1].nas_y)
phi = dindgen(100)/99.*2*!dpi

kidpar.plot_flag = 0            ; init
   
if not keyword_set(fwhm_min)   then fwhm_min   = 5.
if not keyword_set(fwhm_max)   then fwhm_max   = 30.
if not keyword_set(a_peak_min) then a_peak_min = 0.
if not keyword_set(a_peak_max) then a_peak_max = max( kidpar.a_peak)
if not keyword_set(ellipt_max) then ellipt_max = max( kidpar.ellipt)
if not keyword_set(noise_max)  then noise_max  = max( kidpar.noise)
if not keyword_set(ellipt_max) then ellipt_max = 5

wtest = where( kidpar.type eq 1 and $
               kidpar.fwhm ge fwhm_min and $
               kidpar.fwhm le fwhm_max and $
               kidpar.a_peak ge a_peak_min and $
               kidpar.a_peak le a_peak_max and $
               kidpar.ellipt le ellipt_max, nwtest, compl=w_discard, ncompl=nw_discard)
      
if nw_discard ne 0 then kidpar[w_discard].plot_flag = 1
if not keyword_set(position) then begin
   wind, 1, 1, /free
   noerase = 0
endif else begin
   noerase = 1
endelse
plot, xra, yra, /iso, /nodata, xtitle='Nasmyth x', ytitle='Nasmyth y', position=position, noerase=noerase, $
      title=title, charsize=charsize
legendastro, ['All kids', 'To keep'], box=0, textcol=[0,150]
oplot, kidpar[w1].nas_x, kidpar[w1].nas_y, psym=1
oplot, kidpar[wtest].nas_x, kidpar[wtest].nas_y, psym=1, col=150
for ii=0, nw1-1 do $
   oplot, kidpar[w1[ii]].nas_x + kidpar[w1[ii]].fwhm/2*cos(phi), $
          kidpar[w1[ii]].nas_y + kidpar[w1[ii]].fwhm/2*sin(phi)
for ii=0, nwtest-1 do $
   oplot, kidpar[wtest[ii]].nas_x + kidpar[wtest[ii]].fwhm/2*cos(phi), $
          kidpar[wtest[ii]].nas_y + kidpar[wtest[ii]].fwhm/2*sin(phi), col=150

      ;; ;; derive simple statistics on non-absurd kids to flag out outlyers
      ;; med   = median( kidpar[wtest].(ifield))
      ;; sigma = stddev( kidpar[wtest].(ifield))
      ;; w = where( finite(kidpar.(ifield)) ne 1 or abs(kidpar.(ifield)-med) gt 4*sigma, nw)
      ;; if nw ne 0 then kidpar[w].plot_flag = 1

end
