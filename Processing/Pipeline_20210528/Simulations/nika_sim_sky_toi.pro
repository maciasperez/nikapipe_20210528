;ra_source, dec_source : in DEGREES
; LST : in hours
; xoffset, yoffset : reference pointing offset w.r.t the source being tracked in ARCSEC
; fpc_x, fpc_y: pointing offset between actual and nominal telescope pointing
;fp : stucture describing the focal plane pixels {name:'a', ix:0, iy:0,
;           nas_x:0d0, nas_y:0d0, nas_center_x:0.d0, nas_center_y:0.d0, flag:0, rho:0d0, gain:1.d0} to be updated with
;           simulation improvements
; map_t : Intensity map
; res_arcsec : map resolution in arcseconds
; pixel *CENTERS*
;
;optional:
;
;nsmooth : to smooth pixel edges in timelines

;---------------------------------------------------------------------------------

; No need for parallactic angle because I work directly with (az,el) and (ra,dec)
pro nika_sim_sky_toi, ra_source, dec_source, lst, xoffset, yoffset, fpc_x, fpc_y, fp, $
                      map_t, res_arcsec, ymap, toi, noplot=noplot, $
                      f_sample=f_sample, map_q=map_q, map_u=map_u, nsmooth=nsmooth

if not keyword_set( f_sample) then f_sample = !nika_f_sampling
if not keyword_set( map_q)    then map_q    = map_t*0.0d0
if not keyword_set( map_u)    then map_u    = map_t*0.0d0
if not keyword_set( nsmooth)  then nsmooth  = 0

;; raw_dir   = "/Data/NIKA/Iram_Oct2011/Raw/"
;; scan_file = "d_2011_10_18_00h29m35_Uranus_333"
;; fp = mrdfits( "/Data/NIKA/Iram_Oct2011/FocalPlaneGeometry/FPG_config_2_RF_v1.fits", 1, h)

nkids = n_elements( fp.(0))
nsn   = n_elements( xoffset)
nkids = n_elements( fp.(0))
toi   = dblarr( nkids, nsn)

; Generate coordinates, centered on source, Ra-Dec tangential plane
nx = n_elements( map_t[*,0])
ny = n_elements( map_t[0,*])
define_xy_coord, nx, ny, res_arcsec, 0.d0, 0.d0, xg, yg, xmap, ymap

;; lst = pfstr.lst*!radeg/!h2d
nika_radec2azel, ra_source, dec_source, az_source, el_source, lst=lst

if not keyword_set(noplot) then begin
   make_ct, nkids, ct
   wind, 1, 1, /free, /large
   plottv, map_t, xmap, ymap, /iso, /scal, title='T'
endif

for ikid=0, nkids-1 do begin
   if fp[ikid].flag eq 1 then begin

      nika_nasmyth2azel, fp[ikid].nas_x, fp[ikid].nas_y, $
                         fp[ikid].nas_center_x, fp[ikid].nas_center_y, $
                         fpc_x, fpc_y,  el_source, dx, dy
      ;;(az,el)
      coel = cos(el_source*!dtor)
      az = az_source + (xoffset + dx)/3600.0d0/coel
      el = el_source + (yoffset + dy)/3600.0d0

      ;;(ra,dec)
      nika_azel2radec, az, el, ra, dec, lst=lst

      ;;(ra,dec) tangential plane
      x = (ra  -  ra_source)*3600.0d0 * cos(dec_source*!dtor)
      y = (dec - dec_source)*3600.0d0

      if not keyword_set(noplot) then oplot, x, y, col=ct[ikid]

      xx = x - (xmap[0] - res_arcsec/2.d0)
      yy = y - (ymap[0] - res_arcsec/2.d0)
      ipix = long( yy/res_arcsec)*nx + long( xx/res_arcsec)
      if min(ipix) lt 0 or max(ipix) gt (long(nx)*long(ny)-1) then begin
         print, "Wrong pixel index: ikid, minmax(ipix): ", ikid, minmax(ipix)
         stop
      endif else begin
         toi[ikid,*] = map_t[ipix] ;  + fp[ikid].rho * ( map_q[ipix]*cos4omega + map_u[ipix]*sin4omega)
         if nsmooth gt 0 then toi[ikid,*] = smooth( toi[ikid,*], nsmooth)
      endelse
      
   endif
endfor

end
