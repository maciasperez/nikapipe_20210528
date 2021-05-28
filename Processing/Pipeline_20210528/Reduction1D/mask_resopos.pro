function mask_resopos, data, kidpar, verbose = verbose, tol=tol
; Produce a mask of the same size as (ndet) equal to 1 when the expected
; position ofthe resonance is far away from the measured one
; FXD dec 2013
; JFMP, aug, 2016 : take care of multiple boxes

if n_params() le 1 then begin
  message, /info, 'Call is : '
  print, 'mask = mask_resopos( data, kidpar) ; containing .ftone, .dftone '
  return, -1
endif

; Convert to Hz (should be checked)
ftone  = data.f_tone
dftone = data.df_tone

; Old res_frq is New frequency
; Old res_lg  is New width
; >=preRun7: called frequency, width
if tag_exist( kidpar, 'frequency') then begin
  resofr = kidpar.frequency  ; Check Hz OK
  resowidth= kidpar.width
endif else begin
  resofr = kidpar.res_frq
  resowidth = kidpar.res_lg
endelse

ftot = ftone + dftone
ftotmed = median( ftot, dim = 2) ; median total frequency per kid across the scan
; Fill in missing information with a conservative guess

;; Init mask
mask = replicate( 1B, n_elements( kidpar))  ; bad is default

;; Modifications from JFMP 
if  long(!nika.run) lt 13  then begin
;; Need to add a test on ngkida and ngkidb
;; because sometimes we only read one matrix, NP, Jan 2nd, 2014

gkida = where(kidpar.type eq 1 and kidpar.array eq 1, ngkida)  ; Kid A
gkidb = where(kidpar.type eq 1 and kidpar.array eq 2, ngkidb)  ; Kid B


if ngkida ne 0 then begin
   ukia = where( resowidth[gkida] le 0., nukia,  $
                 complem = kia)
   if nukia ne 0 then begin
      wimin = min( resowidth[gkida[ kia]])
      resowidth[gkida[ ukia]] = wimin
   endif

   maska = test_resopos( resofr[ gkida], verb = verbose, $
                         ftotmed[ gkida], resowidth[gkida], tol=tol)
   mask[ gkida] = maska
endif

if ngkidb ne 0 then begin
   ukib = where( resowidth[gkidb] le 0., nukib,  $
                 complem = kib)
   if nukib ne 0 then begin
      wimin = min( resowidth[gkidb[ kib]])
      resowidth[gkidb[ukib]] = wimin
   endif
   maskb = test_resopos( resofr[gkidb], verb = verbose, $
                         ftotmed[ gkidb], resowidth[gkidb], tol=tol)
   
   mask[ gkidb] = maskb
endif

endif else begin

;;nboxes = 20 
   nboxes = max(kidpar.acqbox)-min(kidpar.acqbox)+1
   boxlist = indgen(nboxes) + min(kidpar.acqbox)
;; for ibox=0,nboxes-1 do begin
   for iii=0, nboxes-1 do begin
      ibox = boxlist[iii]
      gkidb = where(kidpar.type eq 1 and kidpar.acqbox eq ibox, ngkidb) ; Kid BOX
      if ngkidb ne 0 then begin


         ukib = where( resowidth[gkidb] le 0., nukib,  $
                       complem = kib)
         if nukib ne 0 then begin
            wimin = min( resowidth[gkidb[ kib]])
            resowidth[gkidb[ukib]] = wimin
         endif
         maskb = test_resopos( resofr[gkidb], verb = verbose, $
                               ftotmed[ gkidb], resowidth[gkidb], tol=tol)
         
         mask[ gkidb] = maskb
      endif
   endfor

endelse

return,  mask
end


