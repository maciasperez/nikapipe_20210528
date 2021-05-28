pro conviq2cf, data,  dapf, ndeg, freqnorm
;; FXD (adapted from conviq2pf)
; Rearrange data so that the new polynomial fit is added (last column)
; Should be used just after restore and just before save2str
; Truncate to scan only
; What could be used is where subscan ne 0
scansub= where( data.subscan GT 0, nscansub)
; keep the whole data set but fit only on the scan part
IF nscansub LT 10 THEN BEGIN ;case where the file is not a scan
  nscansub= n_elements( data) ; take the lot
  scansub = lindgen( nscansub)
ENDIF
ndet= n_elements(data[0].i)

; Do a minimal check on valid data (unvalid data are at 0)
flagI= reform( abs(data.i) LT 0.5)
flagQ= reform( abs(data.q) LT 0.5)
totflagI= total( float( flagI),1)
totflagQ= total( float( flagQ),1)
thresh= ndet- 6  ; to allow 8 detectors only
totflag= smooth( float( totflagI GE thresh OR totflagQ GE thresh),3)
badsam= where( totflag NE 0, nbadsam)
flscan= replicate(0B, n_elements( data))
flscan[ scansub]=1B
IF nbadsam NE 0 THEN flscan[ badsam]=0B
scansub= where( flscan, nscansub)

IF nscansub EQ 0 THEN message,'Data are all wrong', /info

; ndeg must be set in init to 4
dapf= freq_cider_str( data, ndeg, freqnorm, scansub)

return
end
