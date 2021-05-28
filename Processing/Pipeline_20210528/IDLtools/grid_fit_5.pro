
;; fitte la meilleure rotation, grossissement et translation pour aller de
;; x_pix, y_pix a xc, yc

pro grid_fit_5, x_pix, y_pix, xc, yc, delta, alpha_deg, nas_center_x, nas_center_y, xc_0, yc_0, kx, ky, $
                xfit, yfit, $
                n_iter=n_iter, degree=degree, noplot=noplot, title=title, dir=dir, ps=ps, png=png, $
                raw_x_offset=raw_x_offset, raw_y_offset=raw_y_offset, nowarp=nowarp, names=names, $
                distance=distance, charsize = charsize, xtitle = xtitle, ytitle = ytitle, $
                position=position

if not keyword_set(dir) then dir="."
if not keyword_set(title) then title=''
if keyword_set(position) then noerase = 1

nc   = n_elements(xc)

xc_0 = !undef ; place holder
yc_0 = !undef ; place holder

;; Fit
a = dblarr(4,2*nc)
a[0,0:nc-1] = 1
a[1,nc:*]   = 1
a[2,0:nc-1] =  x_pix
a[2,nc:*]   =  y_pix
a[3,0:nc-1] = -y_pix
a[3,nc:*]   =  x_pix

ata = transpose(a)##a
atd = transpose(a)##[ xc, yc]

atam1     = invert(ata)
s         = atam1##atd
delta     = sqrt( s[2]^2+s[3]^2)
x         = s[2]/delta
y         = s[3]/delta
alpha     = atan(y,x)

alpha_deg = alpha*!radeg
cosalpha = cos(alpha)
sinalpha = sin(alpha)

;; (el, co-el) pointing offset
raw_x_offset = s[0]
raw_y_offset = s[1]

;; If all the pointing offset is due to Nasmyth alignment:
nas_center_x = 1.0d0/delta*( -cosalpha*s[0] - sinalpha*s[1])
nas_center_y = 1.0d0/delta*(  sinalpha*s[0] - cosalpha*s[1])

xfit = delta*( (x_pix-nas_center_x)*cosalpha - (y_pix-nas_center_y)*sinalpha)
yfit = delta*( (x_pix-nas_center_x)*sinalpha + (y_pix-nas_center_y)*cosalpha)

distance = sqrt( (xfit-xc)^2 + (yfit-yc)^2)

if not keyword_set(noplot) then begin
   xra = min(xc) + [-0.1, 1.1]*(max(xc)-min(xc))
   yra = min(yc) + [-0.1, 1.1]*(max(yc)-min(yc))

   xra = min(xc) + [-0.1, 1.1]*(max(xc)-min(xc))
   yra = min(yc) + [-0.1, 1.1]*(max(yc)-min(yc))
   plot,  xc, yc, psym=1, /iso, xra=xra, yra=yra, /xs, /ys, title=title+'Sky (Az,el)', $
          xtitle = xtitle, ytitle = ytitle, position=position, noerase=noerase, charsize=charsize
   oplot, xfit, yfit, psym=4, col=250
   if keyword_set(names) then xyouts, xc, yc, strtrim(names,2), charsize = charsize
   legendastro, ['(xc,yc)', 'fit(xpix, ypix)'], col=[!p.color, 250], textcol = [!p.color, 250], psym=[1, 4], box=0, chars=charsize
   legendastro, ['deta_out'+num2string(delta), 'alpha_rot_deg '+num2string(alpha_deg)], box=0, /right, chars=charsize
endif

end
