
pro nk_log_iram_tel, flist, filesave_out, filecsv_out, $
                     nonika = nonika, verb = verb, $
                     undersample = k_undersample, notrim = k_notrim, $
                     noprocess = noprocess, rtaversion = rtaversion, $
                     tsubmax = tsubmax, norta = norta, method=method, n2run = k_n2run, $
                     run_polar = run_polar

; Make a log book out of IRAM telescope data
; Include opacity and sky noise from Nika
; Can be run on sami and bambini and everywhereelse
; flist is a list of imbfits files complete with directory
;  this list does not need to be in chronological order
; filesave_out is an idl saveset output (containing a structure)
; filecsv_out is a filename to save .csv file (one line per scan)
; e.g.
;   ls_unix, diriram + '*201411*imb.fits', flist, /silent
;        FOR i=0, nflist-1 DO print, i, '  --  ', flist[i] 
;   filesave_out= '$SAVE/Log_Iram_tel_' + sav + '.save'
;   filecsv_out=  '$SAVE/Log_Iram_tel_' + sav + '.csv'
; undersample= 10 ; will not measure opacity for all scans
; but one good scan every 10
; undersample=10  ; output one file every 10
; /notrim ; keep all scans with antenna imbfits present otherwise keep only
; t21 and openpool scans (default)
; /noprocess : used with a lot of
;    scans that have already been processed
;    by rta with version rtaversion e.g. 'v_1' and the result can be trusted
; if noprocess=-1 then do not reprocess what has already been done in
;   previous pipeline run
; noprocess=1 means do not reprocess any scan
; noprocess=0 means: do the heavy processing on all scans
;   tsubmax= max integration time for a scan to be processed (long files are
;   difficult to process on bambini with NIKA2
  ; /norta ; when working in offline processing mode (outside Pico computers)
nflist = n_elements( flist)
if keyword_set( k_undersample) then undersample = k_undersample $
else undersample = 1
if not keyword_set( rtaversion) then k_rta = 'v_1' else k_rta = rtaversion
if not keyword_set( norta) and not keyword_set( nonika) $
   then message, /info, 'RTA configuration'
if keyword_set( k_n2run) then n2run = k_n2run else n2run = 'N2R0'
scan = replicate( $
       { day:'', scannum: 0, object:'', operator:'', obsid: '', projid:'',  $
         run:'', config: '', $
         ra_deg: 0D0, dec_deg:  0D0, $
         az_deg: 0D0, el_deg:0D0, parangle_deg:0D0, mjd: 0D0, $
         date:'', lst_sec:0D0, exptime:0. , $  ;;nika_tobs:0., $
         total_obs_time:0., valid_obs_time:0., $
         nkids_valid1: 0,  nkids_valid2: 0,  nkids_valid3: 0, $ 
         n_obs: 0, n_obsp:0, obstype:'', polar: 0, $
         sysoff: '', nasx_arcsec:0., nasy_arcsec:0., $
         xoffset_arcsec: 0., yoffset_arcsec: 0., $
         switchmode: '', focusx_mm:0., focusy_mm:0., focusz_mm:0., $
         pressure_hPa: 0., tambient_C:0., $
         rel_humidity_percent: 0., windvel_mpers:0., $
         tiptau225GHz:0., tau1mm:!undef*1., tau2mm:!undef*1., $
         tau1:!undef*1., tau3:!undef*1., $
         dir:'', file: '', $
;         sitelong_deg:0D0, sitelat_deg:0D0, sitealt_m:0D0, $
         powlawamp1mm:0., powlawamp2mm:0., powlawexpo1mm:0., powlawexpo2mm:0., $
         skynoi1mm0:0.,skynoi1mm1:0.,skynoi1mm2:0.,skynoi1mm3:0., $
         skynoi1mm4:0.,skynoi1mm5:0.,skynoi1mm6:0.,skynoi1mm7:0.,$
         skynoi2mm0:0.,skynoi2mm1:0.,skynoi2mm2:0.,skynoi2mm3:0., $
         skynoi2mm4:0.,skynoi2mm5:0.,skynoi2mm6:0.,skynoi2mm7:0., $
; Add all photometric results here (see nk_default_info)
         ; FXD, 16/1/2018, reintegrate the 1 and 3 array results
         result_flux_I1:0d0, $             
         result_flux_I3:0d0, $             
         result_flux_I_1mm:0d0, $             
         result_flux_I_2mm:0d0, $             
         result_err_flux_I1:0d0, $         
         result_err_flux_I3:0d0, $         
         result_err_flux_I_1mm:0d0, $         
         result_err_flux_I_2mm:0d0, $         
         result_flux_Q1:0d0, $             
         result_flux_Q3:0d0, $             
         result_flux_Q_1mm:0d0, $ 
         result_flux_Q_2mm:0d0, $ 
         result_err_flux_Q1:0d0, $         
         result_err_flux_Q3:0d0, $         
         result_err_flux_Q_1mm:0d0, $
         result_err_flux_Q_2mm:0d0, $
         result_flux_U1:0d0, $             
         result_flux_U3:0d0, $             
         result_flux_U_1mm:0d0, $
         result_flux_U_2mm:0d0, $
         result_err_flux_U1:0d0, $         
         result_err_flux_U3:0d0, $         
         result_err_flux_U_1mm:0d0, $
         result_err_flux_U_2mm:0d0, $

         ;; Point source flux at the center
         result_flux_center_I1:0d0, $     
         result_flux_center_I3:0d0, $     
         result_flux_center_I_1mm:0d0, $     
         result_flux_center_I_2mm:0d0, $     
         result_err_flux_center_I1:0d0, $ 
         result_err_flux_center_I3:0d0, $ 
         result_err_flux_center_I_1mm:0d0, $
         result_err_flux_center_I_2mm:0d0, $
         result_flux_center_Q1:0d0, $     
         result_flux_center_Q3:0d0, $     
         result_flux_center_Q_1mm:0d0, $    
         result_flux_center_Q_2mm:0d0, $    
         result_err_flux_center_Q1:0d0, $ 
         result_err_flux_center_Q3:0d0, $ 
         result_err_flux_center_Q_1mm:0d0, $
         result_err_flux_center_Q_2mm:0d0, $
         result_flux_center_U1:0d0, $     
         result_flux_center_U3:0d0, $     
         result_flux_center_U_1mm:0d0, $
         result_flux_center_U_2mm:0d0, $
         result_err_flux_center_U1:0d0, $ 
         result_err_flux_center_U3:0d0, $ 
         result_err_flux_center_U_1mm:0d0, $
         result_err_flux_center_U_2mm:0d0, $

         ;; flux and errors at the center, derived by aperture photometry
         result_aperture_photometry_I1:0.d0, $
         result_err_aperture_photometry_I1:0.d0, $
         result_aperture_photometry_I3:0.d0, $
         result_err_aperture_photometry_I3:0.d0, $
         result_aperture_photometry_I_1mm:0.d0, $
         result_err_aperture_photometry_I_1mm:0.d0, $
         result_aperture_photometry_I_2mm:0.d0, $
         result_err_aperture_photometry_I_2mm:0.d0, $
         result_aperture_photometry_Q1:0.d0, $
         result_err_aperture_photometry_Q1:0.d0, $
         result_aperture_photometry_Q3:0.d0, $
         result_err_aperture_photometry_Q3:0.d0, $
         result_aperture_photometry_Q_1mm:0.d0, $
         result_err_aperture_photometry_Q_1mm:0.d0, $
         result_aperture_photometry_Q_2mm:0.d0, $
         result_err_aperture_photometry_Q_2mm:0.d0, $
         result_aperture_photometry_U1:0.d0, $
         result_err_aperture_photometry_U1:0.d0, $
         result_aperture_photometry_U3:0.d0, $
         result_err_aperture_photometry_U3:0.d0, $
         result_aperture_photometry_U_1mm:0.d0, $
         result_err_aperture_photometry_U_1mm:0.d0, $
         result_aperture_photometry_U_2mm:0.d0, $
         result_err_aperture_photometry_U_2mm:0.d0, $

         hwp_rot_freq:0.d0, $
         f_sampling:0.d0, $
         result_pol_deg_1mm:0.d0,  $       ; polarization degree where the source is fitted
         result_err_pol_deg_1mm:0.d0,  $   ; error on the degree of polarization
         result_pol_deg_2mm:0.d0,  $       ; polarization degree where the source is fitted
         result_err_pol_deg_2mm:0.d0,  $   ; error on the degree of polarization
         result_pol_angle_1mm:0.d0,  $     ; polarization angle where the source is fitted
         result_err_pol_angle_1mm:0.d0,  $ ; error on the angle of polarization
         result_pol_angle_2mm:0.d0,  $     ; polarization angle where the source is fitted
         result_err_pol_angle_2mm:0.d0,  $ ; error on the angle of polarization

         result_off_x1:0d0, $  ; Point source position array1
         result_off_y1:0.d0, $ ; Point source position
         result_fwhm_x1:0.d0, $
         result_fwhm_y1:0.d0, $
         result_fwhm1:0.d0, $
         result_off_x3:0d0, $  ; Point source position array3
         result_off_y3:0.d0, $ ; Point source position 
         result_fwhm_x3:0.d0, $
         result_fwhm_y3:0.d0, $
         result_fwhm3:0.d0, $
         result_off_x_1mm:0d0, $  ; Point source position at 1mm
         result_off_y_1mm:0.d0, $ ; Point source position at 1mm
         result_fwhm_x_1mm:0.d0, $
         result_fwhm_y_1mm:0.d0, $
         result_fwhm_1mm:0.d0, $
         result_off_x_2mm:0d0, $ ;Point source position at 2mm
         result_off_y_2mm:0.d0, $
         result_fwhm_x_2mm:0.d0, $
         result_fwhm_y_2mm:0.d0, $
         result_fwhm_2mm:0.d0, $

         result_nefd_I_1mm:0d0, $ ;NEFD at 1mm
         result_nefd_I_2mm:0d0, $ ;NEFD at 2mm
         result_nefd_Q_1mm:0d0, $ ;NEFD (Q) at 1mm
         result_nefd_Q_2mm:0d0, $ ;NEFD (Q) at 2mm
         result_nefd_U_1mm:0d0, $ ;NEFD (U) at 1mm
         result_nefd_U_2mm:0d0, $ ;NEFD (U) at 2mm

         result_nefd_center_I1:0d0, $ ;NEFD at the map center array1
         result_nefd_center_I3:0d0, $ ;NEFD at the map center array3
         result_nefd_center_I_1mm:0d0, $ ;NEFD at the map center 1mm
         result_nefd_center_I_2mm:0d0, $ ;NEFD at the map center 2mm
         result_nefd_center_Q1:0d0, $ ;NEFD at the map center (Q) A1
         result_nefd_center_Q3:0d0, $ ;NEFD at the map center (Q) A3
         result_nefd_center_Q_1mm:0d0, $ ;NEFD at the map center (Q) at 1mm
         result_nefd_center_Q_2mm:0d0, $ ;NEFD at the map center (Q) at 2mm
         result_nefd_center_U1:0d0, $ ;NEFD at the map center (U) array1
         result_nefd_center_U3:0d0, $ ;NEFD at the map center (U) array3
         result_nefd_center_U_1mm:0d0, $ ;NEFD at the map center (U) at 1mm
         result_nefd_center_U_2mm:0d0,  $ ;NEFD at the map center (U) at 2mm
         nika2run:n2run,  $ ; FXD April 2020, was not well documented before (filled here seeby nk_get_all_scan)
         comment:'none'}, nflist)
restagn = tag_names( scan)
restag = where( strmid(restagn, 0, 6) eq 'RESULT' or $
                strupcase(restagn) eq "HWP_ROT_FREQ" or $
                strupcase(restagn) eq "F_SAMPLING")
if not keyword_set( nonika) then begin
; Prepare opacity
   if !nika.run le 10 then day = '20141119'
   if !nika.run ge 11 then day = '20150123'
   scannum = 100                ; just one numbers
   scan_name = day+ 's'+strtrim( scannum, 2)
   nk_default_param, param
   param.glitch_width = 100
   nk_init_info, param, info
   info.status = 0
   param.project_dir = !nika.plot_dir+'/Log_Iram_tel' ; default directory that can be erase at the end
   param.plot_dir = param.project_dir+'/Plot'
   param.interpol_common_mode = 1
   param.do_plot  = 1           ; Show plots or not (ps does not work without 1)
   param.plot_ps = 1            ; Make ps files
   param.latex_pdf = 1          ; Make a pdf 
   param.clean_tex = 1          ; clean all aux data
   param.silent= 1 - keyword_set( verb) 
   param.plot_png = 0           ; do not make png files
   param.noerror = 1            ; continue working even if no file could be found
   param.delete_all_windows_at_end = 1

   param.flag_sat                     = 1 ; 0 to be safe for the first iteration

   ;;-- added NP, Aug. 29th, 2017
   param.flag_oor = 1
   param.flag_ovlap = 1
   ;;--
   
   param.line_filter                  = 0 ; ditto
   param.flag_uncorr_kid              = 0 ; ditto
   param.corr_block_per_subscan       = 0
   param.median_common_mode_per_block = 0
; Apparently (march 2017), commmon mode one block gives better FWHM
; and NEFD with 
   if keyword_set(method) then param.decor_method = method else $
      param.decor_method = 'COMMON_MODE_ONE_BLOCK' ; robust fast method
;   param.decor_method = 'COMMON_MODE_KIDS_OUT' ; exclude central source

   param.do_meas_atmo = 1       ; get atmo info from Nika
   param.w8_per_subscan      = 0
   param.fine_pointing       = 1 ; better pointing solution
   param.imbfits_ptg_restore = 1 ; 0=default
   param.kill_noisy_sections = 0 ; 1 for weak sources only
   if tag_exist(param, 'do_aperture_photometry') then $
      param.do_aperture_photometry = 1
   if !nika.run le 10 then param.decor_per_subscan = 'yes' else $
      param.decor_per_subscan = 1
   param.polynomial        = 1
   param.decor_elevation   = 1
;   param.no_opacity_correction = 0 ; get tau
;;;;   do_opacity_correction:2 is default
   param.interpol_common_mode = 1
;   param.math = 'RF' ; PF is default
   param.math = 'PF'
;   param.renew_df = 2 ; 2 is default to get the best opacities
;; Compute df_tone in the latest way
   param.renew_df = 2
; Temporary work around
  ;; newkfdir = '/home/desert/NIKA/Save/Run23/Plots/'
  ;; newkfname = 'kidpar_N2R10.fits'
  ;; if !nika.run eq 23 then begin
  ;;    param.file_kidpar = newkfdir+newkfname
  ;;    param.force_kidpar = 1
  ;; endif else param.force_kidpar = 0
   param.nsigma_corr_block = 1
   param.decor_elevation   = 1
   param.version           = 1
   if !nika.run eq '16' then begin 
; quickfix for run4 (for the time being)
                                ; Not yet final but must be used
      kpfname=!nika.off_proc_dir+'/kidpar_run4_withskydip_20160427_recal.fits'
      param.file_kidpar=kpfname
      param.force_kidpar = 1
   endif
   if !nika.run eq '18' then begin 
; quickfix for run6 (for the time being)
                                ; Not yet final but must be used
      kpfname= !nika.off_proc_dir+ $
               '/kidpar_20161010s37_v3_skd8_match_calib_NP_recal_FR.fits'
      param.file_kidpar=kpfname
      param.force_kidpar = 1
   endif
   
   nk_default_info, info
   param.map_reso = 2D0
   param.map_xsize = 900D0
   param.map_ysize = 900D0
;;   param.decor_cm_dmin = 60  ; 100 recommended by Nicolas 17/3/2017, 60 JMP
   param.mask_default_radius = 60     ; 100 recommended by Nicolas 17/3/2017, 60 JMP
;;; mask definition
   nk_init_grid, param, info, grid
   nk_default_mask, param, info, grid, radius = 20. ; use 20" exclusion radius from the center
;; Update param for the current scan
;   nk_update_scan_param, scan_name, param, info
   paramin = param
   infoin = info
   gridin = grid
endif


FOR ifl = 0, nflist-1 DO BEGIN 
   file = flist[ ifl]
   if ifl mod 100 eq 0 and keyword_set( verb) then $
      print, ifl, '  ', file
   filename = file_basename( file)
   scan[ ifl].dir = file_dirname( file)
   scan[ ifl].file = filename

   da0 = mrdfits( file, 0, h0, /silent, status = status)
   if status lt 0 then print, 'h0 ', status, ' for ', file, ' not taken'
   if status lt 0 then continue
;hview, h0, /xd
   da1 = mrdfits( file, 1, h1, /silent, status = status)
   if status lt 0 then print, 'h1 ', status, ' for ', file
;hview, h1, /xd
   da2 = mrdfits( file, 2, h2, /silent, status = status)
   if status lt 0 then print, 'h2 ', status, ' for ', file
;hview, h2, /xd (need IMBF-antenna)
                                ; In case that the program stops here
                                ; because of one corrupted file, one
                                ; can do .skip 1 then .c


; Get info
   date= sxpar( h0, 'DATE-OBS')
   scan[ ifl].day = strmid( filename, 16, 8)
; Not accurate enough
; scan[ ifl].day = strmid( date, 0, 4)+ strmid( date, 5, 2)+ strmid( date, 8, 2)
   scan[ ifl].scannum = sxpar( h1, 'SCANNUM')
   scan_name = scan[ ifl].day+'s'+strtrim( scan[ ifl].scannum, 2)
; useless
;scan[ ifl].sitelong_deg = sxpar( h1, 'SITELONG')
;scan[ ifl].sitelat_deg = sxpar( h1, 'SITELAT ')
;scan[ ifl].sitealt_m = sxpar( h1, 'SITEELEV')
   scan[ ifl].operator = strtrim( sxpar( h1, 'OPERATOR'), 2)
   scan[ ifl].obsid = strtrim( sxpar( h1, 'OBSID'), 2)


   scan[ ifl].object = strtrim( sxpar( h0, 'OBJECT'), 2)
   scan[ ifl].ra_deg = sxpar( h0,'LONGOBJ')
   scan[ ifl].dec_deg = sxpar( h0, 'LATOBJ')
   if size( da2, /type) eq 8 then begin
      tagn = tag_names( da2)
      if total(strmatch( tagn, 'CAZIMUTH')) ge 1 then begin
         scan[ ifl].az_deg = da2[0].CAZIMUTH * !radeg ; commanded
         scan[ ifl].el_deg = da2[0].CELEVATIO * !radeg
         scan[ ifl].parangle_deg = da2[0].parangle * !radeg
      endif                     ; if not known: wrong receiver
   endif   
   scan[ ifl].mjd = sxpar( h0, 'MJD-OBS')
   scan[ ifl].date = date
   scan[ ifl].lst_sec = sxpar( h0,  'LST')
   scan[ ifl].projid = strtrim( sxpar( h0, 'PROJID'), 2)
   scan[ ifl].exptime = sxpar( h0,'EXPTIME')
   scan[ ifl].N_OBS   = sxpar( h0,'N_OBS')
   scan[ ifl].N_OBSP  = sxpar( h0,'N_OBSP')
   scan[ ifl].OBSTYPE = strtrim( sxpar( h0,'OBSTYPE'), 2)
   if size( da1, /type) eq 8 then begin
      scan[ ifl].sysoff = da1[0].sysoff
      scan[ ifl].nasx_arcsec = da1[0].xoffset*(!radeg * 3600)
      scan[ ifl].nasy_arcsec = da1[0].yoffset*(!radeg * 3600)
   endif

;;;;; THAT SHOULD BE cORRECTED
; OK the data are hidden in P2COR and P7COR
   scan[ ifl].xoffset_arcsec = sxpar( h1,'P2COR') * (!radeg * 3600)
   scan[ ifl].yoffset_arcsec = sxpar( h1,'P7COR') * (!radeg * 3600)
   scan[ ifl].switchmode = sxpar( h1, 'SWTCHMOD')
   scan[ ifl].focusx_mm = sxpar( h1, 'FOCUSX')
   scan[ ifl].focusy_mm = sxpar( h1, 'FOCUSY')
   scan[ ifl].focusz_mm = sxpar( h1, 'FOCUSZ')
   scan[ ifl].pressure_hPa = sxpar( h1, 'PRESSURE')
   scan[ ifl].tambient_C = sxpar( h1, 'TAMBIENT')
   scan[ ifl].rel_humidity_percent = sxpar( h1, 'HUMIDITY')
   scan[ ifl].windvel_mpers = sxpar( h1, 'WINDVEL')
   scan[ ifl].tiptau225GHz = sxpar( h1, 'TIPTAUZ')
   nk_scan2run, scan_name, run, status
   if status gt 0 then stop, ' Problem with that scan '+ scan_name
   scan[ ifl].run = run

   direx = strsplit( !nika.raw_acq_dir, '/', /extract, count = count)
   if count ge 1 then direx = direx[count-1]
   scan[ ifl].config = direx

; exposure time is wrong for Lissajous
   if strupcase( scan[ ifl].obstype) eq 'LISSAJOUS' then begin
      if size( da2, /type) eq 8 then begin
         scan[ ifl].mjd = da2[0].mjd
         scan[ ifl].exptime = (max(da2.mjd)-da2[0].mjd)*24.D0*3600.
      endif
   endif
ENDFOR


; Sort in chronological order
ind = sort( scan.mjd)
scan = scan[ ind]

; Eliminate scans that don't belong to nika
if not keyword_set( k_notrim) then begin
   gdnika = where( strupcase( scan.projid) eq 'T21' or $
                   strupcase( scan.projid) eq 'T22' or $
                   strmatch( strupcase( scan.obsid), '*POOL*') or $
                   strmid(strupcase( scan.projid), 0, 4) eq 'NIKA', ngdnika)
   if ngdnika ne 0 then begin
      scan = scan[ gdnika]
   endif else begin
      message, /info,  'No NIKA scans ?!'
      return
   endelse
endif

nscan = n_elements( scan)

;; Get the "comment" keyword in the xml file to tell which scans
;; belong to OTF focus sequences
;; New feature, Feb. 22nd, 2017
for i=0, nscan-1 do begin
   xml_file = !nika.xml_dir+"/iram30m-scan-"+scan[i].day+"s"+strtrim(scan[i].scannum,2)+".xml"
   if file_test( xml_file) then begin
      spawn, "grep -i comment "+xml_file, res
      if res ne '' then begin
         junk = strsplit( res, "value=", /ex, /reg)
         junk = strsplit( junk[1], " ", /ex, /reg)
         comment = strmid( junk[0],1)
         scan[i].comment = strmid( comment, 0, strlen(comment)-1)
      endif
   endif
endfor

if not keyword_set( nonika) then begin
   tint = scan.exptime
   u = where( strupcase(scan.obstype) eq 'LISSAJOUS', nu)
   if nu ne 0 then tint[u] = scan[u].exptime*scan[u].n_obs

   if keyword_set( tsubmax) then tsu = tsubmax else tsu = 10000.
; Do the opacity only for Lissajous, pointing and otf_maps and skydips
   good = where( (strupcase(scan.obstype) eq 'LISSAJOUS' or $
                 strupcase(scan.obstype) eq 'POINTING' or $
                 strupcase(scan.obstype) eq 'ONTHEFLYMAP' or $
                 strupcase(scan.obstype) eq 'TIPCURRENTAZIMUTH' or $
                 strupcase(scan.obstype) eq 'DIY') and $
                 tint le tsu, ngood)
;   if keyword_set( verb) then $
   print, 'Computing opacity, sky noise and photometry+polar for '
   print, strtrim(ngood, 2), ' scans, one scan every '+ $
          strtrim( undersample, 2)

; New method: Use nk and do maps as well

   nfiproc = -1                 ; counter
   for igood = 0, ngood-1, undersample do begin
      scancur = scan[ good[ igood]]
      nfiproc = nfiproc+1
      scan_name = scancur.day+ 's'+ strtrim(scancur.scannum, 2)
      param = paramin
      info = infoin
      grid = gridin
      if nfiproc mod 10 eq 0 then begin
         print, strtrim(nfiproc, 2)+' files were processed'
         print, strtrim(igood, 2), ' /  ', strtrim( ngood, 2), $
                ' at scan '+scan_name
      endif else if keyword_set( verb) then print, $
         strtrim(igood, 2), ' /  ', strtrim( ngood, 2), $
         ' at scan '+scan_name
      param.map_center_ra = !values.d_nan ; Necessary re-init
      param.map_center_dec = !values.d_nan
      if not keyword_set( noprocess) then begin
         ;; To start from scratch do:
         nk_reset_filing, param, scan_name
         source = strtrim( strupcase(scancur.object), 2)
         lsplanet = [ 'MERCURE', 'VENUS', 'MARS', $
                      'JUPITER', 'SATURNE', 'URANUS', 'NEPTUNE']
         if total( strmatch(lsplanet, strtrim(strupcase(source), 2))) ge 1 or $
            strupcase(strmid( strtrim(source, 2), 0, 4)) eq 'BODY' then begin
            param.map_proj = 'AZEL'
         endif

         nk, scan_name, param = param, info = info, $
             grid = grid, /filing, no_output_map = 0, astr=astr
         file = param.project_dir+'/v_'+strtrim( param.version, 2)+ '/'+$
                scan_name+ '/results.save'
      endif else begin

         ;; Restore the information for each scan (Should erase temp dirs TBD) 
; not working
         file = !nika.plot_dir+ '/'+k_rta + '/'+$
                 scan_name+ '/results.save'
         if keyword_set( norta) then $
            file = param.project_dir+'/v_'+strtrim( param.version, 2)+ '/'+$
                scan_name+ '/results.save'
         if noprocess lt 0 then begin 
            ;; do the processing if it has not been done yet (with /filing)
            nk, scan_name, param = param, info = info, $
                grid = grid, /filing, no_output_map = 0, astr=astr
            file = param.project_dir+'/v_'+strtrim( param.version, 2)+ '/'+$
                   scan_name+ '/results.save'
         endif
      endelse

      if file_test( file) then begin
         restore, file
         infrestagn = tag_names( info1)
;         infrestag = where( strmid( infrestag, 0, 6) eq 'RESULT')
         match, restagn[ restag], infrestagn, idxa, idxb
;         scan[ good[ igood]].nika_tobs = n_elements(data)/!nika.f_sampling
         scan[ good[ igood]].polar = info1.polar
         scan[ good[ igood]].tau1mm = info1.result_tau_1mm
         scan[ good[ igood]].tau2mm = info1.result_tau_2mm
         scan[ good[ igood]].tau1 = info1.result_tau_1
         scan[ good[ igood]].tau3 = info1.result_tau_3
         scan[ good[ igood]].total_obs_time = info1.result_total_obs_time
         scan[ good[ igood]].valid_obs_time = info1.result_valid_obs_time
         scan[ good[ igood]].nkids_valid1 = info1.result_nkids_valid1
         scan[ good[ igood]].nkids_valid2 = info1.result_nkids_valid2
         scan[ good[ igood]].nkids_valid3 = info1.result_nkids_valid3
         scan[ good[ igood]].powlawamp1mm = info1.atmo_ampli_1mm
         scan[ good[ igood]].powlawamp2mm = info1.atmo_ampli_2mm
         scan[ good[ igood]].powlawexpo1mm = info1.atmo_slope_1mm
         scan[ good[ igood]].powlawexpo2mm = info1.atmo_slope_2mm
         scan[ good[ igood]].skynoi1mm0 = info1.fatm1mm_b1
         scan[ good[ igood]].skynoi1mm1 = info1.fatm1mm_b2
         scan[ good[ igood]].skynoi1mm2 = info1.fatm1mm_b3
         scan[ good[ igood]].skynoi1mm3 = info1.fatm1mm_b4
         scan[ good[ igood]].skynoi1mm4 = info1.fatm1mm_b5
         scan[ good[ igood]].skynoi1mm5 = info1.fatm1mm_b6
         scan[ good[ igood]].skynoi1mm6 = info1.fatm1mm_b7
         scan[ good[ igood]].skynoi1mm7 = info1.fatm1mm_b8
         scan[ good[ igood]].skynoi2mm0 = info1.fatm2mm_b1
         scan[ good[ igood]].skynoi2mm1 = info1.fatm2mm_b2
         scan[ good[ igood]].skynoi2mm2 = info1.fatm2mm_b3
         scan[ good[ igood]].skynoi2mm3 = info1.fatm2mm_b4
         scan[ good[ igood]].skynoi2mm4 = info1.fatm2mm_b5
         scan[ good[ igood]].skynoi2mm5 = info1.fatm2mm_b6
         scan[ good[ igood]].skynoi2mm6 = info1.fatm2mm_b7
         scan[ good[ igood]].skynoi2mm7 = info1.fatm2mm_b8
         scan[ good[ igood]].result_aperture_photometry_I_1mm = info1.result_aperture_photometry_I_1mm
         scan[ good[ igood]].result_aperture_photometry_Q_1mm = info1.result_aperture_photometry_Q_1mm
         scan[ good[ igood]].result_aperture_photometry_U_1mm = info1.result_aperture_photometry_U_1mm
         scan[ good[ igood]].result_aperture_photometry_I_2mm = info1.result_aperture_photometry_I_2mm
         scan[ good[ igood]].result_aperture_photometry_Q_2mm = info1.result_aperture_photometry_Q_2mm
         scan[ good[ igood]].result_aperture_photometry_U_2mm = info1.result_aperture_photometry_U_2mm
         scan[ good[ igood]].result_err_aperture_photometry_I_1mm = info1.result_err_aperture_photometry_I_1mm
         scan[ good[ igood]].result_err_aperture_photometry_Q_1mm = info1.result_err_aperture_photometry_Q_1mm
         scan[ good[ igood]].result_err_aperture_photometry_U_1mm = info1.result_err_aperture_photometry_U_1mm
         scan[ good[ igood]].result_err_aperture_photometry_I_2mm = info1.result_err_aperture_photometry_I_2mm
         scan[ good[ igood]].result_err_aperture_photometry_Q_2mm = info1.result_err_aperture_photometry_Q_2mm
         scan[ good[ igood]].result_err_aperture_photometry_U_2mm = info1.result_err_aperture_photometry_U_2mm
         scan[ good[ igood]].result_aperture_photometry_I1 = info1.result_aperture_photometry_I1
         scan[ good[ igood]].result_aperture_photometry_Q1 = info1.result_aperture_photometry_Q1
         scan[ good[ igood]].result_aperture_photometry_U1 = info1.result_aperture_photometry_U1
         scan[ good[ igood]].result_err_aperture_photometry_I1 = info1.result_err_aperture_photometry_I1
         scan[ good[ igood]].result_err_aperture_photometry_Q1 = info1.result_err_aperture_photometry_Q1
         scan[ good[ igood]].result_err_aperture_photometry_U1 = info1.result_err_aperture_photometry_U1
;         scan[ good[ igood]].result_aperture_photometry_I2 = info1.result_aperture_photometry_I2
;         scan[ good[ igood]].result_aperture_photometry_Q2 = info1.result_aperture_photometry_Q2
;         scan[ good[ igood]].result_aperture_photometry_U2 = info1.result_aperture_photometry_U2
;         scan[ good[ igood]].result_err_aperture_photometry_I2 = info1.result_err_aperture_photometry_I2
;         scan[ good[ igood]].result_err_aperture_photometry_Q2 = info1.result_err_aperture_photometry_Q2
;         scan[ good[ igood]].result_err_aperture_photometry_U2 = info1.result_err_aperture_photometry_U2
         scan[ good[ igood]].result_aperture_photometry_I3 = info1.result_aperture_photometry_I3
         scan[ good[ igood]].result_aperture_photometry_Q3 = info1.result_aperture_photometry_Q3
         scan[ good[ igood]].result_aperture_photometry_U3 = info1.result_aperture_photometry_U3
         scan[ good[ igood]].result_err_aperture_photometry_I3 = info1.result_err_aperture_photometry_I3
         scan[ good[ igood]].result_err_aperture_photometry_Q3 = info1.result_err_aperture_photometry_Q3
         scan[ good[ igood]].result_err_aperture_photometry_U3 = info1.result_err_aperture_photometry_U3
         scan[ good[ igood]].result_flux_I1        = info1.result_flux_I1    
         scan[ good[ igood]].result_flux_I3        = info1.result_flux_I3    
         scan[ good[ igood]].result_flux_I_1mm     = info1.result_flux_I_1mm    
         scan[ good[ igood]].result_flux_I_2mm     = info1.result_flux_I_2mm    
         scan[ good[ igood]].result_err_flux_I1 = info1.result_err_flux_I1
         scan[ good[ igood]].result_err_flux_I3 = info1.result_err_flux_I3
         scan[ good[ igood]].result_err_flux_I_1mm = info1.result_err_flux_I_1mm
         scan[ good[ igood]].result_err_flux_I_2mm = info1.result_err_flux_I_2mm
         scan[ good[ igood]].result_flux_Q1        = info1.result_flux_Q1    
         scan[ good[ igood]].result_flux_Q3        = info1.result_flux_Q3    
         scan[ good[ igood]].result_flux_Q_1mm     = info1.result_flux_Q_1mm    
         scan[ good[ igood]].result_flux_Q_2mm     = info1.result_flux_Q_2mm    
         scan[ good[ igood]].result_err_flux_Q1    = info1.result_err_flux_Q1
         scan[ good[ igood]].result_err_flux_Q3    = info1.result_err_flux_Q3
         scan[ good[ igood]].result_err_flux_Q_1mm = info1.result_err_flux_Q_1mm
         scan[ good[ igood]].result_err_flux_Q_2mm = info1.result_err_flux_Q_2mm
         scan[ good[ igood]].result_flux_U1        = info1.result_flux_U1    
         scan[ good[ igood]].result_flux_U3        = info1.result_flux_U3    
         scan[ good[ igood]].result_flux_U_1mm     = info1.result_flux_U_1mm    
         scan[ good[ igood]].result_flux_U_2mm     = info1.result_flux_U_2mm    
         scan[ good[ igood]].result_err_flux_U1    = info1.result_err_flux_U1
         scan[ good[ igood]].result_err_flux_U3    = info1.result_err_flux_U3
         scan[ good[ igood]].result_err_flux_U_1mm = info1.result_err_flux_U_1mm
         scan[ good[ igood]].result_err_flux_U_2mm = info1.result_err_flux_U_2mm

         ;; Point source flux at the center
         scan[ good[ igood]].result_flux_center_I1        = info1.result_flux_center_I1
         scan[ good[ igood]].result_flux_center_I3        = info1.result_flux_center_I3
         scan[ good[ igood]].result_flux_center_I_1mm     = info1.result_flux_center_I_1mm    
         scan[ good[ igood]].result_flux_center_I_2mm     = info1.result_flux_center_I_2mm    
         scan[ good[ igood]].result_err_flux_center_I1    = info1.result_err_flux_center_I1
         scan[ good[ igood]].result_err_flux_center_I3    = info1.result_err_flux_center_I3
         scan[ good[ igood]].result_err_flux_center_I_1mm = info1.result_err_flux_center_I_1mm
         scan[ good[ igood]].result_err_flux_center_I_2mm = info1.result_err_flux_center_I_2mm
         scan[ good[ igood]].result_flux_center_Q1        = info1.result_flux_center_Q1    
         scan[ good[ igood]].result_flux_center_Q3        = info1.result_flux_center_Q3    
         scan[ good[ igood]].result_flux_center_Q_1mm     = info1.result_flux_center_Q_1mm    
         scan[ good[ igood]].result_flux_center_Q_2mm     = info1.result_flux_center_Q_2mm    
         scan[ good[ igood]].result_err_flux_center_Q1    = info1.result_err_flux_center_Q1
         scan[ good[ igood]].result_err_flux_center_Q3    = info1.result_err_flux_center_Q3
         scan[ good[ igood]].result_err_flux_center_Q_1mm = info1.result_err_flux_center_Q_1mm
         scan[ good[ igood]].result_err_flux_center_Q_2mm = info1.result_err_flux_center_Q_2mm
         scan[ good[ igood]].result_flux_center_U1        = info1.result_flux_center_U1   
         scan[ good[ igood]].result_flux_center_U3        = info1.result_flux_center_U3   
         scan[ good[ igood]].result_flux_center_U_1mm     = info1.result_flux_center_U_1mm    
         scan[ good[ igood]].result_flux_center_U_2mm     = info1.result_flux_center_U_2mm    
         scan[ good[ igood]].result_err_flux_center_U1    = info1.result_err_flux_center_U1
         scan[ good[ igood]].result_err_flux_center_U3    = info1.result_err_flux_center_U3
         scan[ good[ igood]].result_err_flux_center_U_1mm = info1.result_err_flux_center_U_1mm
         scan[ good[ igood]].result_err_flux_center_U_2mm = info1.result_err_flux_center_U_2mm

; find the first tag_names in info1
         for it = 0, n_elements( idxa)-1 do $
            scan[ good[ igood]].(restag[ idxa[ it]]) = info1.( idxb[ it])

      endif else if keyword_set( verb) then $
         message,/info, 'No results for '+ scan_name
   endfor
   
; Take the last known value when opacity is unknown
   scan.tau1mm = last_known_value( scan.tau1mm)
   scan.tau2mm = last_known_value( scan.tau2mm)
   scan.tau1 = last_known_value( scan.tau1)
   scan.tau3 = last_known_value( scan.tau3)
endif else begin
   print, 'no nika data were ingested'
endelse
if keyword_set( run_polar) and keyword_set(nonika) then scan.polar = 1 ; better than nothing
print, 'Save logbook in', filesave_out
save, file = filesave_out, scan, /verb, /xdr

; Save as a csv file
list = strarr( nscan)
tagn = tag_names( scan)
ntag = n_tags( scan[0])

FOR ifl = 0, nscan-1 DO BEGIN
   bigstr = string( scan[ ifl].(0))
   FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( scan[ ifl].(itag))
   list[ ifl] = bigstr
ENDFOR
bigstr = tagn[ 0]
FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( tagn[itag])

list = [ bigstr, list]
write_file, filecsv_out, list, /delete
; spawn, 'oocalc ' + filecsv_out +'&'

; Do an .xls in 
; $SAVE/Log_IRAM with oocalc

return
end
