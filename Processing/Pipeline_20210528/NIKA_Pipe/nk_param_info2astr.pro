;+
;
; SOFTWARE:
;
; NAME: 
; nk_param_info2header_astr.pro
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;  nk_param_info2astr, param, info, astr
;
; PURPOSE: 
;        Creates header and astrometry structure for the maps
; 
; INPUT: 
;      - param, info
; 
; OUTPUT: 
;     - astr
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Feb. 2019, NP
;================================================================================================

pro nk_param_info2astr, param, info, astr
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_param_info2astr'
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

;; Force to an odd number of pixels in each directions
nx = 2L*floor( param.map_xsize/param.map_reso/2.) + 1
ny = 2L*floor( param.map_ysize/param.map_reso/2.) + 1
;; crpix = double( [nx/2+1, ny/2+1])
;; crpix can (should ?) be a decimal number, see:
;; http://hosting.astro.cornell.edu/~vassilis/isocont/node17.html
;; Need to add 1 to match fits convention for which the 1st pixel is
;; (1,1), whereas in IDL (and ad2xy) it is (0,0)
crpix = [double(nx)/2.+1, double(ny)/2.+1]

;; default
ctype = ["RA---TAN", "DEC--TAN"]
if strupcase( strtrim(param.map_proj, 2)) eq "GALACTIC" then ctype = ['GLON-TAN', 'GLAT-TAN']
if strupcase( strtrim(param.map_proj, 2)) eq "AZEL"     then ctype = ['ALON-GLS','ALAT-GLS']

astr = create_struct("naxis", [nx, ny], $
                     "cd", double( [[1,0], [0,1]]), $
                     "cdelt", [-1.d0, 1.d0]*param.map_reso/3600.d0, $
                     "crpix", crpix, $
                     "crval", double([info.longobj, info.latobj]), $
                     "ctype", ctype, $
                     "longpole", 180.d0, $
                     "latpole", 90.d0, $
                     "pv2", dblarr(2))
end
