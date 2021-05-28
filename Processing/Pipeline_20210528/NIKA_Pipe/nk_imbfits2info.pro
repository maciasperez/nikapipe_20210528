;+
;
; SOFTWARE:
;
; NAME: 
; nk_imbfits2info
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;  nk_imbfits2info, imb_fits_file, info
;
; PURPOSE: 
;        Updates info with relevant scan information retrieved from
;        the AntennaIMBfits
; 
; INPUT: 
;      - imb_fits_file, info
; 
; OUTPUT: 
;     - info
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Oct. 11th, 2015: NP
;================================================================================================

pro nk_imbfits2info, imb_fits_file, info, scan=scan
;-
  
if n_params() lt 1 then begin
   dl_unix, 'nk_imbfits2info'
   return
endif

if keyword_set(scan) then begin
   nk_find_raw_data_file, ss, dd, ff, imb_fits_file, scan=scan, /silent
endif

if defined(info) eq 0 then nk_default_info, info

ant0 = mrdfits( imb_fits_file, 0, head_ant0, /silent)
info.n_obs = sxpar( head_ant0, 'N_OBS')

ant1 = (mrdfits( imb_fits_file, 1, head_ant1, /silent))[0]
if size(ant1,/TNAME) eq "INT" or size(ant1,/TNAME) eq "LONG" then begin
   nk_error, info, "wrong imbfits file (ext 1)"
   return
endif
ant2 = (mrdfits( imb_fits_file, 2, head_ant2, /silent))[0]
if size(ant2,/TNAME) eq "INT" or size(ant2,/TNAME) eq "LONG" then begin
   nk_error, info, "wrong imbfits file (ext 2)"
   return
endif

;; added, june 2018
ll = strlen( 'iram30m-antenna-')
ll1 = strlen( '-imb.fits')
myfile = file_basename(imb_fits_file)
info.scan = strmid( myfile,ll,strlen(myfile)-ll1-ll)
info.day  = long((strsplit(info.scan,'s',/ex))[0])
info.scan_num = long((strsplit(info.scan,'s',/ex))[1])

info.object        = strtrim(sxpar( head_ant1, 'OBJECT'), 2)
info.azimuth_deg   = ant2[0].CAZIMUTH  * !radeg ; commanded
info.result_elevation_deg = ant2[0].CELEVATIO * !radeg

date = sxpar(head_ant1, 'date')
ll = strlen(date)
info.UT = strmid( date, ll-8) 

info.tau225      = sxpar( head_ant1, 'TIPTAUZ')
info.pressure    = sxpar( head_ant1, 'PRESSURE')
info.temperature = sxpar( head_ant1, 'TAMBIENT')
info.humidity    = sxpar( head_ant1, 'HUMIDITY')
info.wind_speed  = sxpar( head_ant1, 'WINDVEL')

info.obs_type    = sxpar( head_ant2, 'OBSTYPE')
info.systemof    = sxpar( head_ant2, "systemof")

info.ctype1 = sxpar(head_ant1, "CTYPE1")
info.ctype2 = sxpar(head_ant1, "CTYPE2")

info.longobj     = sxpar( head_ant1, "longobj")   ; degrees
info.latobj      = sxpar( head_ant1, "latobj")    ; degrees

info.focusx = sxpar( head_ant1, "FOCUSX")
info.focusy = sxpar( head_ant1, "FOCUSY")
info.focusz = sxpar( head_ant1, "FOCUSZ")

info.nasmyth_offset_x = ant1.(1)*!radeg*3600
info.nasmyth_offset_y = ant1.(2)*!radeg*3600

info.p2cor = sxpar( head_ant1, "P2COR")*!radeg*3600
info.p7cor = sxpar( head_ant1, "P7COR")*!radeg*3600

info.mjd = sxpar( head_ant1, 'MJD')

end
