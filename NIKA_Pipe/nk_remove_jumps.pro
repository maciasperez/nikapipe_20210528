;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_remove_jumps
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_remove_jumps, param, info, data, kidpar
; 
; PURPOSE: 
;         Some jumps are seen in Run5 data (e.g. 20121124s216). This is a first
;         order correction of these jumps.
;
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data.flag is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Sept, 1st, 2014: NP just started
;        - Jan. 2016: NP, retry
;-

pro nk_remove_jumps, param, info, data, kidpar, flag_only=flag_only

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)


w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "No valid kids"
   return
endif

nsn       = n_elements(data)
n_pts_avg = round(!nika.f_sampling/2) ; average over half a second
nsigma    = 5
nsmooth   = 3
itermax   = 6

for i=0, nw1-1 do begin
   ikid = w1[i]

   ;;dtoi = data.toi[ikid]-shift(data.toi[ikid],1)
   ;;dtoi[0] = 0                  ; due to shift's wrap around
   ;;dtoi = data.toi[ikid] - smooth( data.toi[ikid], nsmooth)
   toism = smooth( data.toi[ikid], nsmooth)
   dtoi  = toism - shift(toism,1)
   dtoi[0] = 0 ; correct for shift's wrap around
   d2toi = dtoi-shift(dtoi,1)
   d2toi[0] = 0
   ;w = where( abs(dtoi) ge nsigma*stddev(dtoi), nw)
   w2 = where( abs(dtoi) ge nsigma*stddev(dtoi) and abs(d2toi) ge nsigma*stddev(d2toi), nw2)
   w = w2
   nw = nw2
   iter = 1

   if nw ne 0 then begin
      if keyword_set(flag_only) then begin
         nk_add_flag, data, 20, wsample=w, wkid=ikid
      endif else begin
         
         while iter le itermax and nw ne 0 do begin
;      print, "ikid, iter, nw: ", ikid, iter, nw
            nk_add_flag, data, 20, wsample=w, wkid=ikid
            flag = data.toi*0.
            flag[w] = 1
            
            ;; simple for now, we'll look more into the details of DC
            ;; offsets when we do see real jumps
            toi_out = data.toi[ikid]
            ;; for j=0, nw-1 do begin
            ;;    i1 = (w[j]-1-n_pts_avg+1)>0
            ;;    i2 = (w[j]+n_pts_avg-1)<(nsn-1)
            ;;    toi_out[w[j]:*] -= avg(toi_out[w[j]:i2])-avg(toi_out[i1:w[j]-1])
            ;; endfor

            ;; the smooth triggers successive samples for a single jump, we
            ;; have to correct for this here, taking only the first of a
            ;; series
            isn = 0
            while isn le (nsn-1) do begin
               if flag[isn] ne 0 then begin
                  i1 = (isn-n_pts_avg-1)>0
                  i2 = (isn+nsmooth+n_pts_avg+1)<(nsn-1)

                                ;index = lindgen(nsn)
                                ;ww = where( index ge i1 and index le isn-1)
                                ;oplot, index[ww], toi_out[ww], psym=1, col=70
                                ;ww = where( index ge isn+nsmooth and index le i2)
                                ;oplot, index[ww], toi_out[ww], psym=1, col=70
                  
                  toi_out[isn+1:*] -= avg( toi_out[(isn+nsmooth)<(nsn-1):i2]) - avg(toi_out[i1:isn-1])
                  isn += nsmooth
               endif else begin
                  isn++
               endelse
            endwhile

;;            ;; xra = [0,100]
;;            wind, 1, 1, /free, xs=800, ys=800
;;            !p.multi=[0,1,5]
;;            plot, data.toi[ikid], /xs, xra=xra
;;            oplot, [w], [data[w].toi[ikid]], psym=1, col=250, thick=2
;;            if nw2 ne 0 then oplot, [w2], [data[w2].toi[ikid]], psym=4, col=150
;;            legendastro, ["Input TOI, ikid "+strtrim(ikid,2)], box=0
;;
;;            plot, dtoi, /xs, xra=xra
;;            oplot, [w], [dtoi[w]], psym=1, col=250, thick=2
;;            if nw2 ne 0 then oplot, [w2], [dtoi[w2]], psym=4, col=150
;;            oplot, [0, nsn], [0,0]+nsigma*stddev(dtoi), col=40
;;            oplot, [0, nsn], [0,0]-nsigma*stddev(dtoi), col=40
;;            legendastro, ["DTOI", "Nsiga = "+strtrim(nsigma,2)], box=0
;;
;;            plot, d2toi, /xs, xra=xra
;;            oplot, [w], [d2toi[w]], psym=1, col=250, thick=2
;;            if nw2 ne 0 then oplot, [w2], [d2toi[w2]], psym=4, col=150
;;            oplot, [0,nsn], [0,0]+nsigma*stddev(d2toi), col=40
;;            oplot, [0,nsn], [0,0]-nsigma*stddev(d2toi), col=40
;;            legendastro, ["D2TOI", "Nsiga = "+strtrim(nsigma,2)], box=0
;;            
;;            plot, toi_out, xra=xra, /xs
;;            legendastro, ['TOI out', 'iter '+strtrim(iter,2)], box=0
;;
;;            plot, data.toi[ikid]-toi_out, xra=xra, /xs
;;            legendastro, 'TOI in-out', box=0
;;            !p.multi=0
;;            stop
            data.toi[ikid] = toi_out

            
            ;; to start the next iteration
                                ;dtoi = data.toi[ikid]-shift(data.toi[ikid],1)
                                ;dtoi[0] = 0               ; due to shift's wrap around

            iter++
            toism = smooth( data.toi[ikid], nsmooth)
            dtoi  = toism - shift(toism,1)
            dtoi[0] = 0         ; correct for shift's wrap around
            d2toi = dtoi-shift(dtoi,1)
            d2toi[0] = 0
                                ;w = where( abs(dtoi) ge nsigma*stddev(dtoi), nw)
            w2 = where( abs(dtoi) ge nsigma*stddev(dtoi) and abs(d2toi) ge nsigma*stddev(d2toi), nw2)
            w = w2
            n2 = nw2
         endwhile
      endelse
   endif
endfor

if param.cpu_time then nk_show_cpu_time, param, "nk_remove_jumps"

end
