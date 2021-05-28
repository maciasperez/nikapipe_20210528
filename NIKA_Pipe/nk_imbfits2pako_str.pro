
;+
;
; SOFTWARE: General
;
; NAME: 
; nk_imbfits2pako_str
;
; CATEGORY: general
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Passes info from the Antenna IMBfits to a structure similar to the one
;;       created when we read the xml files in Real time.
; 
; INPUT: 
;      imb_fits_file : the complete path to the Antenna IMBfits file
; 
; OUTPUT: 
;      pako_str: the summary structure
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 4th, 2014: Nicolas Ponthieu
;-
;================================================================================================

pro nk_imbfits2pako_str, imb_fits_file, pako_str

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_imbfits2pako_str, imb_fits_file, pako_str"
   return
endif

init_pako_str, pako_str

a = mrdfits( imb_fits_file, 0, hdr, /sil)
pako_str.obs_type = sxpar( hdr,'OBSTYPE',/silent)

imbHeader = HEADFITS( imb_fits_file,EXTEN='IMBF-scan', /silent)
pako_str.p2cor  = SXPAR(imbHeader, 'P2COR')/!pi*180.d0*3600.d0
pako_str.p7cor  = SXPAR(imbHeader, 'P7COR')/!pi*180.d0*3600.d0
pako_str.source = sxpar(imbheader, 'OBJECT')

pako_str.focusx = double( sxpar( imbHeader, 'FOCUSX'))
pako_str.focusy = double( sxpar( imbHeader, 'FOCUSY'))
pako_str.focusz = double( sxpar( imbHeader, 'FOCUSZ'))

r = mrdfits( imb_fits_file, 1, /silent)
pako_str.NAS_OFFSET_X = r[0].XOFFSET/!arcsec2rad ;Valid only if Nasmyth offsets
pako_str.NAS_OFFSET_Y = r[0].YOFFSET/!arcsec2rad

;; ;; ??
;; pako_str.NAS_OFFSET_X = r.XOFFSET/!arcsec2rad ;Valid only if Nasmyth offsets
;; pako_str.NAS_OFFSET_Y = r.YOFFSET/!arcsec2rad

end
