;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_flag_uncorr_kids
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_flag_uncorr_kids, param, info, data, kidpar
; 
; PURPOSE: 
;        Flags out kids that correlate anormally to the other ones
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Nov. 21st 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;        - Oct. 15th, 2015: NP, adapted to NIKA2
;-

pro nk_flag_uncorr_kids, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_flag_uncorr_kids, param, info, data, kidpar"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

p=0
for iarray=1, 3 do begin
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
   if nw1 ne 0 then begin

      if param.fast_uncorr eq 1 then begin
         ;; The source is ignored... faster but at your own risk
         mcorr = correlate( data.toi[w1])
      endif else begin
         mcorr = dblarr(nw1, nw1)
         for i=0, nw1-2 do begin
            ikid=w1[i]
            for j=i+1, nw1-1 do begin
               jkid=w1[j]
               w = where( data.off_source[ikid] eq 1 and $
                          data.off_source[jkid] eq 1, nw)
               if nw lt 10 then begin
                  nk_error, info, "Less than 10 good samples to correlate numdet "+$
                            strtrim(kidpar[ikid].numdet,2)+" and "+strtrim(kidpar[jkid].numdet,2)
               endif else begin
                  mcorr[i,j] = correlate( data[w].toi[ikid], data[w].toi[jkid])
                  mcorr[j,i] = mcorr[i,j] ; for convenience
               endelse
            endfor
         endfor
      endelse
      
      ;; Look for outlyers
      kid_median_corr = median( mcorr, dim=1)
      good = where( kid_median_corr ge median(kid_median_corr)-3*stddev(kid_median_corr) and $
                    kid_median_corr gt 0.d0, ngood, compl=nogood, ncompl=nnogood)

;; Added during Run16 by someone... ?
;;      wsort = sort(kid_median_corr)
;;      N_kids = n_elements(kid_median_corr)
;;      ;nogood = wsort[0:N_kids/10]
;;      ;nnogood = n_elements(nogood)
;;      nogood = where(kid_median_corr lt 0.99,nnogood)
      
      ;; Flag out if any
      if nnogood ne 0 then kidpar[w1[nogood]].type = 3

      if param.do_plot ne 0 then begin
         if p eq 0 then begin
            if param.plot_ps eq 0 then $
               wind, 1, 1, /free, /large, iconic = param.iconic
            outplot, file='kids_correlation', png=param.plot_png, ps=param.plot_ps
            my_multiplot, 3, 2, pp, pp1, /rev, xmargin=0.1, gap_x=0.1
         endif
         imview, mcorr, imrange=minmax(mcorr[where(mcorr ne 0)]), title="Array "+strtrim(iarray,2), $
                 /noerase, position=pp[iarray-1,0,*]
         plot, kid_median_corr, /ys, ytitle='Kid median correlation', position=pp[iarray-1,1,*], /noerase
         if nnogood ne 0 then oplot, [nogood], [kid_median_corr[nogood]], psym=1, col=250, thick=2
         legendastro, ['Valid kids', 'Flagged kids'], psym=[1,1], $
                      col=[!p.color,250], box=0, /bottom
         p++
      endif

   endif
endfor
outplot, /close

end
