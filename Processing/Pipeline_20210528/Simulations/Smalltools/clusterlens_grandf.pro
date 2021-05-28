
function clusterlens_grandf, x

;+
; aim: functional form of the deflection profile 
; biblio: Lewis&King 0512104 eq.~(26)
;-

nx = n_elements(x)
gf = x*0d
testok=1
if (nx eq 1) then begin
   if (x lt 0.) then testok=0
   ;; on fixe a zero au centre de l'amas
   if (x le 1e-8) then gf=0.
   if testok then begin 
      if (x le 1e-8) then gf=0. else begin
         if (x lt 1.) then gf=1d0/x*(alog(x/2d0) + alog(x/(1d0-sqrt(1d0-x^2)))/sqrt(1d0-x^2))
         if (x eq 1.) then gf=1d0-alog(2d0)
         if (x gt 1.) then gf=1d0/x*(alog(x/2d0) + (!dpi/2d0 - asin(1d0/x))/sqrt(x^2-1d0))
      endelse
   endif
endif else begin
   wneg = where(x lt 0.,co)
   if co then testok=0
   if testok then begin
      w0 = where(x lt 1d-10, co)
      if (co gt 0) then gf(w0)=0d0
      wlt1 = where(x gt 0. and x lt 1.,co) 
      if (co gt 0) then gf(wlt1)=1d0/x(wlt1)*(alog(x(wlt1)/2d0) + alog(x(wlt1)/(1d0-sqrt(1d0-x(wlt1)^2)))/sqrt(1d0-x(wlt1)^2))
      weq1 = where(x eq 1.,co) 
      if (co gt 0) then gf(weq1)=1d0-alog(2d0)
      wgt1 = where(x gt 1.,co) 
      if (co gt 0) then gf(wgt1)=1d0/x(wgt1)*(alog(x(wgt1)/2d0) + (!dpi/2d0 - asin(1d0/x(wgt1)))/sqrt(x(wgt1)^2-1d0))
   endif
endelse

if not(testok) then begin
   print,"unvalid x format"
   gf=-1
endif

return, gf

end
