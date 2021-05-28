function clusterlens_cl2rmsgrad, clfile, lmax, convert_cl_to_microk2
;+
; calcul la rms du gradient d'une observable a partir de son Cl
;-
cl=readclfits(clfile)
ell=dindgen(lmax+1)
rmsgrad = sqrt(total(ell*(ell+1)*(2d*ell+1d)/4d/!dpi*cl(0:lmax)*convert_cl_to_microk2))/180./60.*!dpi

return, rmsgrad
end

