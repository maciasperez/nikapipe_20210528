
pro fits2map, fitsfile, output_maps, ra_map = ra_map, dec_map = dec_map, append = append, lambda = lambda, $
              ra_center = ra_center, dec_center = dec_center


;; Signal
map = mrdfits(fitsfile, 1, header)

;; Variance
map_var = mrdfits(fitsfile, 2)
map_var = map_var^2

;; Nhits
nhits = mrdfits(fitsfile, 3)

;; Decorrelation mask
mask = mrdfits(fitsfile, 4)

;; Coordinates
sxaddpar, header, 'CTYPE1', 'RA---TAN'
sxaddpar, header, 'CTYPE2', 'DEC--TAN'

reso       = abs(sxpar( header, "CDELT1"))*3600.d0
ra_center  = sxpar( header, "CRVAL1")
dec_center = sxpar( header, "CRVAL2")

create_coo2, header, ra_map, dec_map, /silent

;; Approx correction by the cosine of the center declination...
xmap = -(ra_map  -  ra_center)*3600.d0*cos(dec_center*!dtor)
ymap =  (dec_map - dec_center)*3600.d0

;; Init output_maps if needed
if not keyword_set(append) then begin
   output_maps = {map_i_1mm:map*0.d0, $
                  map_i_2mm:map*0.d0, $
                  map_var_i_1mm:map*0.d0, $
                  map_var_i_2mm:map*0.d0, $
                  nhits_1mm:map*0.d0, $
                  nhits_2mm:map*0.d0, $
                  xmap:xmap, $
                  ymap:ymap, $
                  mask_source:mask, $
                  xmin:min(xmap)-reso/2., $
                  ymin:min(ymap)-reso/2., $
                  nx:n_elements(map[*,0]), $
                  ny:n_elements(map[0,*]), $
                  map_reso:reso}
endif

;; fill or append
if lambda eq 1 then begin
   output_maps.map_i_1mm = map
   output_maps.map_var_i_1mm = map_var
   output_maps.nhits_1mm = nhits
endif else begin
   output_maps.map_i_2mm = map
   output_maps.map_var_i_2mm = map_var
   output_maps.nhits_2mm = nhits
endelse

end
