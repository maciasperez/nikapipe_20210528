pro give_short_name, file, short_name, raw=raw, fits=fits

l = strlen(file)
if keyword_set(fits) then begin
   nickname = strmid( file, 0, l-5)
endif else begin
   message, /info, ""
   message, /info, "to be updated to get short name for raw files"
endelse

end

