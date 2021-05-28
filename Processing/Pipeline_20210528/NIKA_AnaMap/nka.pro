;+
;
; SOFTWARE: 
;        NIKA Map Analysis Software
; 
; PURPOSE: 
;        This is the main procedure of the map analysis software. It
;        mainly analyse the map and return large variety of outputs.
; 
; INPUT: 
;        The list of scans to be used as a string vector
;        e.g. ['20140221s0024', '20140221s0025', '20140221s0026']
; 
; OUTPUT: 
;        - Plot of the maps
;        - Beam profile as a FITS file
;        - ...
; 
; KEYWORDS:
;        - 
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 04/03/2014: creation from nika_anapipe_launch.pro (Remi Adam - adam@lpsc.in2p3.fr)
; 
;-

pro nka, input, $
         KEYWORDS=KEYWORDS
  
  ;;========== Calling sequence
  if n_params() lt 1 then begin
     message, /info, "Calling sequence:"
     print, "nk, scan_list, $"
     print, "DECOR=DECOR, $"
     return
  endif

  ;;========== Initialization of the parameters
  nka_init, input, anapar

  ;;========== Get the maps and put them in a structure used hereafter
  nka_get_map, anapar, maps
  
  ;;========== Plot the main maps
  nka_plot_maps, anapar, maps

  ;;========== Beam measurement
  nka_beam, anapar, maps
  
  ;;========== Point source photometry
  nka_ps_photo, anapar, maps

  ;;========== Diffuse source photometry
  nka_diff_photo, anapar, maps

  ;;========== Profiles measurements
  nka_profile, anapar, maps

  ;;========== Show map per detectors
  nka_map_per_kid, anapar, maps

  ;;========== Show map per scan
  nka_map_per_scan, anapar, maps

  ;;========== Compute the spectrum and plot the map
  nka_spectrum, anapar, maps

  ;;========== Noise study
  nka_noise, anapar, maps

  ;;========== Find point sources in a map (contaminated by diffuse emmission)
  nka_find_ps, anapar, maps

  ;;========== Compute the transfer function
  nka_transfer_function, anapar, maps

  return
end
