
;; Brute force fit to determine which grid nodes match nasmyth offsets

pro get_grid_nodes, nas_x, nas_y, xnode, ynode, alpha_opt, delta_opt, xcenter, ycenter, name=name, noplot=noplot, $
                    alpha_start=alpha_start, d_alpha_min=d_alpha_min, d_alpha_max=d_alpha_max, d_alpha_step=d_alpha_step, $
                    delta_start=delta_start, d_delta_min=d_delta_min, d_delta_max=d_delta_max, d_delta_step=d_delta_step, $
                    quick=quick


;; 1st guess by eye, it's best after all
if keyword_set(quick) then begin
   if keyword_set(alpha_start) then alpha = alpha_start*!dtor else alpha = 0.d0
   if keyword_set(delta_start) then delta = delta_start       else delta = 1.d0

   x1 = (  nas_x*cos(alpha) + nas_y*sin(alpha))
   y1 = ( -nas_x*sin(alpha) + nas_y*cos(alpha))
   d = sqrt( (x1-avg(x1))^2 + (y1-avg(y1))^2)
   w = where( d eq min(d))
   x0 = x1[w[0]]
   y0 = y1[w[0]]

   wind, 1, 1, /free, /large
   !p.multi=[0,2,2]
   plot, nas_x, nas_y, psym=1, thick=2, syms=0.5, /iso, xtitle='Nasmyth x', ytitle='Nasmyth y'
   for i=-500, 500, 10 do begin
      oplot, [1,1]*i, [-1,1]*1e10
      oplot, [-1,1]*1e10, [1,1]*i
   endfor

;; Display beam offsets and overplot a grid to guide the eye on the
;; present rotation
   plot, x1, y1, psym=1, /iso, syms=0.5
   oplot, [x0], [y0], psym=4, thick=2, col=150
   for i=-50, 50 do begin
      oplot, x0+[i,i]*delta, [-1,1]*1e10
      oplot, [-1,1]*1e10, y0+[i,i]*delta
   endfor
   oplot, x1, y1, psym=1, syms=0.5, thick=2
   legendastro, ['alpha = '+num2string(alpha*!radeg)+" deg", $
                 'delta = '+num2string(delta)], box=0

   return
endif

if not keyword_set(alpha_start)  then alpha_start  = 45.
if not keyword_set(d_alpha_min)  then d_alpha_min  = -20
if not keyword_set(d_alpha_max)  then d_alpha_max  =  45
if not keyword_set(d_alpha_step) then d_alpha_step = 0.1
if not keyword_set(delta_start)  then delta_start = 10. ; arcsec
if not keyword_set(d_delta_min)  then d_delta_min  = -8 ; arcsec
if not keyword_set(d_delta_max)  then d_delta_max  =  5
if not keyword_set(d_delta_step) then d_delta_step = 0.1

alpha_start = alpha_start*!dtor
d_alpha_min = d_alpha_min*!dtor
d_alpha_max = d_alpha_max*!dtor
d_alpha_step = d_alpha_step*!dtor

d_alpha = d_alpha_min
d_delta = d_delta_min
dmin = 1e6

;; Brute force search for the nodes that correspond to the Nasmyth offsets
while d_alpha lt d_alpha_max do begin

   d_delta = d_delta_min
   while d_delta lt d_delta_max do begin
      delta = delta_start + d_delta
      alpha = alpha_start + d_alpha
      x1 = 1./delta*(  nas_x*cos(alpha) + nas_y*sin(alpha))
      y1 = 1./delta*( -nas_x*sin(alpha) + nas_y*cos(alpha))

      dx = x1 - round(x1)
      dy = y1 - round(y1)
      d = total( sqrt( dx^2 + dy^2))
      if d lt dmin then begin
         dmin = d
         d_alpha_opt = d_alpha
         d_delta_opt = d_delta
      endif
      
      d_delta += d_delta_step
   endwhile
   d_alpha += d_alpha_step
endwhile

;; Nodes
delta_opt = delta_start + d_delta_opt
alpha_opt = alpha_start + d_alpha_opt

x1 = 1./delta_opt*(  nas_x*cos(alpha_opt) + nas_y*sin(alpha_opt))
y1 = 1./delta_opt*( -nas_x*sin(alpha_opt) + nas_y*cos(alpha_opt))

xnode = round(x1)
ynode = round(y1)

message, /info, "fix me:"
w = where( y1 ge -4)
help, w

x1 = x1[w]
y1 = y1[w]
nas_x = nas_x[w]
nas_y = nas_y[w]
xnode = xnode[w]
ynode = ynode[w]

;   wind, 1, 1, /free, /large
plot, x1, y1, psym=1, /iso, xra=xra, yra=yra, /xs, /ys
if keyword_set(name) then xyouts, x1, y1, name, /data

xmin = min(xnode)-1
xmax = max(xnode)+1
ymin = min(ynode)-1
ymax = max(ynode)+1
for i=xmin, xmax do oplot, [1,1]*i, [ymin, ymax]
for i=ymin, ymax do oplot, [xmin,xmax], [1,1]*i
oplot, x1, y1, psym=1, thick=2
;oplot, xnode-xcenter, ynode-ycenter, col=70, psym=4, thick=2

stop



;; Use grid fit to find the true best value of alpha and delta
grid_fit_5, xnode, ynode, nas_x, nas_y, delta_opt, alpha_rot_deg, xcenter, ycenter, /nowarp, /noplot
;; update for the plot
alpha_opt = alpha_rot_deg*!dtor
x1 = 1./delta_opt*(  nas_x*cos(alpha_opt) + nas_y*sin(alpha_opt))
y1 = 1./delta_opt*( -nas_x*sin(alpha_opt) + nas_y*cos(alpha_opt))
;xnode = round(x1)
;ynode = round(y1)

if not keyword_set(noplot) then begin
   xra = minmax(xnode)+[-1,1]
   yra = minmax(ynode)+[-3,5]
   wind, 1, 1, /free, /large
   plot, x1, y1, psym=1, /iso, xra=xra, yra=yra, /xs, /ys
   if keyword_set(name) then xyouts, x1, y1, name, /data

   xmin = min(xnode)-1
   xmax = max(xnode)+1
   ymin = min(ynode)-1
   ymax = max(ynode)+1
   for i=xmin, xmax do oplot, [1,1]*i, [ymin, ymax]
   for i=ymin, ymax do oplot, [xmin,xmax], [1,1]*i
   oplot, x1, y1, psym=1, thick=2
   oplot, xnode-xcenter, ynode-ycenter, col=250, psym=4, thick=2

   legendastro, ['Alpha [deg] = '+strtrim( string(alpha_opt*!radeg,format="(F6.2)"), 2), $
                 "Delta [arcsec] ="+strtrim( string(delta_opt, format="(F5.2)"),2)], box=0, /right
   legendastro, ['Input Nasmyth offsets', 'Integer nodes'], col=[0,250], psym=[1,4], textcol=[0,250], box=0
endif

end
