
;; Educated fit to solve issues with the brute force approach of get_grid_nodes

pro get_grid_nodes_2, nas_x, nas_y, xnode, ynode, $
                      alpha_opt, delta_opt, xcenter, ycenter, $
                      name=name, noplot=noplot, quick=quick, $
                      alpha_start=alpha_start, delta_start=delta_start

;;--------------------------------------------------
;; 1st guess with input values
if keyword_set(alpha_start) then alpha = alpha_start*!dtor else alpha = 0.d0
if keyword_set(delta_start) then delta = delta_start       else delta = 1.d0
x1 = (  nas_x*cos(alpha) + nas_y*sin(alpha))
y1 = ( -nas_x*sin(alpha) + nas_y*cos(alpha))

d = sqrt( (x1-avg(x1))^2 + (y1-avg(y1))^2)
w = where( d eq min(d))
x0 = x1[w[0]]
y0 = y1[w[0]]

if not keyword_set(noplot) then begin
   wind, 1, 1, /free, /large
   plot, x1, y1, psym=1, /iso, syms=0.5
   oplot, [x0], [y0], psym=4, thick=2, col=150
   ymin = min(y1)
   ymax = max(y1)
   yy=0.d0
   while yy le max(d) do begin
      oplot, minmax(x1), y0+[1,1]*yy
      oplot, minmax(x1), y0-[1,1]*yy
      yy += delta
   endwhile
   xx=0.d0
   while xx le max(d) do begin
      oplot, x0+[1,1]*xx, minmax(y1)
      oplot, x0-[1,1]*xx, minmax(y1)
      xx += delta
   endwhile
   oplot, x1, y1, psym=1, syms=0.5, thick=2
   
   legendastro, ['alpha = '+num2string(alpha*!radeg)+" deg", $
                 'delta = '+num2string(delta)], box=0
   if keyword_set(quick) then return
endif

;;--------------------------------------------------
;; Final fit on integer nodes
x1 = 1.d0/delta*(  nas_x*cos(alpha) + nas_y*sin(alpha))
y1 = 1.d0/delta*( -nas_x*sin(alpha) + nas_y*cos(alpha))
xnode = round(x1)
ynode = round(y1)

;; Use grid fit to find the true best value of alpha and delta
grid_fit_5, xnode, ynode, nas_x, nas_y, delta_opt, alpha_rot_deg, xcenter, ycenter, /nowarp, /noplot
;; update for the plot
alpha_opt = alpha_rot_deg*!dtor
x1 = 1./delta_opt*(  nas_x*cos(alpha_opt) + nas_y*sin(alpha_opt))
y1 = 1./delta_opt*( -nas_x*sin(alpha_opt) + nas_y*cos(alpha_opt))

if not keyword_set(noplot) then begin
   xra = minmax(xnode)+[-1,1]
   yra = minmax(ynode)+[-3,5]
   plot, x1, y1, psym=1, /iso, xra=xra, yra=yra, /xs, /ys, /nodata
   if keyword_set(name) then xyouts, x1, y1, name, /data

   xmin = min(xnode)-1
   xmax = max(xnode)+1
   ymin = min(ynode)-1
   ymax = max(ynode)+1
   for i=xmin, xmax do oplot, [1,1]*i, [ymin, ymax]
   for i=ymin, ymax do oplot, [xmin,xmax], [1,1]*i
   oplot, xnode, ynode, col=250, psym=4, thick=2
   oplot, x1+xcenter, y1+ycenter, psym=1, thick=2, col=70
   legendastro, ['Alpha [deg] = '+strtrim( string(alpha_opt*!radeg,format="(F6.2)"), 2), $
                 "Delta [arcsec] ="+strtrim( string(delta_opt, format="(F5.2)"),2)], box=0, /right
   legendastro, ['Input Nasmyth offsets', 'Integer nodes'], col=[70,250], psym=[1,4], textcol=[0,250], box=0
endif

end
