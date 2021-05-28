
;; from nk_hwp_rm, just for one kid and accounts for the source


pro nk_hwp_rm_solo, toi, flag, position, nharmo, amplitudes, fit=fit, nodrift=nodrift

nsn   = n_elements( toi)
t = dindgen(nsn)/!nika.f_sampling
wall  = where( flag eq 0, nwall)

if keyword_set(nodrift) then begin
   amplitudes = dblarr( 2*nharmo)

   ;; Fitting template, only on good positions
   temp = dblarr( 2*nharmo, nwall)
   for i=0, nharmo-1 do begin
      temp[ i*2,     *] = cos( (i+1)*position[wall])
      temp[ i*2 + 1, *] = sin( (i+1)*position[wall])
   endfor

   ;; Global template for the reconstruction
   outtemp = dblarr( 2*nharmo, nsn)
   for i=0, nharmo-1 do begin
      outtemp[ i*2,     *] = cos( (i+1)*position)
      outtemp[ i*2 + 1, *] = sin( (i+1)*position)
   endfor

endif else begin
   amplitudes = dblarr( 4*nharmo)

   ;; Fitting template, only on good positions
   temp = dblarr( 4*nharmo, nwall)
   for i=0, nharmo-1 do begin
      temp[ i*4,     *] =         cos( (i+1)*position[wall])
      temp[ i*4 + 1, *] = t[wall]*cos( (i+1)*position[wall])
      temp[ i*4 + 2, *] =         sin( (i+1)*position[wall])
      temp[ i*4 + 3, *] = t[wall]*sin( (i+1)*position[wall])
   endfor

   ;; Global template for the reconstruction
   outtemp = dblarr( 4*nharmo, nsn)
   for i=0, nharmo-1 do begin
      outtemp[ i*4,     *] =   cos( (i+1)*position)
      outtemp[ i*4 + 1, *] = t*cos( (i+1)*position)
      outtemp[ i*4 + 2, *] =   sin( (i+1)*position)
      outtemp[ i*4 + 3, *] = t*sin( (i+1)*position)
   endfor
endelse

ata   = matrix_multiply( temp, temp, /btranspose)
atam1 = invert(ata)

womega = where( position eq min(position), nwomega)
base = interpol( toi[womega], womega, dindgen(nsn))
toi -= base
a = avg( toi)
toi -= a

atd = matrix_multiply( toi[wall], temp, /btranspose)
ampl = atam1##atd
amplitudes[*] = ampl
fit  = reform( outtemp##ampl)
toi -= fit
toi += a + base

end
