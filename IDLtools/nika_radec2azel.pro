

; ra, dec in degrees
; az, el in degrees
; LST in hours

pro nika_radec2azel, ra, dec, az, el, UT, day, month, year, lon=lon, lat=lat, lst=lst

if not keyword_set(lat) then lat = !iram_lat
if not keyword_set(lon) then lon = !iram_lng

if not keyword_set(lst) then begin
   ;;Universtal Time to Local Sideral Time
   CT2LST, LST, lon, 0, UT, day, month, year
endif

;; Ra to hour angle
ha = LST*15.0d0 - (ra mod 360.0d0)

;; Compute azimuth and elevation
hadec2altaz, ha, dec, lat, el, az

end
