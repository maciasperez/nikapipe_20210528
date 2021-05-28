;+
;
; SOFTWARE: 
;        NIKA simulations
;
; NAME: 
;        nk_default_simpar
;
; CATEGORY: 
;        initialization
;
; CALLING SEQUENCE:
;         nk_default_simpar, simpar
; 
; PURPOSE: 
;        Create the parameter structure from the scan list 
; 
; INPUT: 
;       
; OUTPUT: 
;        - simpar: a default simulation parameter structure
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug. 10th, 2014: NP
;        - May  26,   2015: AR
;-

pro nks_default_simpar, param, simpar, grid, $
                        n_point_sources=n_point_sources, $
                        map=map, $
                        polar=polar
  
  
  ;; simpar = {reset:1, $          ; set to 1 to erase the intput signal and replace by pure simulations
  ;;           polar:keyword_set(polar), $          ; set to 1 to produce a polarized simulation
  ;;           uniform_fwhm: 0, $  ; set to 1 to force all kids in kidpar to have the same FWHM in a band
  ;;           fwhm_1mm:12.d0, $   ; if uniform_fwhm is set, this will be the FWHM at 1mm
  ;;           fwhm_2mm:18.d0, $   ; if uniform_fwhm is set, this will be the FWHM at 2mm
  ;;           kid_NET:0.d0, $     ; Noise equivalent temperature of 1 kid
  ;;           kid_fknee:0.d0, $   ; fknee of the 1/f noise of a kid
  ;;           kid_alpha_noise:0.d0, $ ; slope of 1/f noise 
  ;;           white_noise:0, $        ; set to 1 to simulate white noise only
  ;;           n_point_sources:n_point_sources}      ; number of point sources that are added anlytically to the TOIs


  ;; if keyword_set(n_point_sources) then begin
  ;;    simpar = { ps_flux1mm:   10, $  ; point source flux at 1mm (Jy)
  ;;               ps_flux2mm:   20, $ ; point source flux at 2mm (Jy)
  ;;               ps_flux_q_1mm: 5, $ ; polarization Q flux...
  ;;               ps_flux_u_1mm: 5, $
  ;;               ps_flux_q_2mm: 5, $
  ;;               ps_flux_u_2mm: 5, $
  ;;               ps_offset_x:   dblarr( n_point_sources), $
  ;;               ps_offset_y:   dblarr( n_point_sources)}
  ;; endif

  if keyword_set(map) then begin
     simpar_out = create_struct( simpar, $
                                 ;; "map_reso", param.map_reso, $ ; map resolution in arcsec
                                 ;; "map_xsize", param.map_xsize, $
                                 ;; "map_ysize", param.map_ysize, $
                                 ;; "xmin", grid.xmin, $
                                 ;; "ymin", grid.ymin, $
                                 ;; "nx", grid.nx, $
                                 ;; "ny", grid.ny, $
                                 "map_i_1mm",grid.xmap*0.d0,$
                                 "map_i_2mm",grid.xmap*0.d0,$
                                 "map_q_1mm",grid.xmap*0.d0, $
                                 "map_u_1mm",grid.xmap*0.d0, $
                                 "map_q_2mm",grid.xmap*0.d0, $
                                 "map_u_2mm",grid.xmap*0.d0)
     ;; if keyword_set(polar) then begin
     ;;    simpar_out1 = create_struct( simpar_out, $
     ;;                                 "map_q_1mm",xmap*0.d0, $
     ;;                                 "map_u_1mm",xmap*0.d0, $
     ;;                                 "map_q_2mm",xmap*0.d0, $
     ;;                                 "map_u_2mm",xmap*0.d0)
     ;; endif
     simpar = simpar_out
  endif


end
