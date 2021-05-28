
pro skydip2kidpar, kidpar1, kidpar2, skydip_scan_num, skydip_day

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "skydip2kidpar, kidpar1, kidpar2, skydip_scan_num, skydip_day, RF=RF"
   return
endif

;; re-init skydip parameters
kidpar1.c0_skydip = 0.d0
kidpar2.c0_skydip = 0.d0

;; Read and reduce the correct skydip scan
pf  = 1
skydip_new, skydip_day, skydip_scan_num, kidpar, param=param_skydip

;; Update skydip coeffs
for i=0, n_elements(kidpar1)-1 do begin
   w = where( kidpar.numdet eq kidpar1[i].numdet, nw)
   if nw ne 0 then begin
      kidpar1[i].c0_skydip = kidpar[w].c0_skydip
      kidpar1[i].c1_skydip = kidpar[w].c1_skydip
   endif
endfor

for i=0, n_elements(kidpar2)-1 do begin
   w = where( kidpar.numdet eq kidpar2[i].numdet, nw)
   if nw ne 0 then begin
      kidpar2[i].c0_skydip = kidpar[w].c0_skydip
      kidpar2[i].c1_skydip = kidpar[w].c1_skydip
   endif
endfor

end



