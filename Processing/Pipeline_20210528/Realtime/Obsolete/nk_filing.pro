pro nk_filing, test = test,  verb = verb,  noexe = noexe,  noftp = noftp, $
                  zdir = zdir,  lpsc = lpsc, $
                  updp = updp, nowait = nowait, noimb = noimb, $
                  cfits = cfits,  imb_dir = imb_dir

; /updp is to update the params extension of existing fits files
; cfits=directory_name : start from antenna imbfits and write a clean toi
; imbfits file into 2 files in the directory_name (1 and 2mm) 
; /noimb: do not trigger imbfits production script nor downloading the files
; FXD, start from nika_filing. Oct-2014 Wants to upgrade to nk pipeline formats

  if keyword_set( test) then begin
     nk_rawdata2imbfits, $
        dir_base = '/home/archeops/NIKA/Data/Test_raw_X35/', $
        imb_dir = '/NikaData/Test/',  $
        noexe = noexe,  verb = verb,  ftp = 1-keyword_set( noftp)
  endif else begin 
     if keyword_set( verb) then help,  !nika.raw_acq_dir
     print, 'Type q and enter to interrupt the program, or Crtl-C Crtl-C retall'
     nk_rawdata2imbfits, verb = verb,  noexe = noexe,  $
                               ftp = 1-keyword_set( noftp),  zdir = zdir, $
                               lpsc = lpsc, updp = updp, nowait = nowait, $
                               noimb = noimb, cfits = cfits, imb_dir = imb_dir
  endelse

return
end
