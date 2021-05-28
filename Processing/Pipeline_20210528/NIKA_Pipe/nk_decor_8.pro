

pro nk_decor_8, param, info, data, kidpar, grid, out_temp_data

nsn   = n_elements(data)
nkids = n_elements(kidpar)

;; Keep compatibility with old acquistions
nk_patch_kidpar, param, info, data, kidpar

;; Init the common mode output structure
out_temp_data = create_struct( "toi", data[0].toi*0.d0 + !values.d_nan)
out_temp_data = replicate( out_temp_data, n_elements(data))

;; @ Discard kids that are too uncorrelated to the other ones
if param.flag_uncorr_kid ne 0 then begin
   for i = 1, param.iterate_uncorr_kid do nk_flag_uncorr_kids, param, info, data, kidpar
endif

;; Define continuous sections of the scan per KID
for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)

   toi_out  = data.toi[w1] + !values.d_nan
   flag_out = data.flag[w1]*0 + 2L^7
   
   if nw1 ne 0 then begin
      nkids_in_cm = total( data.off_source[w1], 1)

      wsection = where( nkids_in_cm ge param.nmin_kids_in_cm, nwsection, compl=wout, ncompl=nwout)
      
      if nwsection lt param.nsample_min_per_subscan then begin
         flag_out[*,wsection] = 2L^7
         message, /info, "could not find enough kids anywhere, A"+strtrim(iarray,2)
      endif else begin

         if param.decor_on_two_subscans eq 1 then begin
            i1 = min(data.subscan)
            while i1 le max(data.subscan) do begin
               wsample = where( data.subscan ge i1 and data.subscan le i1+1, nwsample)

               nk_get_cm_sub_2, param, info, data[wsample].toi[w1], $
                                data[wsample].flag[w1], data[wsample].off_source[w1], $
                                kidpar[w1], common_mode

;               wind, 1, 1, /free
;               plot, total( data[wsample].off_source[w1], 1), /xs
;               stop
               
               for i=0, nw1-1 do begin
                  ikid = w1[i]
                  wfit = where( finite(common_mode) and data[wsample].off_source[ikid] eq 1, nwfit)
                  fit = linfit( common_mode[wfit], data[wsample[wfit]].toi[ikid])
                  yfit = fit[0] + fit[1]*common_mode
               
                  data[wsample].toi[          ikid] -= yfit
                  out_temp_data[wsample].toi[ ikid]  = yfit
               endfor

               i1 += 2
            endwhile

         endif else begin
            nk_get_cm_sub_2, param, info, data.toi[w1], data.flag[w1], data.off_source[w1], kidpar[w1], common_mode
            ;; ;; param.nmin_kids_in_cm already accounted for in nk_get_cm_sub_2
            ;; if nwout ne 0 then common_mode[wout] = !values.d_nan
            
            for i=0, nw1-1 do begin
               ikid = w1[i]
               wfit = where( finite(common_mode) and data.off_source[ikid] eq 1, nwfit)
               fit = linfit( common_mode[wfit], data[wfit].toi[ikid])
               yfit = fit[0] + fit[1]*common_mode
               
               data.toi[          ikid] -= yfit
               out_temp_data.toi[ ikid]  = yfit
               
               ;; wind, 1, 1, /free, /large
               ;; my_multiplot, 1, 3, pp, pp1, /rev
               ;; xra = [1, 1.6]*1d4
               ;; nsn = n_elements(data)
               ;; index = lindgen(nsn)
               ;; plot, index, data.toi[ikid], /xs, xra=xra
               ;; oplot, index[wfit], data[wfit].toi[ikid], psym=1, syms=0.5, col=100
               ;; oplot, index, yfit, col=250
            endfor
         endelse

         if nwout ne 0 then data[wout].flag[ikid] = 2L^7
      endelse
   endif
endfor


end

