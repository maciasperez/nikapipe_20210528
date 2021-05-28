function mask_resoident, data, kidpar, verbose = verbose, tol=tol
; try to find kid frequencies which are identical to one another
; Produce a mask of the same size as (ndet=n_elements( kidpar))
; equal to 1 when the expected
; position of the resonance is equal to another one
; FXD August 2019

if n_params() le 1 then begin
  message, /info, 'Call is : '
  print, 'mask = mask_resoident( data, kidpar,/ver,tol=tol) '
  return, -1
endif

; Convert to Hz (should be checked)
ftone  = data. f_tone
ftonemed = median( ftone, dim = 2)
                                ; median tone frequency per kid across
                                ; the scan (it should really be
                                ; constant anyway

; Prepare output
mask = replicate( 1B, n_elements( kidpar)) ; bad is default


if  long(!nika.run) lt 13  then begin
;; Need to add a test on ngkida and ngkidb
;; because sometimes we only read one matrix, NP, Jan 2nd, 2014
   gkida = where(kidpar.array eq 1, ngkida)  ; All tones A
   gkidb = where(kidpar.array eq 2, ngkidb)  ; All tones B
   if ngkida ne 0 then begin
      maska = test_resoident( verb = verbose, ftonemed[ gkida], tol=tol)
      mask[ gkida] = maska
   endif
   if ngkidb ne 0 then begin
      maskb = test_resoident( verb = verbose, ftonemed[ gkidb], tol=tol)
      mask[ gkidb] = maskb
   endif
endif else begin  ; main case
;;   nboxes = 20 
   nboxes = max(kidpar.acqbox)-min(kidpar.acqbox)+1
   boxlist = indgen(nboxes) + min(kidpar.acqbox)
   for iii=0,nboxes-1 do begin
      ibox = boxlist[iii]
      gkidb = where(kidpar.acqbox eq ibox, ngkidb) ; for all boxes
      if ngkidb ne 0 then begin
         maskb = test_resoident( verb = verbose, ftonemed[ gkidb], tol=tol)
         mask[ gkidb] = maskb
      endif
   endfor
endelse

return,  mask
end


