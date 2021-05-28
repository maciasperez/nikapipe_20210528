
pro file2scan_day, file_in, scan, day, time

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "file2scan_day, file_in [, scan, day, time]"
   return
endif

file = file_basename(file_in)
l = strlen( file)

date = strmid( file, 2, 19)
day  = strmid( date,0,4)+strmid(date, 5,2)+strmid(date,8,2)

; FXD fix for Run11 as the file has increased by "A" at the end of the date
; (only during technical time)
if !nika.run le 10 or long(day) ge 20150126 then iscan = 22 else iscan = 43
scan = long( strmid( file, iscan, 4))

on_ioerror, badtime
valid = 0
time = ten( long( strmid( date, 11, 2)),  long( strmid( date, 14, 2)), $
            long( strmid( date, 17, 2)))
valid = 1
badtime: if ~valid then time = -1.
end
