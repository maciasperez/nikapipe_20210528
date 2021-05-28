;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
;    nk_atmb_harm_filter
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         filt= nk_atmb_harm_filter( nsnin, sample_arcsec,
;         fwhm_arcsec, nharm, k1d=k1d)
; 
; PURPOSE: 
;        Derives the filtering factor when one removes harmonics on a subscan
; 
; INPUT: 
;        - nsnin: number of samples in a subscan
;        - sample_arcsec: one sample span in arcsecond
;        - fwhm_arcsec: beam in arcsecond
;        - nharm: the number of harmonics : 1 for a cosine and sine
;          pair
;
; OUTPUT: 
;        - filt : a number between 0 and 1 giving the impact of the
;          filtering process
; 
; KEYWORDS: /k1d : means method at 1 dimension, instead of the
; representation of the 2D issue
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Apr 2021, FXD (extracted from Simu_imcm.scr in labtools FXD
;          N2Rall) to be used to have more accurate defilting factor
;in method 120


function nk_atmb_harm_filter, nsnin, sample_arcsec, fwhm_arcsec, nharm, $
                              k1d = k1d
filt = 0.
if n_params() lt 1 then begin
   dl_unix, 'nk_atmb_harm_filter'
   return, filt
endif

if keyword_set( k1d) then begin
  nsn = (nsnin/2L)*2 ; make it even
  xx = findgen(nsn)-nsn/2       ; centered gaussian
  frq = findgen( (nsn-1)/2) +1 
  nfreq = [0.0, frq, Nsn/2, -Nsn/2 + frq] ; ok for even nsn
  sigma = !fwhm2sigma* (fwhm_arcsec/sample_arcsec)
  gss = exp(-xx^2/(2*sigma^2))
  gss = gss/total(gss)                   ; normalized
  gss_f = fft(gss)                       ; forward transform ( has a 1/nsn factor)
                                ; We put nint because nharm can be a
                                ; non-integer (owing to degrees of freedom)
  ww = where( abs(nfreq) le nint(nharm), nww)  ; &  print, nww, ' should be ',  nharm*2+1
  ugss_f = gss_f
  if nww gt 0 then ugss_f[ww] = 0.
  ugss = fft( ugss_f, +1)
  filt = real_part( total(ugss*gss)/total(gss*gss))
endif else begin                ; 2D case
   nuv = nint( nsnin*sample_arcsec/2L)  ; Effectively 1 arcsec resolution
   nuv2 = nuv*2L
   ugrid = fltarr( nuv2, nuv2)
   vgrid = ugrid
   ma = ugrid + 1
   indsym = findgen( nuv2)-nuv
   for jv = 0, nuv2-1 do ugrid[*, jv] = indsym
   for iu = 0, nuv2-1 do vgrid[iu, *] = indsym
   sigmauv = (nsnin*sample_arcsec)/(!fwhm2sigma* fwhm_arcsec)
   uvbeam = exp( -(ugrid^2+vgrid^2) / (2*sigmauv^2) )
   maskend = where( abs( ugrid) le nharm, nmend)
   if nmend ne 0 then ma[ maskend] = 0.
   filt = total( ma*uvbeam^2)/ total(uvbeam^2)
;   help, nuv, nuv2, filt, sigmauv
endelse

return, filt
end
