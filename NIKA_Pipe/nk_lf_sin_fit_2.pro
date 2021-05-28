

;; Wrapper for lf_sin_fit per subscan or per scan

pro nk_lf_sin_fit_2, param, info, data, kidpar

if param.decor_per_subscan eq 1 then begin
   for isubscan=min(data.subscan), max(data.subscan) do begin
      wsubscan = where( data.subscan eq isubscan, nwsubscan)
      if nwsubscan ne 0 then begin
         data1 = data[wsubscan]
         nk_lf_sin_fit, param, info, data1, kidpar
         data[wsubscan].toi = data1.toi
      endif
   endfor
endif else begin
   nk_lf_sin_fit, param, info, data, kidpar
endelse

end
   
     
