pro nk_sat_cf, data, kidpar, cfraw, $
               satur_level = satur_level, silent = silent
; Flag data which are saturated in the case of Cf method only
; satur_level is an angle from the center of the resonance. pi/2 means
; we tolerate half the circle (-pi/2, +pi/2)
; FXD Sept 2019, see nk_data_conventions for usage
if not keyword_set( satur_level) then satur_level = !dpi/2
ndat = n_elements( data)
npix_sat = lonarr(3)

; Convert satur_level to y
;;;ysat = freqnorm_vec[ kidpar.array-1]* tan( satur_level/2.)
ysat = tan( satur_level/2.)
;;;sin( satur_level)/(1+cos( satur_level))

mask3 = abs( cfraw) gt ysat # (dblarr( ndat)+1)


; copied from nk_outofres
wkid_heavysat = where(total(mask3 ne 0, 2) gt 0.3 * ndat $
                      and kidpar.type eq 1, c_hs)
if c_hs ge 1 then begin
   nk_add_flag, data, 2, wkid=wkid_heavysat
   for arr = 0, 2 do begin
      w = where( kidpar[wkid_heavysat].array eq arr + 1, cw)
      npix_sat[arr] += cw
   endfor
endif

w_sat = where(mask3 ne 0, c_sat)
if c_sat ge 1 then nk_add_flag, data, 2, w2d_k_s=w_sat

for arr=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq arr, nw1)
   if nw1 ne 0 then begin
      if npix_sat[arr-1] eq nw1 then begin
         nk_error, info, 'All Kids of array '+strtrim(arr,2)+$
                   ' are saturated for more than 30% of the data', $
                   silent=silent
         return
      endif
   endif
endfor
if total( npix_sat) ne 0 then print, 'nk_sat_cf ', npix_sat
;stop
return
end
