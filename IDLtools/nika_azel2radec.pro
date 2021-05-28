
; INPUTS
;                                                
;   el - the local apparent elevation, in DEGREES, scalar or vector
;                                                        
;   az  - the local apparent azimuth, in DEGREES, scalar or vector,
;                                                        
;         measured EAST of NORTH!!!  If you have measured azimuth west-of-south
;                                                        
;        (like the book MEEUS does), convert it to east of north via:
;                                                       
;                       az = (az + 180) mod 360
;                                                                      
;   UT : time of day, decimal hours
;   month : month (e.g. October = 10)
;   day, year
;
;   lon - the local geodetic longitude, in DEGREES (East longitudes get negative
;         sign : Paris: -2 deg, 19'
;   lat - the local geodetic latitude, in DEGREES, scalar or vector.
;
; OUTPUTS
;
; ra : right ascension in DEGREES
; dec : Declination, in DEGREES
; LST in hours
;============================================================================================

;;pro nika_azel2radec, az, el, UT, day, month, year, ra, dec, lon=lon, lat=lat,
;;lst=lst
pro nika_azel2radec, az, el, ra, dec, UT, day, month, year, lon=lon, lat=lat, lst=lst

if not keyword_set(lat) then lat = !iram_lat
if not keyword_set(lon) then lon = !iram_lng

;; Azimuth elevation to hour angle and declination
altaz2hadec, el, az, lat, ha, dec

;; Universtal Time to Local Sideral Time
if not keyword_set(lst) then begin
   CT2LST, LST, lon, 0, UT, day, month, year
endif

;; Hour angle to Right Ascension
ra = reform( ( LST*15.0d0 - ha + 360.0d0) mod 360.0d0)
end
