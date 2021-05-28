PRO gen_x_y_map,map,x,y, centered = centered

Nx = (size(map))(1)
Ny = (size(map))(2)

ind = lindgen(Nx,Ny)
x = ind mod Nx
y = ind/Nx

if keyword_set(centered) then begin
   xc = (Nx-1)/2
   yc = (Ny-1)/2
   x = x-xc
   y = y-yc
endif

END
