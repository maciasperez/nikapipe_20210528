pro nika_filing,  test = test,  verb = verb,  noexe = noexe,  noftp = noftp, $
                  x9 = x9, x10 = x10, zdir = zdir,  lpsc = lpsc, $
                  updp = updp, nowait = nowait, noimb = noimb, $
                  cfits = cfits,  imb_dir = imb_dir

; /updp is to update the params extension of existing fits files
; cfits=directory_name : start from antenna imbfits and write a clean toi
; imbfits file into 2 files in the directory_name (1 and 2mm) 
; /noimb: do not trigger imbfits production script nor downloading the files

message, /info, 'This is now an old routine'
print, 'Instead, consider using     nk_filing'
for i = 1, 10 do print, '   *'


  if keyword_set( test) then begin
     convert2_rawdata2imbfits, $
        dir_base = '/home/archeops/NIKA/Data/Test_raw_X33/', $
        imb_dir = '/NikaData/Test/',  $
        noexe = noexe,  verb = verb,  ftp = 1-keyword_set( noftp)
  endif else begin 
; up to run6
;     convert_rawdata2imbfits, verb = verb,  noexe = noexe,  $
;                              ftp = 1-keyword_set( noftp)
; Starting pre run 7
     if keyword_set( x9) then begin
        !nika.raw_acq_dir = '/home/archeops/NIKA/Data/raw_X9'
        zdir = 'X*'
     endif
     if keyword_set( x10) then begin
        !nika.raw_acq_dir = '/home/archeops/NIKA/Data/raw_X10'
        zdir = 'X*'
     endif
     if keyword_set( verb) then help,  !nika.raw_acq_dir
     print, 'Type q and enter to interrupt the program, or Crtl-C Crtl-C retall'
     convert2_rawdata2imbfits, verb = verb,  noexe = noexe,  $
                               ftp = 1-keyword_set( noftp),  zdir = zdir, $
                               lpsc = lpsc, updp = updp, nowait = nowait, $
                               noimb = noimb, cfits = cfits, imb_dir = imb_dir
  endelse

return
end
