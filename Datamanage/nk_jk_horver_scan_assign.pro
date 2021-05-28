pro nk_jk_horver_scan_assign, hor, pindex, jksign
                                ; Routine used in method 120 to pair
                                ; scan (one horiz with one vertical)
                                ; and then to assign a JK sign to the
                                ; pair
  ; deal with cases with a missing partner
  ; Hor is a bytarr (nscan)
nscan = n_elements( hor)
indexhor = where( hor, nhor, compl = indexver, ncomp = nver)

if nhor eq 0 then begin
   pindex = -1
   jksign = 1
   return
endif 
; If nver > nhor Pairing one ver with one hor is enough to have all pairs
; Assume print,  nver ge nhor (but it works in any case, maybe non optimally)
if nhor gt 0 then $
   pindexhor = lonarr( nhor)-1 else $
; which vertical scan is paired with an hor scan
   pindexhor = -1
if nver gt 0 then pindexver = lonarr( nver)-1 else $
   pindexver = -1

for iver = 0, nver-1 do begin
   u = where( indexhor le indexver[iver], nu) ; look for Hor scans of index smaller than the present vertical one
   if nu eq 0 then begin
      u = 0
   endif
   ihor = max(u)               ; the closest
   pindexver[ iver] = indexhor[ ihor]
   pindexhor[ ihor] = indexver[ iver]
endfor
; Complete the missing hor
v = where( pindexhor eq (-1), nv)
if nv ne 0 then begin
;   print, nv
   for iv = 0, nv-1 do begin
      ihor = v[ iv]
      u = where( indexver gt indexhor[ ihor], nu) ; look for Ver scans of index greater than the present horizontal one
      if nu eq 0 then begin
         u = nver-1
      endif
      iver = min(u)             ; the closest
      pindexhor[ ihor] = indexver[ iver]
   endfor  
   
endif
; For the whole index, which is the partner of the pair ?
pindex = intarr( n_elements(hor)) -1
pindex[ indexhor] = pindexhor
pindex[ indexver] = pindexver

; So jackknife sign propagates from there
; Need a loop
jksign = intarr( nscan)
sicur = 1
for iscan = 0, nscan-1 do begin
   if jksign[ iscan] eq 0 then begin
      if jksign[ pindex[ iscan]] ne 0 then begin
         jksign[ iscan] = jksign[ pindex[ iscan]]
      endif else begin
         jksign[ iscan] = sicur
         if pindex[ iscan] gt iscan then jksign[ pindex[ iscan]] = sicur
         sicur = sicur*(-1)     ; change sign for the next one
      endelse
   endif ; do nothing otherwise
endfor

;for i = 0, nscan -1 do print, i, hor[i], pindex[i], jksign[i]
message, /info, 'JK imbalance is '+ $
         string( total( jksign gt .5))+string( total( jksign lt (-0.5)))
return
end
