
function clusterlens_gradtmap, Ty, angsize, pixsize
;+
; map of a pure gradient 
;-
nx=angsize/pixsize
vecy=(dindgen(nx+1)*pixsize - 0.5*angsize);*!dpi/180./60.
y=(dblarr(nx+1)+1d0)#vecy
gmap = Ty*y

return,gmap

end

