
pro nk_decor_trigo, param, info, kidpar, toi, flag, off_source, elevation, $
                    toi_out, out_temp, dra, ddec


if param.nharm_multi_sinfit le 0 then begin
   nk_error, info, "param.nharm_multi_sinfit must be > 0 in nk_decor_trigo"
   return
endif

nsn = n_elements( toi[0,*])

nkids = n_elements(kidpar)
toi_out  = dblarr(nkids,nsn)
out_temp = dblarr(nkids,nsn)
subband = kidpar.numdet/80 ; integer division on purpose
for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if nw1 ne 0 then begin

      ;; allocate templates
      ;; add 1 template for the slope (needed like the baseline
      ;; subtraction before any fft)
      templates = dblarr(2*param.nharm_multi_sinfit+1, nsn)
      x = dindgen(nsn)
      for p=0, param.nharm_multi_sinfit-1 do begin
         ;; x goes from 0 to (nsn-1), so yes, divide 2*pi by (nsn-1) to
         ;; explore the full period
         ;;
         ;; start at harmonics 1 because the const is provided by regress.
         templates[nt+nsubbands + p*2,   *] = cos(2.d0*!dpi/(nsn-1)*x*(p+1))
         templates[nt+nsubbands + p*2+1, *] = sin(2.d0*!dpi/(nsn-1)*x*(p+1))
      endfor
      templates[2*param.nharm_multi_sinfit,*] = dindgen(nsn)/(nsn-1)
       
;;       if param.interactive ge 2 then begin
;;          wind, 1, 1, /free, /large
;;          my_multiplot, 1, 1, ntot=n_elements(templates[*,0]), pp, pp1, /rev, /full
;;          for i=0, n_elements(templates[*,0])-1 do begin
;;             plot, templates[i,*], position=pp1[i,*], /noerase
;;          endfor
;;          stop
;;       endif

      ;; regress out atm and all subbands of the array at the same time
      junk = toi[w1,*]
      nk_subtract_templates_3, param, info, junk, flag[w1,*], off_source[w1,*], $
                               kidpar[w1], templates, out_temp1, out_coeffs=out_coeffs

;;       if param.interactive ge 2 then begin
;;          wind, 1, 1, /free, xpos=100
;;          my_multiplot, /reset
;;          my_multiplot, 2, 2, pp, pp1, /rev
;;          i=0
;;          ikid=w1[i]
;;          plot, toi[ikid,*], /xs
;;          oplot, out_temp1[i,*], col=250
;;          stop
;;       endif
;; 
      ;; Subtract only common modes and trigo for now
      if param.interactive ge 2 then begin
         wind, 1, 1, /free, /large
         my_multiplot, 1, 2, pp, pp1, /rev
         i=0
         ikid=w1[i]
         cmfit = reform((templates##out_coeffs[*,1:*])[ikid,*])
         plot, toi[ikid,*], /xs, position=pp1[0,*]
         oplot, cmfit, col=70
      endif
      toi_out[w1,*]  = toi[w1,*] - templates##out_coeffs[*,1:*]
      out_temp[w1,*] = templates##out_coeffs[*,1:*]
      
      ;; Fit zero level and drift
      index = dindgen(nsn)
      for i=0, nw1-1 do begin
         ikid = w1[i]
         w = where( sqrt( dra[ikid,*]^2 + ddec[ikid,*]^2) ge param.radius_zero_level_mask, nw)
         if nw gt 3 then begin
            fit = linfit( index[w], toi_out[ikid,w])
            
            if param.interactive ge 2 then begin
               index = dindgen(nsn)
               print, fit
               plot, index, toi_out[ikid,*], position=pp1[1,*], /noerase
               oplot, index[w], toi_out[ikid,w], psym=1, col=250
               oplot, index, fit[0] + fit[1]*index, col=150
               stop
            endif
            
            toi_out[ ikid,*] -= (fit[0] + fit[1]*index)
            out_temp[ikid,*] +=  fit[0] + fit[1]*index
         endif else begin
            ;; discard from projection for now
            kidpar[ikid].type = 3
         endelse
      endfor
   endif

endfor

end
