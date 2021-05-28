
;; Extracted from Xavier's Pipeline/Iram2010_Red/Pro/detcoord.pro
;; to have a stable version in my !path

;; el_source_deg : true elevation of the target source in DEGREES
;; nas_x : x coord in ARCSEC of the pixel in Nasmyth coordinates
;; nas_y : y coord in ARCSEC of the pixel in Nasmyth coordinates
;; nas_center_x : center of rotation x in Nasmyth coordinates (in ARCSEC)
;; nas_center_y : center of rotation y in Nasmyth coordinates (in ARCSEC)
;; fpc_x, fpc_y : pointing offset correction in ARCSEC
;; delta_coel : output co-elevation (= azimuth*cos(elevation)) offset of the detector in ARCSEC
;; delta_el   : output    elevation offset of the detector in ARCSEC

pro nika_nasmyth2azel, nas_x, nas_y, fpc_x, fpc_y, el_source_deg, delta_coel, delta_el, $
                       nas_x_ref=nas_x_ref, nas_y_ref=nas_y_ref

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nika_nasmyth2azel, nas_x, nas_y, fpc_x, fpc_y, el_source_deg, delta_coel, delta_el, $"
   print, "                   nas_x_ref=nas_x_ref, nas_y_ref=nas_y_ref"
   return
endif

if not keyword_set(nas_x_ref) then nas_x_ref = 0.d0
if not keyword_set(nas_y_ref) then nas_y_ref = 0.d0

;;alpha    = !dpi/2.d0 - el_source_deg*!dtor
;;
;;cosalpha = cos(alpha)
;;sinalpha = sin(alpha)

;; Arcsec
;delta_coel = (nas_x-nas_x_ref)*cosalpha - (nas_y-nas_y_ref)*sinalpha
;delta_el   = (nas_x-nas_x_ref)*sinalpha + (nas_y-nas_y_ref)*cosalpha
nasm2azel, el_source_deg*!dtor, (nas_x - nas_x_ref), (nas_y - nas_y_ref), delta_coel, delta_el


;; Add pointing offset
delta_coel = fpc_x + delta_coel
delta_el   = fpc_y + delta_el

end
