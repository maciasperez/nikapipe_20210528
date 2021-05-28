;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_ks_test
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_ks_test, param, info, data, kidpar
; 
; PURPOSE: 
;        Performs a Kolmogorov-Smirnov test on each KID compared to
;        the median mode to check if the kid is actually valid or not
; 
; INPUT: 
;        - param, info, data, kidpar
; 
; OUTPUT: 
;        - kidpar.ksone_d and kidpar.ksone_prob are computed
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - March 2019: NP
;-

function gauss_cdf, x
  return, erf(x/sqrt(2.d0))
end

pro nk_ks_test, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_ks_test, param, info, data, kidpar"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; if param.debug ge 1 then begin
;;    save, param, info, data, kidpar, file='data.save'
;;    message, /info, "remove this temporary data.save"
;;    stop
;; endif
niter = 3
for iter=0, niter-1 do begin
   nkids = n_elements(kidpar)
   slope_res = dblarr(nkids)
   std_res   = dblarr(nkids)
   for iarray=1, 3 do begin
      won = where( kidpar.array eq iarray and kidpar.type ne 2 and kidpar.type le 9, nwon)
      if nwon ne 0 then begin
         w1  = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
         if nw1 ne 0 then begin
            ;; Derive a median common mode from all the valid KIDs of
            ;; the array
            toi_med = median( data.toi[w1], dim=1)
            
            for i=0, nwon-1 do begin
               if param.debug ge 1 then begin
                  nplots_per_window = 64 ; 100
;;                   if (i mod nplots_per_window) eq 0 then begin
;;                      wind, 1, 1, /free, /large
;;                      my_multiplot, 1, 1, ntot=nplots_per_window, /rev, /full, pp, pp1, /dry
;;                   endif
               endif
               ikid = won[i]
               ;; Compare the current TOI to the median common mode
               fit = linfit( toi_med, data.toi[ikid])
               y = data.toi[ikid] - (fit[0] + fit[1]*toi_med)
               diff = y ; keep a copy
               slope_res[ikid] = fit[1]
               std_res[ikid] = stddev(y)
               ;; Center and normalization
               y -= avg(y)
               y /= stddev(y)
               ksone,  abs(y), 'gauss_cdf', D, prob ;, /PLOT
               kidpar[ikid].ksone_d    = d
               kidpar[ikid].ksone_prob = prob
               
;;                if param.debug ge 1 then begin
;;                   col = 0
;;                   if kidpar[ikid].ksone_d*100 ge 8 then col=250
;;                   if kidpar[ikid].type ne 1 then col=200
;; ;               plot, toi_med, data.toi[ikid], /xs, /ys, position=pp1[i mod nplots_per_window,*], /noerase, col=col, $
;; ;                     xcharsize=1d-10, ycharsize=1d-10
;; ;               oplot, minmax(toi_med), fit[0] + fit[1]*minmax(toi_med), col=70
;;                   
;;                   fit = linfit( toi_med, data.toi[ikid])
               
;;                   plot, diff, /xs, /ys, position=pp1[i mod nplots_per_window,*], /noerase, col=col, $
;;                         xcharsize=1d-10, ycharsize=1d-10
;;                   legendastro, [string(fit[1],form='(F5.2)'), $
;;                                 strtrim(stddev(diff),2)], textcol=250
;; ;               legendastro, ["A"+strtrim(iarray,2)+"/"+strtrim(ikid,2), $
;; ;                             "d: "+string(kidpar[ikid].ksone_d*100.,form='(F5.1)'), $
;; ;                             "p: "+string(kidpar[ikid].ksone_prob*100,form='(F5.1)')], textcol=250, chars=0.6, $
;; ;                            /bottom, /right
;; ;               stop
;;                endif
               
;            if (i mod nplots_per_window) eq (nplots_per_window-1) then stop
            endfor
         endif
      endif
   endfor

   wind, 1, 1, /free, /large
   my_multiplot, 3, 2, pp, pp1, /rev
   for iarray=1, 3 do begin 
      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1) 
      if nw1 ne 0 then begin
         slope = slope_res[w1]
         mystd = std_res[w1]
         plot, slope, /xs, /ys, position=pp[iarray-1,0,*], /noerase, title='slope (iter '+strtrim(iter,2)+")"
         a = avg(slope) 
         sigma = stddev(slope) 
         oplot, indgen(nw1), dblarr(nw1)+a, col=70 
         for ii=-3,3 do oplot, indgen(nw1), dblarr(nw1)+a+ii*sigma, line=2, col=70
         legendastro, ['A'+strtrim(iarray,2), 'Std: '+strtrim(sigma,2)]

         a_std = avg(mystd)
         sigma_std = stddev(mystd)
;         w = where( (abs(slope-a) gt 3*sigma, nw)

;         if nw ne 0 then kidpar[w1[w]].type = 10
;         if nw ne 0 then begin
;            oplot, [w], [slope[w]], psym=8, col=250, syms=0.5
;            legendastro, 'Nout = '+strtrim(nw,2), textcol=250, /bottom
;         endif
        
         plot, mystd, /xs, /ys, position=pp[iarray-1,1,*], /noerase, title='std' 
         legendastro, ['A'+strtrim(iarray,2), 'Std: '+strtrim(sigma_std,2)]
         oplot, indgen(nw1), dblarr(nw1)+a, col=70 
         for ii=-3,3 do oplot, indgen(nw1), dblarr(nw1)+a_std + ii*sigma_std, line=2, col=70 
         w = where( abs(mystd-a_std) gt 3*sigma_std, nw)
         if nw ne 0 then begin
            oplot, [w], [mystd[w]], psym=8, col=250, syms=0.5
            legendastro, 'Nout = '+strtrim(nw,2), textcol=250, /bottom
         endif
      endif 
   endfor
;   stop
endfor


;; if param.debug ge 1 then stop

;; w = where( kidpar.ksone_d gt 0.08 and kidpar.type eq 1, nw)
;; if nw ne 0 then begin
;;    message, /info, "Rejecting "+strtrim(nw,2)+" KIDs based on KS test"
;;    kidpar[w].type = 11 ; 3
;; endif

if param.cpu_time then nk_show_cpu_time, param

end
