pro nika_pipe_read_cleantoifits, dir, file, toi, kidpar, $
                                 hdr1,  hdr2, hdr3, old = old
; Read a clean toi fits into a structure
; just give dir and file
; FXD June 2014
; Oct 2014: /old= first version of clean imbfits, otherwise most recent

infile = dir+'/'+file
freqna = strmid( file, 12,3) ; = '1mm' or 2
iext = 1  ; Primary extension has nothing in
isubscan_current = 1            ; first subscan
isa = 0  ; sample current count
isb = -1 ; end sample count

if file_test( infile) eq 0 then begin
  message, 'That file does not exist: '+infile
  return
endif
if keyword_set( old) then nikaext = 'CleanNIKAdata' else $
   nikaext = 'IMBF-backendNIKA'+freqna
readin = mrdfits(infile, iext, hdr, status=status, /silent, /no_tdim)
while status ge 0 do begin
   extna = sxpar( hdr, 'EXTNAME')
   case strupcase( strtrim( extna, 2)) of 
      strupcase('KidParams') : begin
         kidpar = readin
      end
      strupcase( 'IMBF-scan') : hdr1 = hdr
      strupcase( 'IMBF-antenna-s') : hdr2 = hdr
      strupcase( nikaext) : begin
        if isubscan_current eq 1 then begin
           hdr3 = hdr
           ndet = n_elements(readin[0].br)
           dstr = {sample:0L, mjd:0D, br: fltarr( ndet), fl: intarr( ndet), $
                   XX: dblarr( ndet), YY: dblarr( ndet), cm: fltarr( ndet), $
                  subscan:0}
           ntag = n_tags( dstr)
           toi = replicate( dstr, 60000) ; 60000 upper limit in samples
        endif
        nsa = n_elements( readin)
        isb = isa+ nsa- 1
; -2 because subscan is not part of the original data
        ntr = n_tags( readin)
        for itag = 0, (ntag-2) < (ntr-1) do toi[isa:isb].(itag) = readin.(itag)
        toi[isa:isb].subscan = isubscan_current
        isa = isb+1
        isubscan_current = isubscan_current+1
        if ntag-2 ge ntr  $
        then print, 'This scan has no CM '+infile+ $
                    ' at subscan '+strtrim( isubscan_current, 2)
      end
      else : begin
         ; do nothing for that extension
      end
   endcase
   iext = iext + 1
   readin = mrdfits(infile, iext, hdr, status=status, /silent, /no_tdim)
endwhile
toi = toi[0:isb]  ; truncate to the useful part


return
end
