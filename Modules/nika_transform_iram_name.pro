function nika_transform_iram_name,  filein, nscan, k_nscan = nscanfile,  teltime = teltime
; Transform to standard fits file name for Iram
; status is 1 for ok, 0 for nok
;e.g. filein = 'A_2012_05_31_00h18m10_0003_NGC702_C.fits'
; becomes
; fileout= 'NIKA2iram-20120531-3.fits'
str2 = strsplit(filein,'_',/extract)
if !nika.run le 10 then begin
   nscanfile = strtrim(long(str2[5]),2) 
endif else begin
   if n_elements( str2) lt 11 then nscanfile = 0 else $
      nscanfile = strtrim(long(str2[9]),2) 
endelse
;;;; FXD : not working
;;;; nscanfile = fix( strmid( filein, 22, 4) )
teltime = strmid( filein, 2, 4) + strmid( filein, 7, 2) + strmid(filein, 10, 2)
fileout = 'NIKA2iram-' + teltime + '-' + strtrim( nscan, 2) + '.fits'
return,  fileout
end
