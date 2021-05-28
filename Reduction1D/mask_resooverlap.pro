function mask_resooverlap, data, kidpar, verbose = verbose, tol=tol
; try to find kid frequencies which are too close to one another
; Produce a mask of the same size as (ndet=n_elements( kidpar))
; equal to 1 when the expected
; position of the resonance is too close to another one
; FXD dec 2013
; FXD Feb 2014, bug discovered with decaHz (once more)
; JFMP aug 2016, update to take into account boxes

if n_params() le 1 then begin
  message, /info, 'Call is : '
  print, 'mask = mask_resooverlap( data, kidpar ) ; containing .ftone, .dftone '
  return, -1
endif

; Convert to Hz (should be checked)
ftone  = data. f_tone
dftone = data.df_tone

; Old res_frq is New frequency
; Old res_lg  is New width
; >=preRun7: called frequency, width
if tag_exist( kidpar, 'frequency') then begin
  resofr = kidpar.frequency*10.D0  ; Check Hz OK NO NO NO back to decaHz
  resowidth= kidpar.width*10.D0
endif else begin
  resofr = kidpar.res_frq
  resowidth = kidpar.res_lg
endelse

ftot = ftone + dftone
ftotmed = median( ftot, dim = 2) ; median total frequency per kid across the scan

; Fill in missing information with a conservative guess
mask = replicate( 1B, n_elements( kidpar))  ; bad is default


;; Modifications from JFMP 
if  long(!nika.run) lt 13  then begin

   gkida = where(kidpar.array eq 1, ngkida)  ; All tones A
   gkidb = where(kidpar.array eq 2, ngkidb)  ; All tones B

;; Need to add a test on ngkida and ngkidb
;; because sometimes we only read one matrix, NP, Jan 2nd, 2014
   if ngkida ne 0 then begin
      ukia = where( resowidth[gkida] le 0., nukia,  $
                    complem = kia)
      if nukia ne 0 then begin
         wimin = min( resowidth[gkida[ kia]])
         resowidth[gkida[ ukia]] = wimin
      endif
      maska = test_resooverlap( verb = verbose, $
                                ftotmed[ gkida], resowidth[ gkida], tol=tol)
      mask[ gkida] = maska
   endif

   if ngkidb ne 0 then begin
      ukib = where( resowidth[gkidb] le 0., nukib,  $
                    complem = kib)
      if nukib ne 0 then begin
         wimin = min( resowidth[gkidb[ kib]])
         resowidth[gkidb[ ukib]] = wimin
      endif
      maskb = test_resooverlap( verb = verbose, $
                                ftotmed[ gkidb], resowidth[ gkidb], tol=tol)
      mask[ gkidb] = maskb
   endif

endif else begin

;;   nboxes = 20 
   nboxes = max(kidpar.acqbox)-min(kidpar.acqbox)+1
   boxlist = indgen(nboxes) + min(kidpar.acqbox)
   ;;for ibox=0,nboxes-1 do begin
   for iii=0, nboxes-1 do begin
      ibox = boxlist[iii]
      gkidb = where(kidpar.acqbox eq ibox, ngkidb) ; for all boxes

      if ngkidb ne 0 then begin
         ukib = where( resowidth[gkidb] le 0., nukib,  $
                       complem = kib)
         if nukib ne 0 then begin
            wimin = min( resowidth[gkidb[ kib]])
            resowidth[gkidb[ ukib]] = wimin
         endif
         maskb = test_resooverlap( verb = verbose, $
                                   ftotmed[ gkidb], resowidth[ gkidb], tol=tol)
         mask[ gkidb] = maskb
      endif
   endfor

endelse


return,  mask
end


