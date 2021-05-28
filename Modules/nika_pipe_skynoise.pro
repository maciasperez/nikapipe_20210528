;+
;PURPOSE: Get opacity and sky noise
;   derived from nika_pipe_launch
;      This is the main procedure of the pipeline which 
;         reduces NIKA's data to maps.
;
;INPUT: Name of the parmeter file used for the reduction.
;       If this file does not exist or if you want to use a new set of
;       parameters, it has to be created using a script such as
;       ngc1068_v1.pro
;
;OUTPUT: The combined map, from all the scan used (It is also saved as
;        a fits with astrometry).
;
;KEYWORDS:
;   1 - given_head_map: Give a predefined header that you want to use
;       in this keyword
;   2 - simu: Set this keyword if you use the pipeline with simulated data
;   3 - pf: Set this keyword if you want to use a polynomial
;       reconstruction of the resonance frequency instead of the
;       RFdIdQ method
;   4 - ext_params: Give the additional parameters that you want to
;       extract in the data structure when reading the binary data
;   5 - silent: Set this keyword if you do not want to print details
;       about the reading data process
;   6 - noskydip: Set this keyword if you do no want to correct for
;       the opacity from skydips
;   7 - bad_kids: Give the kids numdet that you want to reject
;   8 - add_source: Use this keyword to add a source by hand in the data 
;          a) Disk: add_source = {type:'disk',$
;                                 flux_a:0, $
;                                 flux_b:-0.2, $
;                                 radius:120}
;          b) Add point source: add_source = {type:'point_source',$
;                                             flux_a:0.0032,$
;                                             flux_b:0.0044} 
;          c) Add gNFW cluster: add_source = {type:'cluster',$
;                                             z:0.45,$
;                                             M_500:0, $
;                                             P0:526e-12,$
;                                             a:0.9,b:5.0,c:-0.003,rs:406.0}
;          d) Add gNFW cluster + point source: 
;             add_source = {type:'cluster+ps',$
;                           cluster:{z:0.45,$
;                                    M_500:0,$
;                                    P0:526e-12,$
;                                    a:0.9,b:5.0,c:-0.003,rs:406.0},$
;                            ps:{xc:6,$
;                                yc:0,$
;                                flux_a:0.0032,$
;                                flux_b:0.0044}}
;   9 - check_toi_in: Set this keyword to plot the raw (calibrated)
;       TOI and power spectrum
;   10 - check_toi_out: Set this keyword to plot the TOI and power
;        spectrum befor projection
;   11 - azel: Set this keyword if you want the map to be in Azimuth-Elevation and not in R.A.-Dec.
;   12 - kidlist: List of KIDs you want to use for the mapmaking
;   13 - map_per_KID: Set this keyword if you want to produce a scan combined map per detector
;   14 - save_mpkps: Set this keyword if you want to produce also
;        a map per kid per scan
;   15 - png: Set this keyword to save the maps per scan as png
;   16 - ps: Set this keyword to save the maps per scan as ps
;   17 - range_plot_scan_a: Give the range of the 1mm scan maps in this keyword, as a two component vector:[min, max]
;   18 - range_plot_scan_b: Give the range of the 2mm scan maps in this
;        keyword, as a two component vector:[min, max]
;   19 - make_products: Set this keyword to save the TOI and MAPs in FITS
;        for external astronomers
;   20 - var2fits: Set this keyword to save the variance map in fits
;        files instead of the stddev map
;   21 - show_deglitch: set this keyword to compare data before and
;        after deglitching
;   22 - cor_calib: 2 component vector that apply a correctif factor
;        to the calibration (usefull for Run5 and Run6 data that are
;        biased by -5% at 2mm and -30% at 1mm)
;   23 - nocut: set this keyword if you do not want to cut the
;        begining and the end of the scan (often crapy)
;   24 - meas_atm: set this keyword to take a look at the common mode
;        and its power spectrum
;   25 - cf: improved pf method
;   26 - use_noise_from_map: set this keyword if you want to use the
;        noise map computed from the map itself (and not the TOI) for
;        the weights when combining individual scan maps.
;   27 - extent_source: source extention in arcsec. Usefull for gain
;        elevation correction
;   28 - check_flag_cor: set this keyword to check the flagging
;        performed based on the lack of correlation between KIDs
;   29 - check_flag_speed: set this keyword to check the flagging
;        performed based on the scanning speed
;   30 - bypass_error: set this keyword to bypass the error in order
;        to still process all scans
;   31 - no_merge_fig: set this keyword if you do not want to combine
;        figures in one
;   32 - no_acq_flag: set this keyword if you do not want to apply
;        acquisition flags
;   33 - rm_points: set this keyword to the number of points over
;        which the data should be average. This reduces
;        !nika.f_sampling by the same amount
;   34 - make_logbook: set this keyword to produce the logbook
;   35 - plot_decor_toi: produce a plot with all timelines decorrelated
;
;LAST EDITION: 
;   2013: add the possibility to read simulated data (remi.adam@lpsc.in2p3.fr)
;   2013: adapted to Run6 data format (Nicolas.Ponthieu@obs.ujf-grenoble.fr)
;   2013: adapted to opaciy corrections from skydips results
;(catalano@lpsc.in2p3.fr)
;   21/09/2013: possibility to define precisely the header or to use a
;               given one (adam@lpsc.in2p3.fr)
;   20/11/2013: add module for atmospheric noise characterization
;   03/01/2014: add module for gain-elevation correction
;   06/01/2014: flagging and cut of the scan improved
;   07/01/2014: flagging with tuning and anomalous speed added
;   08/01/2014: keyword bypass_error added
;   15/02/2014: Deglitch the data after decorrelation
;   16/02/2014: Force the number of sample to be an even number
;-

pro nika_pipe_skynoise, param, silent = silent, ibeg = ibeg, iend = iend
  ;;####### Get the sky noise and opacity for individual scans 
  nscans = n_elements(param.scan_list) ;Number of scans
  if not keyword_set( ibeg) then ibeg = 0
  if not keyword_set( iend) then iend = nscans-1 else $
     iend = iend < (nscans-1)
  for iscan = ibeg, iend do begin
     param.iscan = iscan
     if iscan mod 10 eq 0 then print, 'Start ', strtrim( iscan,2), ' scan out of  ',  strtrim( nscans-1, 2)
     ;;------- Get the data
     nika_pipe_getdata, param, data, kidpar,silent = silent, /noerror
     Npt = n_elements(data)
     if Npt le 100 or size( data, /type) ne 8 then continue
     if max(data.subscan) le 0 then continue
     if long(Npt)/long(2) ne double(Npt)/double(2) then data = data[1:*] ;I want even number of samples
     ;;------- Cut the scan (flag) and add subscan to lissajous
     param.scan_type[param.iscan] = nika_pipe_findtypescan(param, data, silent=silent)

     
     nika_pipe_cutscan, param, data, loc_ok, loc_bad=loc_bad ;, /safe
     if loc_bad[0] ne -1 then nika_pipe_addflag, data, 8, wsample=loc_bad

     if param.scan_type[param.iscan] eq 'lissajous' then $ 
        nika_pipe_lissajou_select, param, data, kidpar, $
                                   good = loc_ok, silent=silent

     wcut = nika_pipe_wflag(data.flag[0], [7,8], nflag=nflag, $
                            comp=w_nocut, ncomp=nw_nocut)
 
     ;;------- Correct the pointing from antenna data
     nika_pipe_corpointing, param, data, kidpar, $
                            azel=azel, w_ok=w_nocut, silent = silent
     
     ;;----- Calibrate the data 
     if param.glitch.iq eq 0 then $
        nika_pipe_opacity, param, data, kidpar, silent = silent $
     else print, param.glitch.iq, ' should be 0'
     ; opacity is in param.tau_list

; Do not correct from opacity with /noskydip to measure the skynoise
; at the instrument level
     if param.glitch.iq eq 0 then nika_pipe_calib, param, data, kidpar, /noskydip $
     else print, param.glitch.iq, ' should be 0'
     
     ;;------- Flag KIDs that are far from the resonance, jumps, bad KIDs
     nika_pipe_outofres, param, data, kidpar, /bypass
     nika_pipe_flagkid, param, data, kidpar, silent = silent

     ;;------- The data can be cut once saved for astronomers
     Npt = n_elements(w_nocut)
     if npt le 100 then continue  ; don't do anything for that scan
     data = data[w_nocut]
     Npt = n_elements(data)
     if long(Npt)/long(2) ne double(Npt)/double(2) then $
        data = data[1:*]        ;I want even number of samples

     param.integ_time[iscan] = n_elements(data)/!nika.f_sampling

     ;;------- Measure the atmospheric noise and check x_correlations
     nika_pipe_measure_atmo, param, data, kidpar, /noplot
     ; data stored in param.meas_atmo
     ;;------- Print the scan number
     if not keyword_set( silent) then begin
        message, /info, 'Opacity and skynoise computed for the scan '+ $
                 strtrim(iscan+1,2)+'/'+strtrim(nscans,2)+': '+ $
                 strtrim(param.scan_list[param.iscan])
        message, /info, 'Integration time: '+strtrim(param.integ_time[iscan],2)+' seconds'
        print, ' '
     endif
     ;;------- Reset the structure !nika
     reset_nika_struct
  endfor  

  return
end
