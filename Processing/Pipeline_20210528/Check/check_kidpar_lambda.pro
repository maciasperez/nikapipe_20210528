
spawn, "find . -name '*.pro' -print > bidon.txt"
readcol, "bidon.txt", file_list, format="A"

openw, 1, "results.dat"
for i=0, n_elements(file_list)-1 do begin
   cmd = "grep -i kidpar "+file_list[i]+" | grep -i lambda | grep -i eq"
   spawn, cmd, m
;   if m[0] ne "" then stop
;   for j=0, n_elements(m)-1 do printf, 1, strtrim(file_list[i],2)+",
;   "+strtrim(m[j],2)
   if m[0] ne "" then begin
      for j=0, n_elements(m)-1 do printf, 1, strtrim(file_list[i],2)+", "+strtrim(m[j],2)
   endif
endfor
close, 1

end
