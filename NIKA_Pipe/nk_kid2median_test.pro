;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_kid2median_test
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_kid2median_test, param, info, data, kidpar
; 
; PURPOSE: 
;        Regress each kid to the median mode and discards outlyers.
; 
; INPUT: 
;        - param, info, data, kidpar
; 
; OUTPUT: 
;         - kidpar.type is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - July 2019: NP
;-

function gauss_cdf, x
  return, erf(x/sqrt(2.d0))
end

pro nk_kid2median_test, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_kid2median_test, param, info, data, kidpar"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

niter = 2
for iter=0, niter-1 do begin
   nkids = n_elements(kidpar)
   slope_res = dblarr(nkids)
   std_res   = dblarr(nkids)
   for iarray=1, 3 do begin
;      won = where( kidpar.array eq iarray and kidpar.type ne 2 and kidpar.type le 9, nwon)
;      if nwon ne 0 then begin
      w1  = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         toi_med = median( data.toi[w1], dim=1)
         
;            for i=0, nwon-1 do begin
;               ikid = won[i]
         for i=0, nw1-1 do begin
            ikid = w1[i]
            fit = linfit( toi_med, data.toi[ikid])
            diff = data.toi[ikid]-(fit[0]+fit[1]*toi_med)
            slope_res[ikid] = fit[1]
            std_res[ikid] = stddev(diff)
            
            if param.debug ge 3 then begin
               nplots_per_window = 64 ; 100
               if (i mod nplots_per_window) eq 0 then begin
                  wind, 1, 1, /free, /large
                  my_multiplot, 1, 1, ntot=nplots_per_window, /rev, /full, pp, pp1, /dry
               endif
               plot, diff, /xs, /ys, position=pp1[i mod nplots_per_window,*], /noerase, col=col, $
                     xcharsize=1d-10, ycharsize=1d-10
               legendastro, [string(fit[1],form='(F5.2)'), $
                             strtrim(stddev(diff),2)], textcol=250
;;                  if (i mod nplots_per_window) eq (nplots_per_window-1) then stop
            endif
         endfor
      endif
;      endif
   endfor

   if param.debug ge 1 then begin
      wind, 1, 1, /free, /large
      my_multiplot, 3, 2, pp, pp1, /rev
   endif
   
   for iarray=1, 3 do begin 
      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1) 
      if nw1 ne 0 then begin
         slope = slope_res[w1]
         mystd = std_res[w1]
         a     = avg(slope) 
         sigma = stddev(slope) 
         a_std = avg(mystd)
         sigma_std = stddev(mystd)
         w = where( (abs(slope-a) gt 3*sigma or abs(mystd-a_std) gt 3*sigma_std), nw)
         if nw ne 0 then kidpar[w1[w]].type = 10

         if param.debug ge 2 then begin
            plot, slope, /xs, /ys, position=pp[iarray-1,0,*], /noerase, title='slope (iter '+strtrim(iter,2)+")"
            oplot, indgen(nw1), dblarr(nw1)+a, col=70 
            for ii=-3,3 do oplot, indgen(nw1), dblarr(nw1)+a+ii*sigma, line=2, col=70
            legendastro, 'Std: '+strtrim(sigma,2) 
            if nw ne 0 then begin
               oplot, [w], [slope[w]], psym=8, col=250
               legendastro, 'Nout = '+strtrim(nw,2), textcol=250, /bottom
            endif
            
            plot, mystd, /xs, /ys, position=pp[iarray-1,1,*], /noerase, title='std' 
            legendastro, 'Std: '+strtrim(sigma_std,2) 
            oplot, indgen(nw1), dblarr(nw1)+a, col=70 
            for ii=-3,3 do oplot, indgen(nw1), dblarr(nw1)+a_std + ii*sigma_std, line=2, col=70 
            if nw ne 0 then begin
               oplot, [w], [mystd[w]], psym=8, col=250
               legendastro, 'Nout = '+strtrim(nw,2), textcol=250, /bottom
            endif
         endif
      endif 
   endfor
endfor

; if param.debug ge 1 then stop

if param.cpu_time then nk_show_cpu_time, param

end
