
;; Retrying FTTau as  faint source to cross check routines

scan_num_list   = [162, 163, 164, 165]
day        = '20121119'
png        = 1
noskydip   = 1

;; Let it retrieve the correct kidpar with get_kidpar_ref
nika_pipe_default_param, scan_num_list[0], day, param
param.map.size_ra    = 300.d0
param.map.size_dec   = 300.d0
param.map.reso       = 4.d0
param.decor.iq_plane.apply = 'no'

param.decor.method   = 'common_mode_kids_out' ; 'median_simple'
param.decor.common_mode.d_min = 25.

for i=0, n_elements(scan_num_list)-1 do begin
   otf_map, scan_num_list[i], day, /logbook, png=png, ps=ps, $
            param=param, noskydip=noskydip, box_maps=box_maps, $
            xmap=xmap, ymap=ymap

   if i eq 0 then begin         ; init
      map1mm = box_maps.a
      map2mm = box_maps.b

      map1mm.var = map1mm.var * 0.d0
      map2mm.var = map2mm.var * 0.d0

      map_time1mm = box_maps.a.time * 0.d0
      map_time2mm = box_maps.b.time * 0.d0

      w81mm = box_maps.a.var * 0.d0
      w82mm = box_maps.b.var * 0.d0
   endif

   w = where( box_maps.a.var ne 0)
   map1mm.jy[w] = map1mm.jy[w] + box_maps.a.jy[w]/box_maps.a.var[w]
   w81mm[ w] = 1.d0/box_maps.a.var[w]
   map_time1mm = map_time1mm + box_maps.a.time

   w = where( box_maps.b.var ne 0)
   map2mm.jy[w] = map2mm.jy[w] + box_maps.b.jy[w]/box_maps.b.var[w]
   w82mm[ w] = 1.d0/box_maps.b.var[w]
   map_time2mm = map_time2mm + box_maps.b.time

endfor

;; Combine final map
w = where( w81mm ne 0)
map1mm.jy[w] = map1mm.jy[w]/w81mm[w]
map1mm.var[w] = 1.d0/w81mm[w]

w = where( w82mm ne 0)
map2mm.jy[w] = map2mm.jy[w]/w82mm[w]
map2mm.var[w] = 1.d0/w82mm[w]


;; Derive flux and noise properties
kidpar_1mm = mrdfits( param.kid_file.a, 1)
kidpar_2mm = mrdfits( param.kid_file.b, 1)

w1 = where( kidpar_1mm.type eq 1)
fwhm1mm = avg( kidpar_1mm[w1].fwhm)
w1 = where( kidpar_2mm.type eq 1)
fwhm2mm = avg( kidpar_2mm[w1].fwhm)

nika_map_noise_estim, param, map1mm, xmap, ymap, fwhm1mm, flux, sigma_flux, sigma_bg
format="(F8.2)"
if flux lt 1 then begin
   flux       = flux * 1000
   sigma_flux = sigma_flux * 1000
   sigma_bg   = sigma_bg   * 1000
   units      = 'mJy'
endif else begin
   units      = "Jy"
endelse
s_flux       = strtrim( string(flux,format="(F8.2)"), 2)
s_flux_noise = strtrim( string(sigma_flux,format='(F7.2)'),2)+$
               "/"+strtrim( string(sigma_bg,format="(F7.2)"),2)
leg_txt_1mm = ['Flux : '+s_flux+" +- "+s_flux_noise +' '+units]


nika_map_noise_estim, param, map2mm, xmap, ymap, fwhm2mm, flux2, sigma_flux, sigma_bg
format="(F8.2)"
if flux lt 1 then begin
   flux       = flux * 1000
   sigma_flux = sigma_flux * 1000
   sigma_bg   = sigma_bg   * 1000
   units      = 'mJy'
endif else begin
   units      = "Jy"
endelse
s_flux       = strtrim( string(flux,format="(F8.2)"), 2)
s_flux_noise = strtrim( string(sigma_flux,format='(F7.2)'),2)+$
               "/"+strtrim( string(sigma_bg,format="(F7.2)"),2)
leg_txt_2mm = ['Flux : '+s_flux+" +- "+s_flux_noise +' '+units]

my_multiplot, 2, 1, pp, pp1, /rev
wind, 1, 1, /free, xs=1200, ys=800
imview, map1mm.jy, xmap=xmap, ymap=ymap, title='1mm', position=pp1[0,*], /noerase, $
        legend_text=leg_txt_1mm, legend_chars=1.5
imview, map2mm.jy, xmap=xmap, ymap=ymap, title='2mm', position=pp1[1,*], /noerase, $
        legend_text=leg_txt_2mm, legend_chars=1.5



end
