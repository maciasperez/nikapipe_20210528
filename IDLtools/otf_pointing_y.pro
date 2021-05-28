function otf_pointing_y, t, allinfo, last_value=last_value, sharpstep=sharpstep, chatty=chatty, debug=debug

;+
; AIM :  generate a template of the y coordinate (elevation-like)
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
;     y : el pointing
;
; KEYWORDS:
;    last_value : value of the last sample (if not given, the last
;    ss is interpolated) 
; 
; HISTORIC
; LP, 2014 May, 13th
;
;- 

  code = "IDLtools/otf_pointing_y >> "
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
  idebs = reform(allinfo.beg_index)>0  ; [FXD] sometimes can be negative
  a0 = reform(allinfo.amplitude)
  
  
;; account for dephasing
  tt = lindgen(nsp)+phase
  
;; initialisating output
  yy = dblarr(nsp)
  
;; flag
  ff = lonarr(nsp)
  
  i=0
  ibeg = 0
  iend = ibeg
;.r
  while (iend lt nsp) and (i lt nss-1) do begin
     if bavaz gt 0 then print,code,"subscan num ", i
     
;; on subscan
     ibeg = idebs[i]
     iend = min([ibeg+lss[i]-1,nsp-1])
     yy[ibeg:iend] = replicate(a0[i],lss[i])
     ff[ibeg:iend]=1
     
;; inter-subscan
     mylis = max([lis[i],idebs[i+1]-iend+1])
     
     if ((keyword_set(sharpstep)) or (mylis le 3)) then begin
;; sharp elevation step at the middle of the IS
        ;; petit prolongement au debut du IS
        deb_mi_is = ceil(mylis/2.)
        yy[iend+1:iend+deb_mi_is] = replicate(a0[i],deb_mi_is)
        ;; petit prolongement a la fin du IS
        fin_mi_is = floor(mylis/2.)
        yy[iend+deb_mi_is+1:iend+deb_mi_is+fin_mi_is] = replicate(a0[i+1],fin_mi_is)
     endif else begin
;; smoother elevation step (more like real pointing data)
        ;; petit prolongement au debut du IS
        deb_mi_is_1 = ceil(mylis/4.)
        deb_mi_is_2 = ceil(mylis/2.)
        yy[iend+1:iend+deb_mi_is_1] = replicate(a0[i],deb_mi_is_1)
        ;; petit prolongement a la fin du IS
        fin_mi_is = floor(mylis/2.)
        yy[iend+deb_mi_is_2+1:iend+deb_mi_is_2+fin_mi_is] = replicate(a0[i+1],fin_mi_is)
        ;; step with a hard slope (but not vertical)
        l_step = deb_mi_is_2-deb_mi_is_1
        ind = indgen(l_step)
        yy[iend+deb_mi_is_1+1:iend+deb_mi_is_2] = (a0[i+1]-a0[i])/l_step*ind + a0[i]
     endelse
     
     ff[iend+1:iend+mylis]=2
     
     i+=1
     if bavaz gt 0 then print,code,iend," sur ", nsp
  endwhile
;end
  
  
;; le dernier subscan+intersubscan peut ne pas etre complet: on teste
  ibeg = idebs[i]
  iend = min([ibeg+lss[nss-1]-1,nsp-1])
  
;; dernier subscan
  yy[ibeg:iend] = replicate(a0[i],iend-ibeg+1)
  ff[ibeg:iend]=1
  
;; dernier inter-subscan
  if ((lis[i] gt 0) and (iend+1 lt nsp)) then begin  
     mylis = nsp-1-iend
     yy[iend+1:iend+mylis] = replicate(a0[i],mylis)
     
     ff[iend+1:iend+mylis] = 2
     
  endif
  
;plot,tt,yy,col=0,xr=[nsp-500,nsp-phase],/xs
  
  
  
  
  return,yy
end
