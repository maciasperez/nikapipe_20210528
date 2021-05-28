
pro decouple, map_a, map_b, xmap, ymap, n_dec, theta1, theta2, $
              theta, chi, estim, ampl, hand=hand, mask=mask, $
              ntheta=ntheta, show=show, xc=xc, yc=yc, sigma_max=sigma_max, anim=anim

if not keyword_set(ntheta) then ntheta = 500
if not keyword_set(sigma_max) then sigma_max = 20.

nx = n_elements( map_a[*,0])
ny = n_elements( map_a[0,*])

if not keyword_set(mask) then mask = dblarr(nx,ny) + 1.0d0

if keyword_set(xc) then begin
   d = sqrt( (xmap-xc)^2 + (ymap-yc)^2)
   w0 = where( d eq min(d))
   iy0 = w0/nx
   ix0 = w0 - iy0*nx
   
   x1 = (ix0-n_dec)>0
   x2 = (ix0+n_dec)<(nx-1)
   y1 = (iy0-n_dec)>0
   y2 = (iy0+n_dec)<(nx-1)
endif else begin
   x1 = 0
   x2 = nx-1
   y1 = 0
   y2 = ny-1
endelse

theta = dindgen(ntheta)/(ntheta-1)*2*!dpi
estim = theta*0.0d0
ampl = theta*0.
chi  = theta*0.
sigma_x = theta*0.
sigma_y = theta*0.

nx_disp = nx*4
ny_disp = ny*4

wind, 1, 1, /free, /large
for i=0L, ntheta-1 do begin
   map = mask * (cos(theta[i])*map_a + sin(theta[i])*map_b)

   ;;fit = mpfit2dpeak( map[x1:x2,y1:y2], a, xmap[x1:x2,0], ymap[0,y1:y2], /tilt, /gauss, chisq=chisq)
   fit = gauss2dfit( map[x1:x2,y1:y2], a, reform(xmap[x1:x2,0]), reform(ymap[0,y1:y2]))
   chisq = total( (fit-map)^2)

   ux = (xmap-a[4])*cos(a[6]) - (ymap-a[5])*sin(a[6])
   uy = (xmap-a[4])*sin(a[6]) + (ymap-a[5])*cos(a[6])
   beam_pict = a[0] + a[1]*exp(-ux^2/(2.*a[2]^2)-uy^2/(2.*a[3]^2))

   if keyword_set(anim) then begin
      !p.multi=[0,2,2]
      dispim_bar, rebin( map_a, nx_disp, ny_disp), /noc, title='A'
      dispim_bar, rebin(map_b, nx_disp, ny_disp), /noc, title='B'
      dispim_bar, rebin( map, nx_disp, ny_disp), /noc, title='1, theta = '+strtrim(theta[i]*!radeg,2)
      dispim_bar, rebin(beam_pict, nx_disp, ny_disp), /noc, title='fit, i='+strtrim(i,2)
      !p.multi=0
      if keyword_set(hand) then begin
         cont_plot
      endif else begin
      wait, 0.02
   endelse         
   endif

   ampl[i] = a[1]
   chi[i] = chisq
   sigma_x[i] = a[2]
   sigma_y[i] = a[3]

   estim[i] = a[1]/sqrt(chisq)
   estim[i] = a[1]/chisq^2
   ;;estim[i] = a[1]^2/chisq
   ;;estim[i] = a[1]^2/chisq^2
endfor

;; Cut out crazy values
estim1 = estim
w = where( sigma_x gt sigma_max, nw)
if nw ne 0 then estim1[ w] = 0.
w = where( sigma_y gt sigma_max, nw)
if nw ne 0 then estim1[ w] = 0.

ampl_max = max( abs(map_a) + abs( map_b))
w = where( ampl gt ampl_max, nw)
if nw ne 0 then estim1[ w] = 0.

theta_width = 45*!dtor

;1st max

x1 = where( estim1 eq max(estim1), nw)
theta1 = (theta[x1])[0]
w2 = where( cos(theta-theta1) le cos(theta_width))
w22 = where( estim1[w2] eq max( estim1[w2]))
x2 = w2[w22]

theta1 = (theta[x1])[0]
theta2 = (theta[x2])[0]

if keyword_set(show) then begin
   wind, 1, 1, /free, /large
   !p.multi=[0,2,2]
   plot, theta*!radeg, ampl, title='ampl', yra=yra_ampl
   oplot, [1,1]*28, [-1,1]*1e6
   oplot, [1,1]*78, [-1,1]*1e6
   plot, theta*!radeg, chi, title='chi'
   plot, theta*!radeg, estim, title='estim', yra=[0, max(estim)], /ys
   oplot, [1,1]*28, [-1,1]*1e6
   oplot, [1,1]*78, [-1,1]*1e6
   oplot, theta[x1]*!radeg, estim[x1], psym=4, col=250, thick=2
   oplot, theta[x2]*!radeg, estim[x2], psym=4, col=250, thick=2
   !p.multi=0

   wind, 1, 1, /free
   !p.multi=[0,2,2]
   dispim_bar, rebin( map_a, nx_disp, ny_disp), /noc, title='A'
   dispim_bar, rebin(map_b, nx_disp, ny_disp), /noc, title='B'
   dispim_bar, rebin( cos(theta1)*map_a + sin(theta1)*map_b, nx_disp, ny_disp), /noc, title='1'
   dispim_Bar, rebin( cos(theta2)*map_a + sin(theta2)*map_b, nx_disp, ny_disp),/noc,title='2'
   !p.multi=0
endif

end
