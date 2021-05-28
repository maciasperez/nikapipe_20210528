
pro nk_fourier_subtract, param, info, data, kidpar, grid, subtract_maps


if info.status eq 1 then return
if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

;; Quick check if there actually is a mask
w = where( data.off_source eq 0, nw)
if nw eq 0 then begin
   ;; nothing to do
endif else begin
   w1 = where( kidpar.type eq 1, nw1)
   if nw1 eq 0 then begin
      text = "No valid kid"
      message, /info, text
      nk_error, info, text
      return
   endif

   ;; Init filter
   np_bandpass, data.toi[0], !nika.f_sampling, s_out, $
                freqlow=param.freqlow, freqhigh=param.freqhigh, $
                filter=filter, delta_f=param.bandpass_delta_f

   
   w1 = where( kidpar.type eq 1 and (kidpar.array eq 1 or kidpar.array eq 3), nw1)
   map_toi = data.toi*0.d0
   nk_map2toi_3, param, info, subtract_maps.map_i_1mm, data.ipix[w1], toi_1mm
   map_toi[w1,*] = toi_1mm
   w2 = where( kidpar.type eq 1 and kidpar.array eq 2, nw2)
   nk_map2toi_3, param, info, subtract_maps.map_i_2mm, data.ipix[w2], toi_2mm
   map_toi[w2,*] = toi_2mm
   stop

   w1 = where( kidpar.type eq 1, nw1)
   nsn = n_elements(data)
   index = lindgen(nsn)
   for i=0, nw1-1 do begin
      ikid = w1[i]
      w_on = where( data.off_source[ikid] eq 0, nw_on, compl=w_off)
      if nw_on ne 0 then begin

         if param.debug ne 0 then time = index/!nika.f_sampling
         if param.debug ne 0 then xra = [0,30]
         if param.debug ne 0 then wind, 1, 1, /free, /xl
         if param.debug ne 0 then plot, time, data.toi[ikid], /xs, xra=xra, title="i="+strtrim(i,2)+", ikid: "+Strtrim(ikid,2)
         if param.debug ne 0 then oplot, time, data.off_source[ikid], col=200

         ;; junk  = interpol( smooth( data[w_off].toi[ikid], 20, /edge_zero), index[w_off], index)
         junk  = interpol( smooth( data[w_off].toi[ikid], 50, /edge_zero), index[w_off], index)
         ;r = poly_fit(

         if param.debug ne 0 then oplot, time, junk, col=40
         if param.debug ne 0 then oplot, time, (data.subscan-min(data.subscan))/10., col=200

         sigma = stddev( data.toi[ikid]-junk)
         junk[w_off] = data[w_off].toi[ikid] ; replace by true data
         junk[w_on] += randomn( seed, nw_on)*sigma

         if param.debug ne 0 then oplot, time, junk, col=100

         np_bandpass, junk, !nika.f_sampling, s_out, filter=filter

         if param.debug ne 0 then oplot, time, s_out, col=150
         if param.debug ne 0 then stop

         ;; then subtract difference from input TOI
         data.toi[ikid] -= (junk - s_out)

      endif
   endfor
endelse

if param.cpu_time then nk_show_cpu_time, param

end

















end
