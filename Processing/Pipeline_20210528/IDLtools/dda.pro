function dda,  z, omega_M, omega_L, H

;H in km/s/Mpc

; calcoliamo le distanze di diametro angolare-------------------
  Ez=sqrt(omega_M*((1+z)^3.)+omega_L)   ;|
                                ;|
  q=0.5*(omega_M-2*omega_L)     ;|
  c=299792.458                  ;km/s                                  ;|
  D=dblarr(n_elements(z))       ;|
                                ;|
  for i=0,n_elements(z)-1 do begin      ;|
     Dh=c/H                             ;|
     x=findgen(50001)*(z(i)/50000)      ;|
     E=sqrt((omega_M*((1+x)^3))+omega_L) ;|
     f=1./E                              ;|
     Dc=int_tabulated(x,f)               ;|
     D[i]=Dh*Dc/(1+z(i))                 ;|
  endfor                                 ;|
;---------------------------------------------------------------
  dEz=[[D], [Ez]]

  return, dEz
end
