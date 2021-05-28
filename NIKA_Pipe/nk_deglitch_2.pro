;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_deglitch_2
;
; CATEGORY: 1D processing
;
; CALLING SEQUENCE:
;         nk_deglitch_2, param, info, data, kidpar
; 
; PURPOSE: 
;        Detect, flags and interpolate cosmic ray induced glitches
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
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
;        - April 8th, 2014: creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr)
;        - Feb. 18th, 2016: NP improved version to avoid the slow loop on
;          timelines.
;-
;===========================================================================================================

pro nk_deglitch_2, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_deglitch_2, param, info, data, kidpar"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

nsn   = n_elements(data)
nkids = n_elements( kidpar)
ind   = dindgen( nsn)

;; init
atam1 = dblarr(2,2)
atd   = dblarr(2)
nglitch = 1

w1 = where( kidpar.type eq 1, nw1)

dtoi  = data.toi[w1]-shift(data.toi[w1],0,1)
d2toi = dtoi - shift( dtoi,0,1)
d2toi[*,0:1] = 0.d0
sigma_d2toi = nk_stddev(d2toi[*,2:*], dim=2)

;; Look at chunks of data
x1 = 0
while x1 le (nsn-1) do begin
   x2 = (x1 + param.glitch_width-1) < (nsn-1)
   if x2 eq (nsn-1) then x1 = (x2-param.glitch_width+1)>0

   n = x2-x1+1

   sigma_const = (dblarr(n)+1) ## sigma_d2toi
   y_diff      = abs( d2toi[*,x1:x2]/sigma_const)
   w = where( abs(y_diff) gt param.glitch_nsigma, nw)   
   if nw ne 0 then begin
      ;; flag out
      ;; extracted from nk_add_flag to avoid loop on kids
      myflag = data[x1:x2].flag[w1]*0.d0
      myflag[w] = 1
      powerOfTwo = 1
      deja_flag = where((LONG(data[x1:x2].flag[w1]) AND powerOfTwo) EQ powerOfTwo, ndeja_flag, comp=pas_flag, ncomp=npas_flag)
      ;; Apply the flag only where it has never been applied
      if npas_flag ne 0 then data[x1:x2].flag[w1] += myflag

      wx = where( avg( myflag, 0) ne 0, nwx)
      if (n-nwx) lt 2 then begin
         message, /info, "Not enough valid samples to fit a baseline"
         stop
      endif
      w8 = dblarr(n) + 1.d0
      w8[wx] = 0.d0
      
      x = dindgen(n)
      
      ;; fit baselines for all kids in a single pass
      xt    = total(w8*x)
      xt2   = total(w8*x^2)
      
      atam1 = 1.d0/((n-nwx)*xt2-xt^2) * [[xt2, -xt], [-xt, n-nwx]]
      
      atd0 = total(     ( w8## (dblarr(nw1)+1)) * data[x1:x2].toi[w1], 2)
      atd1 = transpose( ( w8## (dblarr(nw1)+1)) * data[x1:x2].toi[w1])##x
      
      a0 = atam1[0,0]*atd0 + atam1[1,0]*atd1
      a1 = atam1[0,1]*atd0 + atam1[1,1]*atd1
      
      const = (dblarr(n)+1) ## a0
      xx    = x ## (dblarr(nw1)+1)
      slope = (dblarr(n)+1) ## a1
      baseline = const + slope*xx
      
;;       if x1 ge 2000 then begin
;;          print, "x1: ", x1
;;          wind, 1, 1, /free
;;          plot, data[x1:x2].toi[w1[820]], /xs
;;          oplot, baseline[820,*], col=250
;;          stop
;;       endif
      
      ;; Interpolate (hard to it in one pass, try to replace by the
      ;; baseline value)
      junk = data[x1:x2].toi[w1]
      junk[w] = baseline[w]
      data[x1:x2].toi[w1] = temporary(junk)
   endif
   x1 = x2+1
endwhile

;; 
;; 
;; wflag = where( output_flag ne 0, nwflag)
;; if nwflag ne 0 then begin
;; 
;;    if nwflag gt 1 then begin
;;       ;; Keep only glitches that have no immediate neighbour to preserve planets
;;       for i=1, nwflag-1 do begin ; small loop
;;          if (wflag[i]-wflag[i-1]) eq 1 then begin
;;             output_flag[wflag[i  ]] = 0
;;             output_flag[wflag[i-1]] = 0
;;          endif
;;       endfor
;;    endif
;; 
;;    ;; Interpolate only glitches, not all flagged values
;;    ;; Rely on non-flagged values for the interpolation (flag contains glitch flags too)
;;    wgood = where( flag eq 0, nwgood)
;;    if nwgood ne 0 then begin
;;       data_out = interpol( data_in[wgood], ind[wgood], ind)
;;    endif else begin
;;       message, /info, "No good samples for interpolation ?!"
;;       stop
;;    endelse
;; endif else begin
;;    data_out = data_in
;; endelse


;; end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Recombine into TOI (PF, RF) if needed
if param.glitch_iq eq 1 then begin 
   case strupcase(param.math) of
      
      "RF":nk_iq2rf_didq, param, data, kidpar
      
      "PF": begin
         if !nika.pf_ndeg gt 0 and !nika.freqnorm1 gt 0. and n_elements(data.i) gt 1 then $
            nika_conviq2pf, data, kidpar, dapf, !nika.pf_ndeg, [!nika.freqnorm1, !nika.freqnorm2, !nika.freqnorm3]
         data.toi = dapf
      end
   endcase

;;    ;; Now we don't need I, Q, dI, dQ anymore
;;    rm_fields = ['I', 'Q', 'DI', 'DQ']
;;    nk_shrink_data, param, info, data, kidpar, rm_fields=rm_fields
endif
  
if param.cpu_time then nk_show_cpu_time, param, "nk_deglitch_2"

end
