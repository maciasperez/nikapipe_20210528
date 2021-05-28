function intinstring,  str,  bef,  aft
; find the largest number in a string
;e.g.
; print, intinstring('pico143veleta',bef,aft)
;         143
; print,bef,' ',aft
; pico veleta
b = byte( str)
u = where( b ge 48 and b le 57,  nu)
bef = ''
aft = str
if nu ne 0 then begin
   if nu gt 1 then begin
; look for continuous number
      dsh =  u[1: * ]
      cci = where( dsh- u[0:nu-2] ne 1,  ncci)
      if ncci eq 0 then good = u else good = u[ 0: cci[0]]
   endif else good = u[0]
   out = long( string( b[ good]))
   if good[0] ne 0 then bef = strmid( str, 0, good[0])
   ngood = n_elements( good)
   if good[ ngood-1] ne strlen( str) then  $
      aft = strmid( str, good[ ngood-1] + 1, strlen( str)-(good[ngood-1] + 1))
                                                                     
endif else out = -1

return,  out
end
