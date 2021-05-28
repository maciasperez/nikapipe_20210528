
pro file2nickname, file_in, nickname, scan, date, matrix, box, source, lambda, ext, file_save, day, raw_data=raw_data

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "file2nickname, file, nickname, scan, date, matrix, box, source, lambda, ext, file_save, day, raw_data=raw_data"
   return
endif


file = file_basename(file_in)
l = strlen( file)

if keyword_set(raw_data) then begin
   file_save = file+".save"
endif else begin
   file_save = strmid(file, 0, l-5)+".save"
endelse

box = strupcase(strmid( file, 0, 1))
date = strmid( file, 2, 19)
scan = strmid( file, 22, 4)
day  = strmid( date,0,4)+strmid(date, 5,2)+strmid(date,8,2)

w = where( strupcase(!nika.boxes) eq strupcase(box), nw)
if nw ne 0 then lambda = !nika.array[w].lambda else lambda = 0

matrix = "W"+strtrim(lambda,2)
nickname = date+"_"+scan+"_"+matrix
ext = box+strtrim(lambda,2)+"mm"

L = strlen( file)
l1 = strlen('A_2012_06_03_17h25m16_0152_')
source = strmid( file, l1, l-7-l1)

end
