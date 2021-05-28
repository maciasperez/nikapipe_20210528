
;+
;
; SOFTWARE:
; NIKA pipeline
;
; NAME: 
;  nk_subtract_maps_from_toi
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_truncate_filter_map, param, info, subtract_maps
; 
; PURPOSE: 
;        truncate and median filter subtract_maps
; 
; INPUT: 
;        - param, info, kidpar, subtract_maps
;         param.map_truncate_percent
; OUTPUT: 
;    subtract_maps is modified (only 1mm and 2mm maps)
;    
; KEYWORDS:
;    truncate_map: a map that can be used to multiply the output map
;(1 at the center, 0 at the outside)
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 2020, FXD

pro nk_truncate_filter_map, param, info, subtract_maps, truncate_map = truncate_mapsm
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_truncate_filter_map'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

sm = subtract_maps
FOV2 = 0.                       ; default
reso = param.map_reso           ; default

u = where(strmatch( tag_names( param), 'MAP_TRUNCATE_PERCENT', /fold) eq 1, nu)
if nu ne 0 then begin
   truncate_percent = param.map_truncate_percent
   if truncate_percent gt 0. then begin
;;;truncate_percent = 50.
      FOV2 = (6.5*60.)/2                             ; size of half a FOV in arcsec
      w = where( sqrt( sm.xmap^2 + sm.ymap^2) lt FOV2, nw) ; define the pixels within FOV/2 of center
      medhitmap_1mm = double(median( sm.nhits_1mm[w]))     ; take this as the standard hit count
      medhitmap_2mm = double(median( sm.nhits_2mm[w]))     ; take this as the standard hit count
; define the area with a reasonable hit count at 1 and 2 mm simultaneously
      if not keyword_set(truncate_map) then $  ; Define if not given as an input
         truncate_map = double( (sm.nhits_1mm gt (medhitmap_1mm*truncate_percent/100.)) AND $
                             (sm.nhits_2 gt (medhitmap_2mm*truncate_percent/100.)))
      nextend = 4                        ; size of the smoothing map in numbers of sigma_kernel
      reso = abs(sm.cdelt[0])*3600.      ; map resolution in arcsec.
      kgauss = get_gaussian_kernel(  FOV2/2., reso,  nextend = nextend) ; get a normalized Gaussian so convolution does not change values wherever constant
      truncate_mapsm = convol( truncate_map, kgauss) ; smooth the truncation (a sort of apodisation).
      sm.map_i1 = sm.map_i1*truncate_mapsm
      sm.map_i2 = sm.map_i2*truncate_mapsm
      sm.map_i3 = sm.map_i3*truncate_mapsm
      sm.map_i_1mm = sm.map_i_1mm*truncate_mapsm
      sm.map_i_2mm = sm.map_i2 ; sm.map_i_2mm*truncate_mapsm

      ; Do the same for the hit counts so that the noise is preserved
      ; keep hard truncation to avoid border effects in flux measurements
      tr_hit = (truncate_mapsm gt 0.7)*truncate_map
      sm.nhits_1 = sm.nhits_1*tr_hit^2 
      sm.nhits_2 = sm.nhits_2*tr_hit^2
      sm.nhits_3 = sm.nhits_3*tr_hit^2
      sm.nhits_1mm = sm.nhits_1mm*tr_hit^2
      sm.nhits_2mm = sm.nhits_2 ; sm.nhits_2mm*tr_hit^2
   endif
endif


; Now check the median filtering
u = where(strmatch( tag_names( param), 'MAP_MEDIAN_FRACT', /fold) eq 1, nu)
if nu ne 0 then begin           ; do the subraction only if the parameter is defined and positive
   nsm = 2*round(FOV2*2.*param.map_median_fract/reso/2.)+1 
     ; make it odd (take third a fov smoothing (fov is slow))
   if nsm gt 10 then begin
      it = sm.map_i1
      sm.map_i1 = it-median(it, nsm)
      
      it = sm.map_i2
      sm.map_i2 = it-median(it, nsm)
      
      it = sm.map_i3
      sm.map_i3 = it-median(it, nsm)
      
      it = sm.map_i_1mm
      sm.map_i_1mm = it-median(it, nsm)
      
      it = sm.map_i_2mm
      sm.map_i_2mm = it-median(it, nsm)
   endif
endif


subtract_maps = sm

if param.cpu_time then nk_show_cpu_time, param
return
end
