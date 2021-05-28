FUNCTION    lf_sin_fit,vec,flaggal,step,nfcoef,nocount=nocount, coefg1 = coefg1, scoeff =scoeff


;+
; NAME:
;  lf_sin_fit  
; PURPOSE:
; use Juan Macias Perez fitting method with sin and cos
; inputs : vec (timeline)
;         flaggal : vector of galactic flags, 1 if inside galaxy
;         step : the length of each piece of timeline
;         nfcoef : the number of fitting function is 2*nfcoef+1
; result : the fitting vector, same dimension as vec
;
; CALLING SEQUENCE:
;   lf_sin_fit,vec,flaggal,step,nfcoef,nocount=nocount
; INPUT:
;  vec - original data
;  flaggal - flagging for interpolation
;  step - size of the data to be used at each baseline fitting
;  nfcoef - number of coefficients of the Fourier series 
; OUTPUT:
;
; KEYWORDS:
;  none
; EXAMPLES:
;  ndata = 4500*20L*4
;   x = dindgen(ndata)/double(ndata)*2*!dpi
;  data = cos(4 *30d*x)+sin(4 *40*x)
;  plot,data
;  plot,data,/xs
;  flag =dblarr(n_elements(data))
;  step = 9000
;  nfcoef=5
;  yfit=lf_sin_fit(data,flag,step,nfcoef)
;  plot,data-yfit
; RESTRICTIONS:
;  None.
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;  Written by Philippe Filliatre
;  Revised by JFMP, correct for jumps on the baseline
;-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ndata = n_elements(vec)
yfit = dblarr(ndata)


xdat = 2*!dpi*dindgen(step)/double(step)
if keyword_set(scoeff) then singlecoeff =scoeff else singlecoeff =0
 mf = create_matrix_fit(xdat,nfcoef=nfcoef, singlecoeff =singlecoeff)
nsteps=long((float(ndata)/float(step)) * 2-1) ; *2-1)
w1 =  dindgen(step/2)
w1 =  w1/(step/2)
w1 =  reverse(w1)
w2 =  dindgen(step/2)
w2 =  w2/(step/2)

;if not keyword_set(nocount) then plot,findgen(nsteps),findgen(nsteps),/nodata
;yfitdif =  0

FOR istep=0L, nsteps-1L DO BEGIN
;;;    removed for batch purpose(FXD)
;;;        if not keyword_set(nocount) then plots,istep,istep,psym=1
	ibg=(istep ne 0)
	ibd=(istep ne nsteps-1)

	IF ibd THEN BEGIN 
         ind1=istep*step/2L +lindgen(step)
        ENDIF ELSE BEGIN  
           ind1=istep*step/2 +lindgen(ndata-istep*step/2)     
         nnstep = n_elements(ind1)
         xdat = 2*!dpi*dindgen(nnstep)/double(nnstep)
          mf = create_matrix_fit(xdat,nfcoef=nfcoef,singlecoeff = singlecoeff)
        ENDELSE 
 	ind2=ind1 + step/2L
        indc =  istep*step/2+lindgen(step/2) + step/2
        indc1 = lindgen(step/2) + step/2
        indc2 =  lindgen(step/2)
;	ind=istep*step+lindgen(step)
;        center=(step/4)*ibg+lindgen((3*step/4-(step/4)*ibg)*ibd+(ndata-step/4+1)*(1-ibd))
;	indcenter=istep*step/2+center    
;                IF NOT ibd THEN  stop
        
	solve_ls,vec(ind1),mf,coefg1,yfitg1,flag=flaggal(ind1)
        IF ibg AND ibd THEN BEGIN 
 	 solve_ls,vec(ind2),mf,coefg2,yfitg2,flag=flaggal(ind2)
         yfit(indc) =  (w1 * yfitg1(indc1) +  w2 * yfitg2(indc2))/(w1 + w2)
        ENDIF ELSE BEGIN 
         yfit(ind1) = yfitg1
        ENDELSE 
;        IF istep NE 0 THEN yfitdif = yfitold - yfitg(center[0]-1)
;        yfit(ind) = yfitg
;       yfit(indcenter)=yfitg(center)  ; + yfitdif
;       IF istep NE nsteps-1 THEN yfitold = yfit(max(indcenter))
ENDFOR


RETURN,yfit

END
