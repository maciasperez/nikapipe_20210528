function otf_pointing_x, t, allinfo, last_value=last_value, chatty=chatty, debug=debug

;+
; AIM : generate a template of the x coordinate (azimuth-like)
; pointing timeline from a detailed description of each subscan
;
; INPUT : 
;     t : sample table
;     allinfo : structure giving a complete description of the az pointing in the form :
;     allinfo.ss_length : length of each subscan (ss)
;     allinfo.is_length : length of each inter-subscan interval (is)
;     allinfo.beg_index : index of each subscan beginning
;
; OUTPUT :
;     x : az pointing timeline
;
; KEYWORDS:
;    last_value : value of the last sample (if not given, the last
;    ss is interpolated) 
; 
; HISTORIC
; LP, 2014 May, 2nd
;
;- 


  code = "IDLtools/otf_pointing_x >> "
  bava = 0
  if keyword_set(chatty) then bava=1
  bavaz = 0
  if keyword_set(debug) then bavaz=1


;; number of subscan
  nss = n_elements(allinfo)
  
;; number of sample to a complete subscan 
  phase = allinfo[0].beg_index
  
;; number of sample
  nsp = n_elements(t)
  

;; reforming allinfo
  lss = reform(allinfo.ss_length)
  lis = reform(allinfo.is_length)
  idebs = reform(allinfo.beg_index)
  a0 = reform(allinfo.amplitude)
  signe = a0/abs(a0)
;a0=abs(a0)
  
;; account for dephasing
  tt = lindgen(nsp)+phase
  
;; initialisating output
  xx = dblarr(nsp)
  
  
;; first subscan (could be partial)
;i0 = lss[0]-phase 
;y[0:i0-1] = signe[0]*(a0[0]/lss[0]*xx[0:i0-1] - a0[0]/2.)
  
  
  i=0
  ibeg = 0
  iend = ibeg
;b=0
;.r
  while (iend lt nsp) and (i lt nss-1) do begin
     if bavaz gt 0 then print,code,"subscan num ", i
;; on subscan
     ibeg = idebs[i]>0
     iend = min([ibeg+lss[i]-1,nsp-1])
;print,(a0[i+1]-a0[i])/lss[i]
;print,a0[i]
     ind=lindgen(lss[i])
     xx[ibeg:iend] = ((a0[i+1]-a0[i])/lss[i]*ind + a0[i])
;; inter-subscan
     mylis = max([lis[i],idebs[i+1]-iend+1])
     xx[iend+1:iend+mylis] = replicate(a0[i+1],mylis)
;b = b + lis[i] + lss[i]; nb de samples ecrits 
     i+=1
     if bavaz gt 0 then print,code,iend," sur ", nsp
  endwhile
;end


;; le dernier subscan+intersubscan peut ne pas etre complet: on teste
  ibeg = idebs[i]>0
  iend = min([ibeg+lss[nss-1]-1,nsp-1])
  
  mylss = min([lss[i],iend-ibeg+1])
  ind=lindgen(mylss)
  ampli=1.
  if keyword_set(last_value) then ampli = last_value-a0[i] else begin
     med_a0 = median(abs(a0))
     signe=-2.*a0[i]/abs(a0[i])
     ampli = signe*med_a0
     signe=-1.*a0[i]/abs(a0[i])
     pentes = fltarr(nss-1)
     for k = 0,nss-2 do pentes[k] = abs((a0[k+1]-a0[k]))/lss[k]
     pente = median(pentes)
     p = signe*pente
  endelse
  ;; LP MODIF JUNE
  ;;xx[ibeg:iend] = (ampli/mylss*ind + a0[i])
  xx[ibeg:iend] = (p*ind + a0[i])

  if ((lis[i] gt 0) and (iend+1 lt nsp)) then begin  
;; inter-subscan
     mylis = nsp-1-iend
     xx[iend+1:iend+mylis] = replicate(ampli/2.,mylis)
;b = b + lis[i] + lss[i]; nb de samples ecrits 
  endif
  
;plot,tt,t,xr=[16500,nsp],yr=[-210,210]
;oplot,tt,xx,col=250
  

  ;;stop
  

  return,xx
end
