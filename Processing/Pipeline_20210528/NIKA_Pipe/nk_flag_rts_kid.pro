pro nk_flag_rts_kid, kidpar, xoff, verbose = verbose
                                ; mark type 1 kids with type 3
                                ;    if they show some RTS
                                ; The technique relies on Cf method
                                ; and the statistics of the off-axis
                                ; differential
                                ; FXD August 2019, using first scan of
                                ; G2 indicated by Nicolas Ponthieu.
 ; verbose=2 for details
gkid = where( kidpar.type eq 1, ngkid) ; limit the search to "good" type 1 kids
fxoff = shift( xoff, 0, 1)-xoff
; derivative of the xoff vector. xoff does not contain signal (except for a small drift). Derivative is signal-free and hence susceptible to show RTS clearly.
nel = n_elements( fxoff[0, *])
nkid = n_elements( kidpar)
crit_rts = dblarr(nkid)-1       ; -1 is default value
for jk = 0, ngkid-1 do begin
   curk = gkid[ jk]
   disp = stddev( reform(fxoff[curk, 1:nel-2])) ; disregard both ends
   histo_make, fxoff[curk, 1:nel-2], xq, yq, stat_res, gauss_res, $
            /stat, /gauss, n_bins = 101, yarrfit = qfit, $
            min = -10*disp, max = +10*disp
   if disp gt 1.5*gauss_res[1] then begin ; redo if disp was incorrect
      disp = gauss_res[1]
      histo_make, fxoff[curk, 1:nel-2], xq, yq, stat_res, gauss_res, $
                /stat, /gauss, n_bins = 101, yarrfit = qfit, $
                  min = -10*disp, max = +10*disp
   endif
  ; Take everything above 3 sigma
   ixg = where( abs(xq-gauss_res[0]) gt 3.*gauss_res[1], nixg)
                                ; the criterion is the fraction of
                                ; samples which are really far from 0
   if nixg ne 0 then $
      crit_rts[ curk] = total( (yq[ ixg]- qfit[ ixg]))/float( nel)
endfor

; Find the RTS kids
; The 0.01 is an empirically found factor
; It means that above that threshold, the kid is RTS or pathological
; (the circle can be a bad fit but in any case the resulting toi is unreliable)
rtsind = where( crit_rts gt 0.01, nrtsind)
if keyword_set( verbose) then begin
   message, /info, strtrim( nrtsind, 2)+ ' Kids were transformed to type 3: '
   if verbose ge 2 then begin
      print, 'i, index, numdet, acqbox, RTS criterion'
      for i = 0, nrtsind-1 do $
         print, i, rtsind[ i], kidpar[ rtsind[ i]].numdet,  $
                kidpar[ rtsind[ i]].acqbox,  $
                crit_rts[ rtsind[ i]]
   endif
endif

if nrtsind ge 1 then kidpar[ rtsind].type = 3

return
end
