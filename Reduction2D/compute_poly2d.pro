; Compute the polynomials (as defined by polywarp) at given points (x,y)
function compute_poly2d, x, y, p

n = n_elements(p[0, *])
a = x*0D
for i = 0, n-1 do begin
   for j = 0, n-1 do begin
      a = a+p[i, j]*(x^j)*(y^i)  ; j, i according to IDL help
   endfor
endfor
return, a
end
