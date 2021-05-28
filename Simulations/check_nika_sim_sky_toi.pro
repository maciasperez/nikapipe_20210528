
;; Take Uranus 220 scan to have realistic planet scan

;; Take A665 Ra dec to have typical pointing direction
;; A665                 EQ 2000 08:30:45.200  +65:52:55.000   LSR 0.000 FL 0.000
ra_source  = (8.0d0 + 30.0d0/60.0d0 + 45.2d0/3600)*!h2d
dec_source = 65.0d0 + 52.0d0/60.0d0 + 55.d0/3600d0

raw_dir  = "/Data/NIKA/Iram_Oct2011/Raw/OTF_Geometry/" ; don't forget the trailing "/"
file = 'd_2011_10_19_23h14m23_Uranus_220'
get_data, file, toi, az, el, w8, kidpar, dir=raw_dir, subscan=subscan, pfstr=pfstr, poly_didq=poly_didq
delvarx, toi, az, el

fp = mrdfits("/Data/NIKA/Iram_Oct2011/FocalPlaneGeometry/FPG_config_1_PF_v1.fits", 1)


;; Restrict to one matrix for now
wa = where( fp.matrix eq 'A', nkids)
fp = fp[wa]


;pfstr.actualaz : coordonnees du centre du telescope qui n'est pas forcement le centre du PF, ni la source
;pfstr.actualel : idem
az_tel = pfstr.actualaz
el_tel = pfstr.actualel ; a utiliser dans detcoord

;; save memory and refer everything to 1st bolo's pointing
y_0 = pfstr.yoffset/!arcsec2rad                     ; offset par rapport a la position de la source (el_tel-el_source)(t)
x_0 = pfstr.xoffset/!arcsec2rad * cos(el_tel*!dtor) ; pfstr.xoffset = (az_tel-az_source)(t)

;;;; Account for Xavier's pointing correction
;;x_0 = x_0 - fpc.x
;;y_0 = y_0 - fpc.y

fpc_x = 0.d0 ;  2.d0
fpc_y = 0.d0 ; -3.d0

LST = pfstr.lst*!radeg/!h2d

res_arcsec = 1.d0

wind, 1, 1, /free, /large
plot, x_0, y_0, /iso

xra = minmax(x_0) + [-1,1]*0.55*(max(x_0)-min(x_0))
yra = minmax(y_0) + [-1,1]*0.55*(max(y_0)-min(y_0))

nx = round( (max(xra)-min(xra))/res_arcsec)
ny = round( (max(yra)-min(yra))/res_arcsec)
define_xy_coord, nx, ny, res_arcsec, 0., 0., xg, yg, xmap, ymap

sigma = !fwhm2sigma * 16.d0
map_t = exp( -(xmap^2+ymap^2)/(2.*sigma^2))
wind, 1, 1, /f
plottv, map_t, xmap, ymap, /iso, /scal
oplot, x_0, y_0


nika_sim_sky_toi, ra_source, dec_source, LST, x_0, y_0, fpc_x, fpc_y, fp, $
                  map_t, res_arcsec, ymap, toi, $
                  f_sample=f_sample, map_q=map_q, map_u=map_u, nsmooth=nsmooth




end
