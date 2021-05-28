;+
;PURPOSE: Comput the volume covered by the beam up to a given distance
;
;INPUT: - lambda_mm: the wavelenght in mm
;       - file: the beam fits file (string)
;
;OUTPUT: - The beam volume in arcsec^2
;
;KEYWORD: - int_rad: the radius at which the integration stops
;           (default is 1 arcmin)
;         - no_file: set this keyword is you do not have a beam file,
;           then the beam is the gaussian beam x 1.5, with 1.5 being the
;           error beam
;
;LAST EDITION: 
;   26/01/2014: Creation (adam@lpsc.in2p3.fr)
;-

function nika_pipe_measure_beam_volume, lambda_mm, file, int_rad=int_rad, no_file=no_file
  
  if keyword_set(int_rad) then rad_int = int_rad else rad_int = 60.0
  
  if keyword_set(no_file) then begin
     if round(lambda_mm) eq 1 then beam_vol = 1.5 * 2*!pi * (12.0*!fwhm2sigma)^2
     if round(lambda_mm) eq 2 then beam_vol = 1.5 * 2*!pi * (18.0*!fwhm2sigma)^2
  endif else begin
     
     ;;------- Get the beam profile
     case round(lambda_mm) of
        1: struct = mrdfits(file, 1, head, /silent)        
        2: struct = mrdfits(file, 2, head, /silent)
     endcase
     radius = struct.angular_radius
     beam = struct.beam
     integ_rad = struct.INTEGRATED_ANGULAR_RADIUS
     solid_angle = struct.SOLID_ANGLE   

     ;;------- Integrate up to the radius
     loc_integ = where(radius lt rad_int, nloc)
     loc_integ2 = where(integ_rad lt rad_int, nloc2)
     if nloc eq 0 then message, 'The integration radius provided is too small such that no point is availlable'
     if nloc2 eq 0 then message, 'The integration radius provided is too small such that no point is availlable'
     
     beam_vol = int_tabulated(radius[loc_integ], 2*!pi*radius[loc_integ] * beam[loc_integ]) 
     beam_vol2 = max(solid_angle[loc_integ2])

     if 100*abs(beam_vol - beam_vol2)/beam_vol2 gt 15 then message, /info, 'Warning: the beam volume ' + $
        'computed from the profile is more then 15% different with respect to the map'
  endelse
  
  return, beam_vol
end
