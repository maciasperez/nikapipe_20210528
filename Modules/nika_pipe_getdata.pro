;+
;PURPOSE: This procedure get the data according to the required
;         scan. It select the valid part of the scan, rejects the
;         unused tones, rephase I,Q,dI,dQ with RFdIdQ, and makes a
;         structure containing the data used in the pipeline.
;
;INPUT: The parameter structure.
;
;OUTPUT: The data structure.
;
;LAST EDITION: 26/02/2012
;   2013: Creation (adam@lpsc.in2p3.fr)
;   March 2013: update (nicolas.ponthieu@obs.ujf-grenoble.fr)
;   April 2013: update  Catalano (catalano@lpsc.in2p3.fr)
;   May 2013: unit conversion (adam@lpsc.in2p3.fr)
;   Oct. 2013: retard corrected in read_nika_brute now, so the retard
;   used in read_nika_brut does not include RF_dIdQ shifts
;   (Alain, macias@lpsc.in2p3.fr, adam@lpsc.in2p3.fr)
;-

pro nika_pipe_getdata, param, data, kidpar, $
                       list_data = list_data, $
                       ext_params=ext_params, $
                       nocut=nocut, $
                       one_mm_only=one_mm_only, $
                       two_mm_only=two_mm_only, $
                       pf=pf, $
                       debug=debug, $
                       force_file=force_file, $
                       silent=silent, $
                       all_kids=all_kids, $
                       param_c=param_c, $
                       param_d=param_d, $
                       in_retard=in_retard,$
                       make_products=make_products,$
                       simu=simu, $
                       no_bandpass=no_bandpass, $
                       no_acq_flag=no_acq_flag,  $
                       jump = jump, $
                       noerror = noerror
  
  if n_params() lt 1 then begin
     message, /info, "Calling sequence:"
     print, " nika_pipe_getdata, param, data, kidpar, $"
     print, "                    list_data = list_data, $"
     print, "                    ext_params=ext_params, $"
     print, "                    nocut=nocut, $"
     print, "                    one_mm_only=one_mm_only, $"
     print, "                    two_mm_only=two_mm_only, $"
     print, "                    pf=pf, $"
     print, "                    debug=debug, $"
     print, "                    force_file=force_file, $"
     print, "                    silent=silent, all_kids=all_kids, $"
     print, "                    param_c=param_c, param_d=param_d, in_retard=in_retard, $"
     print, "                    make_products=make_products, $"
     print, "                    simu=simu, no_bandpass = no_bandpass"
     return
  endif

  ;;------- Init the structure !nika with the appropriate Run
  day2run, param.day[param.iscan], run
  fill_nika_struct, run
  
  ;;------- In case of simulated data, only need conversion coeffs
  if keyword_set(simu) then goto, suite1
  
  ;;------- Force the retard if requested
  if keyword_set(in_retard) then retard = in_retard $
  else retard = !nika.retard

  ;;------------- List what we want to read
  if not keyword_set( list_data) then begin
     list_data = "subscan scan El retard "+strtrim(retard,2) + $
                 " ofs_Az ofs_El Az Paral scan_st MJD LST SAMPLE B_t_utc A_t_utc" + $
                 " I Q dI dQ F_tone dF_tone RF_didq A_masq B_masq c_position c_synchro k_flag MAP_TBM"
;; FXD MAP_TBM is the dilution temperature, will only exist if recompile
;; read_nika. 16-May-2014
  endif
  
  my_list_data = strsplit( list_data, " ", /extract)
  w = where( strupcase(my_list_data) eq "ALL", nw)
  if nw eq 0 then begin
     add_params = 0             ; default
     new_params = strarr(1)
     if keyword_set(ext_params) then new_params = [new_params, ext_params]
     if n_elements(new_params) gt 1 then begin
        ;; remove the first dummy element of new_params if present
        new_params = new_params[1:*]
        
        ;; add to list_data only if not already present
        my_list_data = strsplit( list_data, " ", /extract)
        for i=0, n_elements(new_params)-1 do begin
           w = where( strupcase(my_list_data) eq strupcase( new_params[i]), nw)
           if nw eq 0 then list_data = list_data+" "+new_params[i]
        endfor
     endif
  endif

  ;;------- Select the KIDs to be used
  if keyword_set(one_mm_only) then begin
     indexdetecteurdebut = 0
     nb_detecteurs_lu    = 400
  endif
  if keyword_set(two_mm_only) then begin
     indexdetecteurdebut = 400
     nb_detecteurs_lu    = 800
  endif
  if keyword_set(all_kids) then begin
     indexdetecteurdebut = 0
     nb_detecteurs_lu    = 800
  endif
  
  ;;------------- Read data
  suite1:                       ;Case of simulated data (get the corresponding files)
  
  if not keyword_set(force_file) then begin
     nika_find_raw_data_file, param.scan_num[param.iscan], param.day[param.iscan], file_scan, imb_fits_file, silent = silent, noerror = noerror
  endif else begin 
     file_scan = force_file
     imb_fits_file = ''
  endelse
  file_scan = file_scan[0]      ; some weird cases give 2 files instead of one
  if keyword_set( noerror) and strlen( file_scan) eq 0 then goto, nodata
  param.data_file = file_scan
  param.imb_fits_file = imb_fits_file[0]
  file2nickname, file_scan, nickname
  param.nickname = nickname

  if keyword_set(simu) then goto, suite2 ;No need to read the data if simulated
  
  rr = read_nika_brute(file_scan, param_c, kidpar, data0, units, param_d=param_d, $
                       list_data=list_data, read_type=12, $;indexdetecteurdebut=indexdetecteurdebut, nb_detecteurs_lu=nb_detecteurs_lu, $
                       amp_modulation=amp_modulation, /silent)


  if size( data0, /type) ne 8 then begin
     goto,  nodata
  endif
  
  ;;------- Convert f_tone and df_tone to Hz
  if tag_exist( data0, 'f_tone') then data0.f_tone *= 1d3
  if tag_exist( data0, 'df_tone') then data0.df_tone *= 1d3
  
  ;;------- If PF or CF is explicitely set, overwrite param.math to maintain compatibility
  if keyword_set(pf) then param.math = "PF"
  if keyword_set(cf) then param.math = "CF"

  ;;------- Replace RFdIdQ by the polynom if requested
  if strupcase(param.math) eq "PF" then begin
     ndeg = 3
     if tag_exist( param_c, "AF_MOD")  then afmod = double( param_c.AF_MOD)*1000.d0
     if tag_exist( param_c, "A_F_MOD") then afmod = double( param_c.A_F_MOD)
     if tag_exist( param_c, "BF_MOD")  then bfmod = double( param_c.BF_MOD)*1000.d0
     if tag_exist( param_c, "B_F_MOD") then bfmod = double( param_c.B_F_MOD)
     
     freqnormA = afmod          ; /2.    ; 2500. Hz most of the time
     freqnormB = bfmod          ; /2.    ; 1000. Hz most of the time
     
     ;; Pass these values to !nika to access them in e.g. nika_pipe_deglitch
     !nika.freqnormA = freqnormA
     !nika.freqnormB = freqnormB
     !nika.pf_ndeg   = ndeg
     if ndeg gt 0 and freqnormA gt 0. and n_elements(data0.I) gt 1 then $
        nika_conviq2pf, data0, kidpar, dapf, ndeg, [freqnormA, freqnormB]
     data0.rf_didq = -dapf      ;The flux is positive
  endif

  ;;---------- RFdIdQ is set positif and numdet id forced to raw_num
  data0.rf_didq = -data0.rf_didq
  kidpar.numdet = kidpar.raw_num
  
  ;;------- Deal with kidpar
  if strlen( param.kid_file.a[param.iscan]) gt 1 and strlen( param.kid_file.b[param.iscan]) gt 1 then begin
     if not keyword_set( silent) then begin
        message, /info, "kidpar_a = "+param.kid_file.a[param.iscan]
        message, /info, "kidpar_b = "+param.kid_file.b[param.iscan]
     endif
     
     tags  = tag_names(kidpar)
     ntags = n_elements(tags)
     input_kid_file = [param.kid_file.a[param.iscan], param.kid_file.b[param.iscan]]
     for ifile=0, 1 do begin
        filex = file_test( input_kid_file[ifile])
        if filex ne 1 then message, 'This file does not exist: '+ strtrim(input_kid_file[ifile], 2)
        kidpar_a = mrdfits( input_kid_file[ifile], 1, /silent)
        tags_a   = tag_names(kidpar_a)
        ntags_a  = n_elements( tags_a)
        
        for i=0, n_elements(kidpar_a)-1 do begin
           wdet = where( kidpar.numdet eq kidpar_a[i].numdet, nwdet)
           
           if nwdet gt 1 then message, strtrim(nwdet,2)+" kids have the same numdet = "+$
                                       strtrim(kidpar_a[i].numdet,2)+" ?!"
           if nwdet eq 1 then begin
              for j=0, ntags_a-1 do begin
                 wtag = where( strupcase( tags) eq strupcase(tags_a[j]), nwtag)
                 if nwtag ne 0 then kidpar[wdet].(wtag) = kidpar_a[i].(j)
              endfor
           endif
        endfor
     endfor

  endif else begin              ;initialize kidpar

     ;; default init with lab values
     wa = where( strupcase(kidpar.acqbox) eq 0, nwa)
     wb = where( strupcase(kidpar.acqbox) eq 1, nwb)
     if nwa ne 0 then kidpar[wa].array = 1                ; make sure
     if nwb ne 0 then kidpar[wb].array = 2                ; make sure
     if nwa ne 0 then kidpar[wa].lambda = !nika.lambda[0] ; make sure
     if nwb ne 0 then kidpar[wb].lambda = !nika.lambda[1] ; make sure
     
     ;; update with flight configuration
     if strmid(param.day[param.iscan], 0, 6) eq '201211' then begin
        wa = where( strupcase(kidpar.acqbox) eq 1, nwa)
        wb = where( strupcase(kidpar.acqbox) eq 2, nwb)
        if nwa ne 0 then begin
           kidpar[wa].lambda = !nika.lambda[0]
           kidpar[wa].array  = 1
        endif
        if nwb ne 0 then begin
           kidpar[wb].lambda = !nika.lambda[1]
           kidpar[wb].array  = 2
        endif
     endif

     if tag_exist( param_c, "AF_MOD")  then afmod = double( param_c.AF_MOD)*1000.d0
     if tag_exist( param_c, "A_F_MOD") then afmod = double( param_c.A_F_MOD)
     if tag_exist( param_c, "BF_MOD")  then bfmod = double( param_c.BF_MOD)*1000.d0
     if tag_exist( param_c, "B_F_MOD") then bfmod = double( param_c.B_F_MOD)
     
     if nwa ne 0 then kidpar[wa].df = afmod
     if nwb ne 0 then kidpar[wb].df = bfmod
  endelse

; stop
  ;;------------- Extend structure "data" with flags and weights
  new_struct = {flag:lonarr(n_elements(kidpar)),$
                on_source_dec:intarr(n_elements(kidpar)), $
                on_source_w8:intarr(n_elements(kidpar)), $
                on_source_zl:intarr(n_elements(kidpar)), $
                w8:dblarr(n_elements(kidpar))}
  upgrade_struct, data0, new_struct, data
  data.w8 += 1                  ;(i.e. no w8 if module w8 off)
  
  ;;------- Flag the first 49 samples since RFdIdQ is not well computed here
  nsn = n_elements(data)
  nika_pipe_addflag, data, 7, wsample=lindgen(48)
  if strupcase(param.math) eq "RF" then nika_pipe_addflag, data, 7, wsample=nsn-1-lindgen(50)

  ;; Resample the pointing timelines to account for a non integer "retard" (aka zigzag)
  if tag_exist( !nika, "ptg_shift") then begin
     nsn = n_elements( data)
     index = dindgen(nsn)
     index_shift = index + !nika.ptg_shift
     n_ind_shift = round( abs(!nika.ptg_shift))
     
     tags = ["ofs_az", "ofs_el", "el", "paral", "lst", "mjd"]
     for i=0, n_elements(tags)-1 do begin
        cmd = "data."+tags[i]+" = interpol( data."+tags[i]+", index, index_shift)"
        junk = execute(cmd)
     endfor
     nika_pipe_addflag, data, 8, wsample=lindgen(n_ind_shift+1)
     nika_pipe_addflag, data, 8, wsample=lindgen(n_ind_shift+1)-n_ind_shift-1+nsn
  endif
  
  ;;------- Flag based on kid type 
  loc2 = where(kidpar.type eq 2, nloc2)
  loc3 = where(kidpar.type ge 3, nloc3)
  if nloc2 ne 0 then nika_pipe_addflag, data, 1, wkid=loc2
  if nloc3 ne 0 then nika_pipe_addflag, data, 6, wkid=loc3

  ;;----------Are we in november 2012? If yes add the ampli modulation
  if strmid(param.day[param.iscan], 0, 6) eq '201211' then begin
     the_struc = {amp_mod:0}
     upgrade_struct, kidpar, the_struc, kidpar_bis
     w = where(kidpar.array eq 1, nw)
     if nw ne 0 then kidpar_bis[w].amp_mod = amp_modulation[0]
     w = where(kidpar.array eq 2, nw)
     if nw ne 0 then kidpar_bis[w].amp_mod = amp_modulation[1]
     kidpar = kidpar_bis
  endif

  ;;------------- Compute unit coefficients using the bandpasses
  suite2:                       ;The simulation needs this
  if strmid(param.day[param.iscan], 0, 6) eq '201211' then begin
     bp_file = !nika.soft_dir+'/OldRuns_pipeline/Run5_pipeline/Calibration/BP/NIKA_bandpass_Run5.fits'
     beam_file1mm = !nika.soft_dir+'/OldRuns_pipeline/Run5_pipeline/Calibration/Beam/NIKA_beam_Run5_best1mm.fits'
     beam_file2mm = !nika.soft_dir+'/OldRuns_pipeline/Run5_pipeline/Calibration/Beam/NIKA_beam_Run5_best2mm.fits'
  endif
  if strmid(param.day[param.iscan], 0, 6) eq '201306' then begin
     bp_file = !nika.soft_dir+'/OldRuns_pipeline/Run6_pipeline/Calibration/BP/NIKA_bandpass_Run6.fits'
     beam_file1mm = !nika.soft_dir+'/OldRuns_pipeline/Run6_pipeline/Calibration/Beam/NIKA_beam_Run6_best1mm.fits'
     beam_file2mm = !nika.soft_dir+'/OldRuns_pipeline/Run6_pipeline/Calibration/Beam/NIKA_beam_Run6_best2mm.fits'
  endif
  if strmid(param.day[param.iscan], 0, 6) eq '201311' then begin
     bp_file = !nika.soft_dir+'/OldRuns_pipeline/RunCryo_pipeline/Calibration/BP/NIKA_bandpass_RunCryo.fits'
     beam_file1mm = !nika.soft_dir+'/OldRuns_pipeline/RunCryo_pipeline/Calibration/Beam/NIKA_beam_RunCryo_best1mm.fits'
     beam_file2mm = !nika.soft_dir+'/OldRuns_pipeline/RunCryo_pipeline/Calibration/Beam/NIKA_beam_RunCryo_best2mm.fits'
  endif
  if strmid(param.day[param.iscan], 0, 6) eq '201401' then begin
     bp_file = !nika.soft_dir+'/Pipeline/Calibration/BP/NIKA_bandpass_Run7.fits'
     beam_file1mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run8_best1mm.fits'
     beam_file2mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run8_best2mm.fits'
  endif
  ;; enable "dry run" too
;  if strmid(param.day[param.iscan], 0, 6) eq '201402' or $
;     strmid(param.day[param.iscan], 0, 6) eq '201405' then begin
  ;; change a bit to be able to look at June lab data (NP)
  ;; Add October to be able to read data with nika_pipe_getdata
; Add november 2014
  if long( strmid(param.day[param.iscan], 0, 6)) ge 201402 and $
     long( strmid(param.day[param.iscan], 0, 6)) le 201411 then begin
     bp_file = !nika.soft_dir+'/Pipeline/Calibration/BP/NIKA_bandpass_Run8.fits'
     beam_file1mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run8_best1mm.fits'
     beam_file2mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run8_best2mm.fits'
  endif
  if long( strmid(param.day[param.iscan], 0, 6)) ge 201501 and $
     long( strmid(param.day[param.iscan], 0, 6)) le 201503 then begin
     bp_file = !nika.soft_dir+'/Pipeline/Calibration/BP/NIKA_bandpass_Run8.fits'
     beam_file1mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run8_best1mm.fits'
     beam_file2mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run8_best2mm.fits'
  endif

  if long( strmid(param.day[param.iscan], 0, 6)) ge 201501 then begin
     bp_file = !nika.soft_dir+'/Pipeline/Calibration/BP/NIKA_bandpass_Run8.fits'
     beam_file1mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run8_best1mm.fits'
     beam_file2mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run8_best2mm.fits'
  endif

  nika_pipe_unit_conv, !nika.lambda[0], bp_file, $
                       Kcmb2Krj1mm, Ytsz2Kcmb1mm, Yksz2Kcmb1mm, Ytsz2JyPerSr1mm,$ ; Yksz2JyPerSr1mm, $
                       colcor_dust1mm, colcor_radio1mm, no_bandpass=no_bandpass
  
  nika_pipe_unit_conv, !nika.lambda[1], bp_file, $
                       Kcmb2Krj2mm, Ytsz2Kcmb2mm, Yksz2Kcmb2mm, Ytsz2JyPerSr2mm, $ ;Yksz2JyPerSr2mm, $
                       colcor_dust2mm, colcor_radio2mm, no_bandpass=no_bandpass
  
  beam_vol1mm = nika_pipe_measure_beam_volume(!nika.lambda[0], beam_file1mm)
  beam_vol2mm = nika_pipe_measure_beam_volume(!nika.lambda[1], beam_file2mm)
  
  param.KRJperKCMB.A = Kcmb2Krj1mm
  param.KCMBperY.A = Ytsz2Kcmb1mm
  param.JYperKRJ.A = beam_vol1mm*(!pi/3600/180)^2 * 2/(!nika.lambda[0]*1d-3)^2*!const.k * 1d26 ;We need to integrate over nu as well? Not sure because BP in RJ?
  
  param.KRJperKCMB.B = Kcmb2Krj2mm
  param.KCMBperY.B = Ytsz2Kcmb2mm
  param.JYperKRJ.B = beam_vol2mm*(!pi/3600/180)^2 * 2/(!nika.lambda[1]*1d-3)^2*!const.k * 1d26 ;We need to integrate over nu as well? Not sure because BP in RJ?
  
  if keyword_set(make_products) then begin
     coeff1mm = {Kcmb2Krj:Kcmb2Krj1mm,$
                 y2Kcmb:Ytsz2Kcmb1mm,$
                 Krj2JyperB:param.JYperKRJ.A,$
                 JYperB2JYperSr:1.0/(beam_vol1mm*(!pi/180/3600)^2)}
     coeff2mm = {Kcmb2Krj:Kcmb2Krj2mm,$
                 y2Kcmb:Ytsz2Kcmb2mm,$
                 Krj2JyperB:param.JYperKRJ.B,$
                 JYperB2JYperSr:1.0/(beam_vol2mm*(!pi/180/3600)^2)}
     
     mwrfits, coeff1mm, param.output_dir+'/NIKA_unit_conversion.fits', /create, /silent
     bidon = mrdfits(param.output_dir+'/NIKA_unit_conversion.fits',1,head_coeff, /silent)
     head1mm = head_coeff
     fxaddpar, head1mm, 'CONT1', 'K_CMB to K_RJ at 1mm', ''
     fxaddpar, head1mm, 'CONT2', 'y Compton to K_CMB at 1mm', ''
     fxaddpar, head1mm, 'CONT3', 'K_RJ to Jy/Beam at 1mm', ''
     fxaddpar, head1mm, 'CONT4', 'Jy/Beam to Jy/sr at 1mm', ''
     head2mm = head_coeff
     fxaddpar, head2mm, 'CONT1', 'K_CMB to K_RJ at 2mm', ''
     fxaddpar, head2mm, 'CONT2', 'y Compton to K_CMB at 2mm', ''
     fxaddpar, head2mm, 'CONT3', 'K_RJ to Jy/Beam at 2mm', ''
     fxaddpar, head2mm, 'CONT4', 'Jy/Beam to Jy/sr at 2mm', ''
     
     mwrfits, coeff1mm, param.output_dir+'/NIKA_unit_conversion.fits',head1mm, /create, /silent
     mwrfits, coeff2mm, param.output_dir+'/NIKA_unit_conversion.fits',head2mm, /silent
     
     ;;spawn, "cp -f "+bp_file+' '+param.output_dir+'/NIKA_bandpass.fits'
     spawn, "/bin/cp -f "+bp_file+' '+param.output_dir+'/NIKA_bandpass.fits'
  endif
  
  ;;------- Acquisition flags
  if not keyword_set(no_acq_flag) then begin
     ;; Flag data using Alain tunning flags !!
     nika_pipe_acqflag2pipeflag, param, data, kidpar

     ;; Flag nan values on some scans
     nika_pipe_nan_flag, param, data, kidpar

     ;; Flag from scan status
     nika_pipe_flag_scanst, param, data, kidpar

     ;; Flag from *_masq
     nika_pipe_tuningflag, param, data, kidpar

     ;; Flag dilution temperature glitch
     nika_pipe_tdilflag, param, data, kidpar
  endif
  
  nika_pipe_get_dftone, param, data, kidpar, param_d
  
  ;; If requested, correct for jumps. Do not do it by default until fully
  ;; checked
  if keyword_set(jump) then nika_pipe_jump,  param, data, kidpar


goto, fin

nodata: data = -1
if not keyword_set( silent) then print, 'No data for that scan ', file_scan

fin: if not keyword_set( silent) then print, 'End of nika_pipe_getdata'

end
