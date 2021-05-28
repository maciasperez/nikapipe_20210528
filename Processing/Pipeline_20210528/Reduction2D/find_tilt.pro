pro find_tilt, tabs,  tabw, xd, yd, x0, y0, px, py
; Find the best instantaneous tilted plane going through the data
; Copied from 2012/Pro diabolo run
; inputs: tabs and tabw = fltarr (ndet, nsample)
; and xd and yd instantaneous positions
; Outputs: x0,y0, average position
; px, py : vector orthogonal to the tilted plane
; Hence data=px(xd-x0)+py(yd-y0)
x0 = avg( xd)
y0 = avg( yd)
dx = (double( xd-x0 )^2 # double( tabw))
dy = (double( yd-y0 )^2 # double( tabw))
goodx = where( dx gt 0, ngoodx)
goody = where( dy gt 0, ngoody)
px = fltarr( n_elements( tabs[0, * ]))
py = px
if ngoodx ne 0 then $
  px[ goodx] = reform( (xd-x0) # double( tabs[ *, goodx] * tabw[ *, goodx]) ) / dx[ goodx]
if ngoody ne 0 then $
  py[ goody] = reform( (yd-y0) # double( tabs[ *, goody] * tabw[ *, goody]) ) / dy[ goody]

return

end
