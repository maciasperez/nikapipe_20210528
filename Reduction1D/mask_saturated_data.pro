function mask_saturated_data, data,  satur_level = satur_level
; Produce a mask of the same size as (ndet,nsample) equal to 1 when the
; linearity angle is beyond pi/4 in absolute value
; satur_level is pi/4 by default 
if n_params() ne 1 then begin
  message, /info, 'Call is : '
  print, 'mask = mask_saturated_data( read_struct_data ) ; containing .i, .q, .di, .dq '
  return, -1
endif

if keyword_set( satur_level) then sl = abs(satur_level) else sl = !dpi/4
angle = nk_angleiq_didq( data)

mask = abs( angle) gt sl

return,  mask
end


