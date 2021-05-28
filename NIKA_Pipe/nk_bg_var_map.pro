;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_bg_var_map
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Derives the variance map associated to an observation map and
; the number of hits per pixels by computing the standard dev of
; sqrt(n)*m. This is more accurate than the sole propation of toi
; weights.
; 
; INPUT: 
;        - map: the scientific data
;        - nhits: number of hits per pixel
;        - bg_mask: set 1 in pixels that must be used for the noise
;          estimation, 0 otherwise
;
; OUTPUT: 
;        - map_var
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 3rd, 2016: NP


pro nk_bg_var_map, map, nhits, bg_mask, map_var, $
                   boost=boost, nhits_min_bg_var_map=nhits_min_bg_var_map, $
                   commissioning_plot=commissioning_plot, sigma_h=sigma_h, status=status
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_bg_var_map'
   return
endif

if not keyword_set(nhits_min_bg_var_map) then nhits_min_bg_var_map=5 ; 20

status = 0

map_var = map*0.d0
;; ;;wpix = where( bg_mask eq 1 and nhits ne 0, nwpix)
;; ; FXD, Nov 2017, add the condition of 20 hits to avoid badly sampled pixels
;; wpix = where( bg_mask eq 1 and nhits ge nhits_min_bg_var_map, nwpix)
;; if nwpix eq 0 then begin
;;    message, /info, "no pixel has bg_mask == 1 and nhits>=20, I cannot compute the background noise"
;;    return
;; endif

;; Compute the background noise
;; hh            = sqrt(nhits[wpix])*map[wpix]
;; sigma_h       = stddev(hh)
nhits_med = median(nhits[where(nhits ne 0)])
wpix      = where( nhits ge nhits_med and bg_mask eq 1)
hh        = sqrt(nhits[wpix])*map[wpix]
sigma_h   = stddev(hh)

;; wind, 1, 1, /free, /large
;; my_multiplot, 3, 3, pp, pp1, /rev
;; imview, map, position=pp1[0,*]
;; imview, nhits, position=pp1[1,*], /noerase
;; imview, bg_mask, position=pp1[2,*], /noerase
;; np_histo, nhits[wpix], position=pp1[3,*], /noerase, title='wpix ori'
;; imview, nhits/nhits_med, position=pp1[4,*], /noerase, title='Nhits/nhits_med='+strtrim( long(nhits_med),2)
;; stop

;; Deduce the variance map
whits = where( nhits ne 0)
map_var[whits] = sigma_h^2/nhits[whits]

if keyword_set(boost) then begin
   histo_make, map[wpix]/sqrt(map_var[wpix]), $
               /gauss, n_bin = 301, minval = -10, maxval = +10, $
               xarr, yarr, stat_res, gauss_res
   if defined(gauss_res) eq 0 then begin
      status = 1
      return
   endif
   sigma_boost = gauss_res[1]
   map_var *= sigma_boost^2
endif

end
