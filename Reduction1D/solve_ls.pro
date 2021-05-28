pro solve_ls,inputy,matrixf,outa,outyfit,flag=flag,mftf=mftf
;+
; NAME:
;  solve_ls
; PURPOSE:
; function to generate a fitting matrix to resolve y = Fa+n
; NOTE: the system to solve is Fty=FtFa
; we include Fourier series
; we include also user's provided functions
; CALLING SEQUENCE:
;  
; INPUT:
;  inputy - vector of dataxb
;  matrixf - matrix for solving linear system
; OUTPUT:
;  outa - solution of the linear system
;  outyfit - matrixf##a
; KEYWORDS:
;  flag = flag for good data when 0 bad data otherwise
; EXAMPLES:
;  x = 2* !dpi * dindgen(4096)/4096.d0
;  y = 3.* randomn(seed,4096)+ 12.* cos(3.*x)+20. 
;  matrixf = create_matrix_fit(x,nfcoef=300)
;  solve_ls,y,matrixf,outa,yfit
; RESTRICTIONS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;  Written by Juan Macias-Perez and Xavier Desert, September 2001
;-                                                                             
  if (n_params() lt 4) then begin
   print, "The subroutine should be called as follows:"
   print, "solve_ls,inputy,matrixf,outa,outyfit"
  endif
; checking for flags
  if keyword_set(flag) then begin
   listok = where(flag eq 0, nok)
   IF nok NE 0 THEN BEGIN 
      yused = inputy(listok)
      mf = matrixf(*,listok)
   ENDIF ELSE BEGIN 
      message, /info, ' No real valid data , take the whole set for fitting '
      yused=inputy 
      mf = matrixf
   ENDELSE 
  endif else begin
   yused=inputy 
   mf = matrixf
  endelse
; solving the linear system - by default LU
 if keyword_set(mftf) then begin
  ftf = mftf
 endif else begin 
  ftf = transpose(mf)##mf
 endelse
 ludc, ftf,index
 tfy = transpose(mf)##yused
 tfy = transpose(tfy)
 ;tfy = transpose(mf)#yused
 outa = lusol(ftf,index,tfy)
; think about other methods, I mean no lu methods ...
 
; calculate yfit from outa
 outyfit = matrixf##outa
; outyfit = matrixf#outa
 return
end











