function create_matrix_fit,vectx,nfcoef=nfcoef,userfunct=userfunct,flag=flag, singlecoeff = singlecoeff
;+
; NAME:
;  create_matrix_fit
; PURPOSE:
;!$ function to generate a fitting matrix to resolve y = Fa
; we include Fourier series
; we include also user's provided functions
; CALLING SEQUENCE:
;  
; INPUT:
;  vectx - vector of the form 2*pi*findgen(n)
; OUTPUT:
;  matrixf = matrix such that y = Fa
; KEYWORDS:
;  nfcoef = number of non zero order Fourier modes
;  userfunct = predefined user functions same size of vectx
;  flag = flagging of the data good data eq 0, bad otherwise
; EXAMPLES:
;   
; RESTRICTIONS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;  Written by Juan Macias Perez and Xavier Desert, September 2001
;-
 if (n_params() lt 1) then begin
  print, "The subroutine should be called as follows:"
  print, "matrixf=create_matrix_fit(x,nfcoef=nfcoef,userfunct=userfunct)"
 endif
 if keyword_set(flag) then begin
  listok = where(flag eq 0,nt)
  xused = vectx(listok)
 endif else begin
  nt = (size(vectx))[1]
  xused = vectx  
 endelse
 ncoef = 1
 if keyword_set(nfcoef) then begin
  ncoef = ncoef+2*nfcoef
  if keyword_set(singlecoeff) then ncoef = 3
 endif
 if keyword_set(userfunct) then begin
  ncoef = ncoef+ (size(userfunct))[2]
 endif
 matrixf = dblarr(ncoef,nt)
 nind = 0
 matrixf(nind,*)=1.d0
 if keyword_set(nfcoef) then begin
  for i=1,nfcoef do begin
   if keyword_set(singlecoeff) then begin
    if i eq singlecoeff then begin 
      nind = nind+1
      matrixf(nind,*)=cos(xused*double(i))
      nind=nind+1
      matrixf(nind,*)=sin(xused*double(i))
    endif 	 
  endif else begin 	
    nind = nind+1
    matrixf(nind,*)=cos(xused*double(i))
    nind=nind+1
    matrixf(nind,*)=sin(xused*double(i))
   endelse	
  end
 endif
 if keyword_set(userfunct) then begin
  nind = nind+1
  if keyword_set(flag) then begin
   matrixf(nind:*,*) = userfunct(*,listok)
  endif else begin
   matrixf(nind:*,*) = userfunct
  endelse
 endif
 return, matrixf
end












