function otf_pointing_fit_angle, x, y, flag, signe=signe, min=min, max=max, check=check, status=status, showme=showme

;
; the rotation angle is fitted in minimising the speed of y, which is supposed
; to be the slowest coordinate
;
; INPUTS
;       ofs_az : data.ofs_az
;       ofs_el : data.ofs_el
;        flag  : data.flag[w1[0]]
;
; KEYWORDS 
;     min     : minimal value of the rotation angle to consider
;     max     : maximal value of the rotation angle to consider   
;     check   : checking that fitting an angle is needed (that the scan
;               is not already "straigh")
;
;     status  : indicate the quality of the scan
;                = 0  : angle ok
;                = -1 : bad fit
;     showme  : show some plot (to be selected along with status)
;
;
; 

;; symmetry along the two axis --> angle in 0 to pi/2
;;__________________________________________________________
amin = 0.
if keyword_set(min) then amin = min
amax = !dpi/2.   
if keyword_set(max) then amax = max
sens=1.
if keyword_set(signe) then sens = signe

;; check if a fit is needed
;;_________________________________________________________
criterion = 1.
if keyword_set(check) then begin
   cmin = otf_pointing_check_angle(x, y, flag, amin, showme=showme, scantype='otf_diagonal')
   cmax = otf_pointing_check_angle(x, y, flag, amax, showme=showme, scantype='otf_diagonal')
   criterion = min([cmin, cmax])
endif

;; perform the fit if needed
;;________________________________________________________
if criterion gt 1d-3 then begin
   ;; start fitting
   ;;-----------------------------------------
   
   ;; first targeting a precision of 1/32 degree
   coarse_reso = 0.03125*!dtor
   na = long( (amax-amin)/coarse_reso)
   angles = lindgen(na)*coarse_reso + amin
   vy_tab = dblarr(na)
   
   ;; selecting representative samples (on subscan, far from
   ;; inter-subscan interval)
   ;; subscan begins end ends
   w_ok = where(flag lt 1, nok)
   nsp = n_elements(y)
   otf_pointing_flag_subscan, x[w_ok], y[w_ok], flag_scan, i_begs, i_ends_az, i_ends_el, scantype='otf_diagonal'
   w_on = w_ok[where(flag_scan lt 1)]

   
   if i_begs[0] gt i_ends_az[0] then i_begs=[0, i_begs]
   idebs = w_ok[i_begs]
   ndebs = n_elements(idebs)    
   ss_flag = lonarr(nsp)+1L
   ll = long(idebs-shift(idebs,1))
   ll = ll[1:*]
   ss_length = median(ll)
   ;;for iss=0, ndebs-2 do ss_flag[idebs[iss]+0.25*ss_length:idebs[iss]+0.75*ss_length] = 0L 
   ;; 1iere solution debug
   ;; ss_flag[w_on]=0L
   ;; for iss=0, ndebs-2 do ss_flag[idebs[iss]:idebs[iss]+0.15*ss_length] = 1L
   ;; ifins = w_ok[i_ends_az]
   ;; nfins = n_elements(ifins) 
   ;; for iss=1, nfins-1 do ss_flag[ifins[iss]-0.15*ss_length:ifins[iss]] = 1L
   ;; 2ieme solution debug 
   for iss=0, ndebs-2 do if abs((ll[iss]-ss_length)/ss_length) lt 0.15 then ss_flag[idebs[iss]+0.25*ss_length:idebs[iss]+0.75*ss_length] = 0L 

   w_on = where(ss_flag lt 1L)
   

   for i=0,na-1 do begin
     
      yy=sens*sin(angles[i])*x+cos(angles[i])*y
      vyy = deriv(yy)*!nika.f_sampling ;
      vyy_mean = mean(abs(vyy[w_on]))
      vy_tab[i]=vyy_mean
      
   endfor

   vymin = min(vy_tab, imin)
   angle = angles[imin]

   ;;plot,angles/!dtor, vy_tab
   ;;stop
   
   if keyword_set(status) then begin
      criterion = otf_pointing_check_angle(x, y, flag)
      if criterion gt 1d-3 then begin
         status=-1
         print,"OTF SCAN FIT ANGLE >> bad fit"
      endif else status=0
   endif
   
;; no fit needed
;;------------------------------------------------------------------------------------   
endif else if cmin le cmax then angle = amin else angle = amax


return, angle

end
