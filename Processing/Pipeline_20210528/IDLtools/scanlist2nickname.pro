
pro scanlist2nickname, scan_list, nickname

nscans = n_elements(scan_list)
if nscans eq 1 then begin
   nickname = strtrim(scan_list[0], 2)
endif else begin
   nickname = strmid(scan_list[0], 0, 9)
   for iscan = 0, n_elements(scan_list)-2 do begin
      l = strlen(scan_list[iscan])
      nickname += strmid( scan_list[iscan], 9, l-9)+"_"
   endfor
   l = strlen(scan_list[iscan])
   nickname +=  strmid( scan_list[iscan],  9,  l-9)
endelse

end
