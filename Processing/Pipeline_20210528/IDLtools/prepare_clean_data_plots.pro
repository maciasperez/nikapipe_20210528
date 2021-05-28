
pro prepare_clean_data_plots, param, info, data, kidpar, index, my_toi, my_kid

nsn = n_elements(data)
index = lindgen(nsn)
my_toi = dblarr(3,nsn)
my_kid = lonarr(3) -1
for iarray=1, 3 do begin
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
   if nw1 ne 0 then begin
      if !nika.ref_det[iarray-1] ne -1 then ikid = (where(kidpar.numdet eq !nika.ref_det[iarray-1]))[0] else ikid = w1[0]
      if ikid ne -1 then begin
         my_kid[iarray-1] = ikid
         my_toi[iarray-1,*] = data.toi[ikid]
      endif
   endif
endfor

end
