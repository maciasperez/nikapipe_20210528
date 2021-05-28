;+
;
; SOFTWARE: 
;        NIKA Simulations Pipeline
; 
; PURPOSE: 
;        This is the main procedure of the NIKA simulation
;        software. It launches the different modules that end up
;        creating the simulated timelines.
; 
; INPUT: 
;        None
;        
; OUTPUT: 
;        Simulated timelines and focal plane saved as FITS files
; 
; KEYWORDS:
;        - IN_PARAM: the parameter structure containing the simulation
;          information can be provided directly. Otherwise the default
;          pipeline is launched (i.e. Uranus geometry).
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 09/03/2014: creation from partial_simu_launch.pro (Remi Adam - adam@lpsc.in2p3.fr)
; 
;-

pro nks, $
   IN_PARAM=IN_PARAM, $
   SCAN_LIST=SCAN_LIST

  ;;========== Calling sequence
  if n_params() lt 1 then begin
     message, /info, "Calling sequence:"
     print, "nk, $"
     print, "IN_PARAM=IN_PARAM"
     print, "SCAN_LIST=SCAN_LIST"
     return
  endif
  
  ;;========== Initialization
  if keyword_set(IN_PARAM) then simpar = IN_PARAM else begin $
     nks_init, simpar
     simpar = replicate(simpar, nscan)
  endelse
  if Nscan ne n_elements(simpar) then message, 'The number of scans does not correspond to the input parameters'
     
  ;;========== Create the simulated map if needed
  nks_create_map, simpar

  ;;========== Loop over all scans requested
  nscans = n_elements(simpar.scan_list)
  for iscan = 0 , nscans - 1 do begin
     
     ;;========== Get the pointing and define the data structure accordingly
     nks_getpointing, simpar
     
     ;;========== Add the source in the timeines
     nks_add_source, param, data, kidpar

     ;;========== Add glitches in the timelines
     nks_add_glitch, param, data, kidpar

     ;;========== Add pulse tube lines in the timelines
     nks_add_pulsetube, param, data, kidpar

     ;;========== Add the atmospheric noise in the timelines
     nks_add_atmo, param, data, kidpar

     ;;========== Add the electronic noise in the timelines
     nks_add_elec, param, data, kidpar
     
     ;;========== Save the data as FITS files
     nks_save_data
     
     ;;========== Provide some info the the user
     message, /info, 'Data computed for the scan '+strtrim(iscan+1,2)+'/'+strtrim(nscans,2)
     
  endfor
  
end
