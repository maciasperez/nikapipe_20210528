function otf_pointing_check_angle, x, y, flag, angle, showme=showme, scantype=scantype

;  checking that a OTF scan is "straightened" after a rotation through
;  angle
;
;  When a OTF scan is "straight", the subscans are perpendicular to
;  the slow coordinate axis.
;  Here we check that the stddev of the projection onto the slowest
;  coordinate for each subscan is minimal
;
;

  
  scant = 'otf_azimuth'
  if keyword_set(scantype) then scant = scantype 

  ;; selecting a large part of the on-subscan samples
  w_ok = where(flag lt 1, nok)
  nsp = n_elements(y)
  otf_pointing_flag_subscan, x[w_ok], y[w_ok], flag_scan, i_begs, i_ends_az, i_ends_el, scantype=scantype
  w_on = w_ok[where(flag_scan eq 0)]
  if i_begs[0] gt i_ends_az[0] then i_begs=[0, i_begs]
  idebs = w_ok[i_begs]
  ndebs = n_elements(idebs)

   ss_flag = lonarr(nsp)
   ll = long(idebs-shift(idebs,1))
   ss_length = median(ll[1:*])
   for iss=1, ndebs-2 do ss_flag[idebs[iss]+0.15*ss_length:idebs[iss]+0.65*ss_length] = iss 
   w_on = where(ss_flag gt 0)

   if keyword_set(showme) then begin
      window,0
      index = lindgen(nsp)
      plot, index, y, title = "y timeline with selected samples in red", col=0
      oplot,index[w_on], y[w_on], col=250, psym=1
   endif

   ;; generating a map of the pointing projected to the y-coordinate
   ;; (slow coordinate)

   
   xrot = cos(angle)*x + sin(angle)*y
   yrot = -sin(angle)*x + cos(angle)*y

   xbornes = minmax(xrot)
   ybornes = minmax(yrot)
         
   xx = xrot - xbornes[0]
   yy = yrot - ybornes[0]
         
   res=0.5
   nx = ceil((xbornes[1]-xbornes[0])/res) < 1000
   ny = ceil((ybornes[1]-ybornes[0])/res) < 1000

; To avoid too big arrays (FXD)
   res = ((xbornes[1]-xbornes[0])/nx) > ((ybornes[1]-ybornes[0])/ny)
   nx = ceil((xbornes[1]-xbornes[0])/res)+1
   ny = ceil((ybornes[1]-ybornes[0])/res)+1
         
   ix   = long( ( xx)/res)
   iy   = long( ( yy)/res) 
   ipix = ix + iy*nx
         
   angles = atan(yy/xx)
         
   ;;pmap = fltarr(nx, ny)
   ymap = fltarr(nx, ny)
   smap = intarr(nx, ny)
   for isp = 0, nsp-1 do begin
      ;;pmap[ipix[isp]] = 1.
      ymap[ipix[isp]] = sqrt(xx[isp]^2+yy[isp]^2)*sin(angles[isp]) 
      smap[ipix[isp]] = ss_flag[isp]
   endfor
   
   if keyword_set(showme) then begin
      window,1
      dispim_bar, ymap,/nocont, /aspect, title = "pointing map projected onto the y-coordinate"
      window,2
      dispim_bar, smap,/nocont, /aspect, title = "subscan map" 
   endif
   
   ;; computing stddev of the projection for each subscan
   nss = ndebs-1
         
   criterion = 0.
   for iss = 1, nss-2 do begin
      w=where(smap eq iss, co)
      if co gt 0 then criterion += stddev(ymap[w])
   endfor
   
   ;;stop
   

return, criterion

end
