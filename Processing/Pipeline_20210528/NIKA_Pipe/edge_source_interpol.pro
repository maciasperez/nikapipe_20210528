

nsn = n_elements(data)

;; Flag out the few samples that might be on source at the
;; beginning of the 1st subscan or the end of the last one and that
;; could bias the interpolations and produce artefacts on the final
;; maps.
my_loc_flag = data.flag

w1 = where( kidpar.type eq 1, nw1)
for i=0, nw1-1 do begin &$
   ikid = w1[i] &$
   ii = 0L &$
   while ii lt nsn and data[ii].off_source[ikid] eq 0 do begin &$
   my_loc_flag[ikid,ii] = 1 &$
      ii++ &$
   endwhile &$
   ii = nsn-1 &$
   while ii ge 0 and data[ii].off_source[ikid] eq 0 do begin &$
      my_loc_flag[ikid,ii] = 1 &$
      ii-- &$
   endwhile &$
endfor

index = lindgen(nsn)
w1 = where( kidpar.type eq 1, nw1)
for i=0, nw1-1 do begin &$
   ikid = w1[i] &$
   wflag = where( data.off_source[ikid] eq 0 or my_loc_flag[ikid,*] ne 0, nwflag, compl=wk, ncompl=nwk) &$
   if nwflag ne 0 then begin &$
      y = data.toi[ikid] &$
;;      y_smooth = smooth( y, long(!nika.f_sampling), /edge_mirror) &$
      y_smooth = smooth( y, long(!nika.f_sampling)) &$
      sigma = stddev( y[wk]-y_smooth[wk]) &$
      z = interpol( y_smooth[wk], index[wk], index) &$
      ;; if param.interactive then begin
      ;;    wind, 1, 1, /free, /large
      ;;    plot, data.toi[ikid], /xs
      ;;    oplot, wflag, data[wflag].toi[ikid], psym=8
      ;;    oplot, y_smooth, col=150
      ;;    stop
      ;; endif
      data[wflag].toi[ikid] = z[wflag] + randomn( seed, nwflag)*sigma &$
   endif &$
endfor
