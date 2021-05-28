pro nika_conviq2pf2, data, kidpar, dapf, ndeg, $
                     freqnorm, index, $
                     cfmethod = cfmethod, satur_level = satur_level
;; FXD (copied from run5 pipeline)
; Rearrange data so that the new polynomial fit is added (last column)
; Should be used just after restore and just before save2str
; Truncate to scan only
; What could be used is where subscan ne 0
; freqnorm is a vector of 2 values (A and B)
; pf method is default
; /cfmethod means a simpler implementation (FXD Dec 2013)
; version 2 is for testing purpose (frequency sweeps)

;scansub= where( data.subscan GT 0, nscansub)
scansub = index
nscansub = n_elements( index)
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

; ndeg_pf must be set in init to 3
if keyword_set( cfmethod) then begin
   ;; dapf= nika_freq_cider_str2( data, kidpar, ndeg, freqnorm, scansub, $
   ;;                          satur_level = satur_level)
endif else begin
   dapf= nika_freq_polyder_str2( data, kidpar, ndeg, freqnorm, scansub, $
                               satur_level = satur_level)
endelse

return
end
