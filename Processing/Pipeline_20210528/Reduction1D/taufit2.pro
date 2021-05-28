pro taufit2, am, fr, fr0, fr2K, taumed, $
             taumean, frfit, rmsfit, $
             tau = tauall, opacorr = opacorr, silent = silent
; Find a fit for skydips
; here the coefficients fr0 and fr2K are known
; take the median and mean of tau across all airmasses
; FXD, Feb 2015
  ; FXD, Feb 2017, add opa keyword
taumed = -1.
taumean = -1.
rmsfit = 0.
nel = n_elements( am)
if nel lt 1 then return
redf = 1+ (fr-fr0)/(fr2K*270.D0)
gfr = where( redf gt 0 and redf lt 1,  ngfr)
frfit = fr*0.
tauall = fltarr( nel)
opacorr = tauall+1.  ; exp(am.tau): the corrective factor to be applied to the timelines.
if ngfr gt 0 then begin
   tau = -1/am[ gfr]* alog( redf[ gfr])
   opacorr[ gfr] = 1/redf[ gfr]
   tauall[ gfr] = tau
   taumed = median( tau)
   taumean = mean( tau)
   fit = [-fr2K, taumed, fr0]
   frfit[ gfr] = tau_model2( am[ gfr], fit)
   rmsfit = sqrt( mean( (fr[ gfr]-frfit[ gfr])^2))
endif

return
end
