pro match2d, xa, ya, xb, yb, inda, indb
; pair vector A with vector B so that the distance between each pair is the
; smallest.
; hence the distance between Va[inda] and Vb is minimal and
; between Vb[indb] and Va is minimal
; Method : use the min function
; FXD May 2016, needed for focal plane reconstruction
na = n_elements( xa) < n_elements( ya)
nb = n_elements( xb) < n_elements( yb)

indb = intarr(na)
for ia = 0, na-1 do begin
   ; Compute the square of the distance of all Vb towards one A vector component
   dd = (xb - double(xa[ia]))^2 + (yb - double(ya[ ia]))^2
   dmin = min( dd, imin)
   indb[ ia] = imin
endfor

inda = intarr(nb)
for ib = 0, nb-1 do begin
   ; Compute the square of the distance of all Va towards one B vector component
   dd = (xa - double(xb[ib]))^2 + (ya - double(yb[ ib]))^2
   dmin = min( dd, imin)
   inda[ ib] = imin
endfor

return
end
