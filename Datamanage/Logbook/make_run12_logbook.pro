

ls_unix, !nika.imb_fits_dir+"/*2015021*", flist, /silent

;; Discard the first scans of Feb 10th, that still belong to Run11 (open pool 3)
files         = file_basename( flist)
l             = strlen(files[0])
nfiles        = n_elements(files)
scan_list     = strarr( nfiles)
day_list      = lonarr( nfiles)
scan_num_list = lonarr( nfiles)
next          = strlen("-imb.fits")
niram         = strlen("iram30m-antenna-")
;; Need to loop, not all files have the same length because of scan_num
for i=0, nfiles-1 do begin
   l = strlen( files[i])
   scan_list[i] = strmid( files[i], niram, l-(niram+next))
   scan2daynum, scan_list[i], day, scan_num
   day_list[i] = long( day)
   scan_num_list[i] = scan_num
endfor

w = where( long(day_list) gt 20150210 or $
           ( long(day_list) eq 20150210 and scan_num_list gt 157))
flist = flist[w]

filesave_out = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_Run12_v0.save"
filecsv_out  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_Run12_v0.csv"
nk_log_iram_tel, flist, filesave_out, filecsv_out, /nonika

;; 
;; 
;; 
;; 
;; 
;; 
;; pro nk_log_iram_tel, flist, filesave_out, filecsv_out, $
;;                      nonika = nonika, verb = verb, $
;;                      undersample = k_undersample, notrim = k_notrim
;; 
;; ; Make a log book out of IRAM telescope data
;; ; Include opacity and sky noise from Nika
;; ; Can be run on sami and bambini and everywhereelse
;; ; flist is a list of imbfits files complete with directory
;; ;  this list does not need to be in chronological order
;; ; filesave_out is an idl saveset output (containing a structure)
;; ; filecsv_out is a filename to save .csv file (one line per scan)
;; ; e.g.
;; ;   ls_unix, diriram + '*201411*imb.fits', flist, /silent
;; ;        FOR i=0, nflist-1 DO print, i, '  --  ', flist[i] 
;; ;   filesave_out= '$SAVE/Log_Iram_tel_' + sav + '.save'
;; ;   filecsv_out=  '$SAVE/Log_Iram_tel_' + sav + '.csv'
;; ; undersample= 10 ; will not measure opacity for all scans
;; ; but one good scan every 10
;; ; undersample=10  ; output one file every 10
;; ; /notrim ; keep all scans with antenna imbfits present otherwise keep only
;; ; t21 and openpool scans (default)
;; nflist = n_elements( flist)
;; if keyword_set( k_undersample) then undersample = k_undersample $
;; else undersample = 1
;; 
;; scan = replicate( $
;;        { day:'', scannum: 0, object:'', operator:'', obsid: '', projid:'',  $
;;          ra_deg: 0D0, dec_deg:  0D0, $
;;          az_deg: 0D0, el_deg:0D0, parangle_deg:0D0, mjd: 0D0, $
;;          date:'', lst_sec:0D0, exptime:0. , nika_tobs:0., $
;;          n_obs: 0, n_obsp:0, obstype:'', polar: 0, $
;;          sysoff: '', nasx_arcsec:0., nasy_arcsec:0., $
;;          xoffset_arcsec: 0., yoffset_arcsec: 0., $
;;          switchmode: '', focusx_mm:0., focusy_mm:0., focusz_mm:0., $
;;          pressure_hPa: 0., tambient_C:0., $
;;          rel_humidity_percent: 0., windvel_mpers:0., $
;;          tiptau225GHz:0., tau1mm:!undef*1., tau2mm:!undef*1., $
;;          dir:'', file: '', $
;; ;         sitelong_deg:0D0, sitelat_deg:0D0, sitealt_m:0D0, $
;;          powlawamp1mm:0., powlawamp2mm:0., powlawexpo1mm:0., powlawexpo2mm:0., $
;;          skynoi1mm0:0.,skynoi1mm1:0.,skynoi1mm2:0.,skynoi1mm3:0., $
;;          skynoi1mm4:0.,skynoi1mm5:0.,skynoi1mm6:0.,skynoi1mm7:0.,$
;;          skynoi2mm0:0.,skynoi2mm1:0.,skynoi2mm2:0.,skynoi2mm3:0., $
;;          skynoi2mm4:0.,skynoi2mm5:0.,skynoi2mm6:0.,skynoi2mm7:0.$
;;        }, nflist)
;; if not keyword_set( nonika) then begin
;; ; Prepare opacity
;;    if !nika.run le 10 then day = '20141119'
;;    if !nika.run ge 11 then day = '20150123'
;;    scannum = 100               ; just one numbers
;;    scan_name = day+ 's'+strtrim( scannum, 2)
;;    nk_default_param, param
;;    nk_init_info, param, info
;;    info.status = 0
;;    param.silent= 1 - keyword_set( verb) 
;;    param.do_plot = 0            ; no plot
;;    param.plot_png = 0           ; Make png files
;;    param.flag_sat                     = 0 ; to be safe for the first iteration
;;    param.line_filter                  = 0 ; ditto
;;    param.flag_uncorr_kid              = 0 ; ditto
;;    param.corr_block_per_subscan       = 0
;;    param.median_common_mode_per_block = 0
;;    param.decor_method = 'COMMON_MODE_ONE_BLOCK'  ; robust fast method
;;    param.do_meas_atmo = 1    ; get atmo info from Nika
;;    param.w8_per_subscan      = 0
;;    param.fine_pointing       = 0
;;    param.imbfits_ptg_restore = 0 ; 0=default
;;    param.kill_noisy_sections = 0 ; 1 for weak sources only
;;    if !nika.run le 10 then param.decor_per_subscan = 'no' else $
;;       param.decor_per_subscan = 0
;;    param.polynomial        = 1
;;    param.decor_elevation   = 1
;; ;   param.no_opacity_correction = 0 ; get tau
;;    param.interpol_common_mode = 1
;;    param.math = 'RF' ; don't need pf
;;    param.renew_df = 2 ; to get the best opacities
;; ; Temporary work around
;;    newkfdir = '/home/desert/Soft/Nika/Processing/Kidpars/'
;;    newkfname = 'kidpar_20150123s137_v2.fits'
;;    if !nika.run eq 11 then begin
;;       param.file_kidpar = newkfdir+newkfname
;;       param.force_kidpar = 1
;;    endif else param.force_kidpar = 0
;; ; mask definition
;;    nk_init_grid, param, grid
;;    nk_default_mask, param, info, grid ; by default use 30" about
;; ;; Update param for the current scan
;;    nk_update_scan_param, scan_name, param, info
;; endif
;; 
;; 
;; FOR ifl = 0, nflist-1 DO BEGIN 
;;   file = flist[ ifl]
;;   if ifl mod 100 eq 0 and keyword_set( verb) then $
;;     print, ifl, '  ', file
;;   filename = file_basename( file)
;;   scan[ ifl].dir = file_dirname( file)
;;   scan[ ifl].file = filename
;; 
;;   da0 = mrdfits( file, 0, h0, /silent)
;; ;hview, h0, /xd
;;   da1 = mrdfits( file, 1, h1, /silent)
;; ;hview, h1, /xd
;;   da2 = mrdfits( file, 2, h2, /silent)
;; ;hview, h2, /xd (need IMBF-antenna)
;; 
;; 
;; ; Get info
;; date= sxpar( h0, 'DATE-OBS')
;; scan[ ifl].day = strmid( filename, 16, 8)
;; ; Not accurate enough
;; ; scan[ ifl].day = strmid( date, 0, 4)+ strmid( date, 5, 2)+ strmid( date, 8, 2)
;; scan[ ifl].scannum = sxpar( h1, 'SCANNUM')
;; ; useless
;; ;scan[ ifl].sitelong_deg = sxpar( h1, 'SITELONG')
;; ;scan[ ifl].sitelat_deg = sxpar( h1, 'SITELAT ')
;; ;scan[ ifl].sitealt_m = sxpar( h1, 'SITEELEV')
;; scan[ ifl].operator = strtrim( sxpar( h1, 'OPERATOR'), 2)
;; scan[ ifl].obsid = strtrim( sxpar( h1, 'OBSID'), 2)
;; 
;; 
;; scan[ ifl].object = strtrim( sxpar( h0, 'OBJECT'), 2)
;; scan[ ifl].ra_deg = sxpar( h0,'LONGOBJ')
;; scan[ ifl].dec_deg = sxpar( h0, 'LATOBJ')
;; if size( da2, /type) eq 8 then begin
;;    scan[ ifl].az_deg = da2[0].CAZIMUTH * !radeg ; commanded
;;    scan[ ifl].el_deg = da2[0].CELEVATIO * !radeg
;;    scan[ ifl].parangle_deg = da2[0].parangle * !radeg
;; endif   
;; scan[ ifl].mjd = sxpar( h0, 'MJD-OBS')
;; scan[ ifl].date = date
;; scan[ ifl].lst_sec = sxpar( h0,  'LST')
;; scan[ ifl].projid = strtrim( sxpar( h0, 'PROJID'), 2)
;; scan[ ifl].exptime = sxpar( h0,'EXPTIME')
;; scan[ ifl].N_OBS   = sxpar( h0,'N_OBS')
;; scan[ ifl].N_OBSP  = sxpar( h0,'N_OBSP')
;; scan[ ifl].OBSTYPE = strtrim( sxpar( h0,'OBSTYPE'), 2)
;; if size( da1, /type) eq 8 then begin
;;   scan[ ifl].sysoff = da1[0].sysoff
;;   scan[ ifl].nasx_arcsec = da1[0].xoffset*(!radeg * 3600)
;;   scan[ ifl].nasy_arcsec = da1[0].yoffset*(!radeg * 3600)
;; endif
;; 
;; ;;;;; THAT SHOULD BE cORRECTED
;; ; OK the data are hidden in P2COR and P7COR
;; scan[ ifl].xoffset_arcsec = sxpar( h1,'P2COR') * (!radeg * 3600)
;; scan[ ifl].yoffset_arcsec = sxpar( h1,'P7COR') * (!radeg * 3600)
;; scan[ ifl].switchmode = sxpar( h1, 'SWTCHMOD')
;; scan[ ifl].focusx_mm = sxpar( h1, 'FOCUSX')
;; scan[ ifl].focusy_mm = sxpar( h1, 'FOCUSY')
;; scan[ ifl].focusz_mm = sxpar( h1, 'FOCUSZ')
;; scan[ ifl].pressure_hPa = sxpar( h1, 'PRESSURE')
;; scan[ ifl].tambient_C = sxpar( h1, 'TAMBIENT')
;; scan[ ifl].rel_humidity_percent = sxpar( h1, 'HUMIDITY')
;; scan[ ifl].windvel_mpers = sxpar( h1, 'WINDVEL')
;; scan[ ifl].tiptau225GHz = sxpar( h1, 'TIPTAUZ')
;; 
;; 
;; 
;; ; exposure time is wrong for Lissajous
;; if strupcase( scan[ ifl].obstype) eq 'LISSAJOUS' then begin
;;   if size( da2, /type) eq 8 then begin
;;      scan[ ifl].mjd = da2[0].mjd
;;      scan[ ifl].exptime = (max(da2.mjd)-da2[0].mjd)*24.D0*3600.
;;   endif
;; endif
;; ENDFOR
;; 
;; ; Sort in chronological order
;; ind = sort( scan.mjd)
;; scan = scan[ ind]
;; 
;; ; Eliminate scans that don't belong to nika
;; if not keyword_set( k_notrim) then begin
;;    gdnika = where( strupcase( scan.projid) eq 'T21' or $
;;                  strmatch( strupcase( scan.obsid), '*POOL*'), ngdnika)
;;    if ngdnika ne 0 then begin
;;       scan = scan[ gdnika]
;;    endif else begin
;;       stop,  'No NIKA scans ?!'
;;    endelse
;; endif
;; 
;; nscan = n_elements( scan)
;; 
;; if not keyword_set( nonika) then begin
;; ; Do the opacity only for Lissajous, pointing and otf_maps
;;    good = where( strupcase(scan.obstype) eq 'LISSAJOUS' or $
;;                  strupcase(scan.obstype) eq 'POINTING' or $
;;                  strupcase(scan.obstype) eq 'ONTHEFLYMAP', ngood)
;; ;   if keyword_set( verb) then $
;;       print, 'Computing opacity and sky noise for ', $
;;              strtrim(ngood, 2), ' scans, one scan out of '+ $
;;              strtrim( undersample, 2)
;;    nfiproc = -1 ; counter
;;     for igood = 0, ngood-1, undersample do begin
;;        scancur = scan[ good[ igood]]
;;        nfiproc = nfiproc+1
;;        scan_name = scancur.day+ 's'+ strtrim(scancur.scannum, 2)
;;        
;;        if nfiproc mod 10 eq 0 then begin
;;           print, strtrim(nfiproc, 2)+' files were processed'
;;           print, strtrim(igood, 2), ' /  ', strtrim( ngood, 2), $
;;                  ' at scan '+scan_name
;;        endif else if keyword_set( verb) then print, $
;;              strtrim(igood, 2), ' /  ', strtrim( ngood, 2), $
;;              ' at scan '+scan_name
;; 
;;        nk_update_scan_param, scan_name, param, info
;;        info1 = info
;;        ; do a condensed version of nk
;;  ;; Perform all operations on data that are not projection nor cleaning dependent
;;        
;;        nk_scan_preproc, param, info1, data, kidpar, /noerror
;;        if info1.status eq 1 then goto, notau
;;          ;; processes, decorrelates, compute noise weights...
;;        nk_scan_reduce, param, info1, data, kidpar, grid
;;        if info1.status eq 1 then goto, notau
;;        scan[ good[ igood]].nika_tobs = n_elements(data)/!nika.f_sampling
;;        scan[ good[ igood]].polar = info1.polar
;;        scan[ good[ igood]].tau1mm = info1.tau_1mm
;;        scan[ good[ igood]].tau2mm = info1.tau_2mm
;;        scan[ good[ igood]].powlawamp1mm = info1.atmo_ampli_1mm
;;        scan[ good[ igood]].powlawamp2mm = info1.atmo_ampli_2mm
;;        scan[ good[ igood]].powlawexpo1mm = info1.atmo_slope_1mm
;;        scan[ good[ igood]].powlawexpo2mm = info1.atmo_slope_2mm
;;        scan[ good[ igood]].skynoi1mm0 = info1.fatm1mm_b1
;;        scan[ good[ igood]].skynoi1mm1 = info1.fatm1mm_b2
;;        scan[ good[ igood]].skynoi1mm2 = info1.fatm1mm_b3
;;        scan[ good[ igood]].skynoi1mm3 = info1.fatm1mm_b4
;;        scan[ good[ igood]].skynoi1mm4 = info1.fatm1mm_b5
;;        scan[ good[ igood]].skynoi1mm5 = info1.fatm1mm_b6
;;        scan[ good[ igood]].skynoi1mm6 = info1.fatm1mm_b7
;;        scan[ good[ igood]].skynoi1mm7 = info1.fatm1mm_b8
;;        scan[ good[ igood]].skynoi2mm0 = info1.fatm2mm_b1
;;        scan[ good[ igood]].skynoi2mm1 = info1.fatm2mm_b2
;;        scan[ good[ igood]].skynoi2mm2 = info1.fatm2mm_b3
;;        scan[ good[ igood]].skynoi2mm3 = info1.fatm2mm_b4
;;        scan[ good[ igood]].skynoi2mm4 = info1.fatm2mm_b5
;;        scan[ good[ igood]].skynoi2mm5 = info1.fatm2mm_b6
;;        scan[ good[ igood]].skynoi2mm6 = info1.fatm2mm_b7
;;        scan[ good[ igood]].skynoi2mm7 = info1.fatm2mm_b8
;; notau:
;;     endfor
;;     
;;    
;; ; Take the last known value when opacity is unknown
;;     scan.tau1mm = last_known_value( scan.tau1mm)
;;     scan.tau2mm = last_known_value( scan.tau2mm)
;;  endif else begin
;;     print, 'no nika data were ingested'
;;  endelse
;;  
;; save, file = filesave_out, scan, /verb, /xdr
;; 
;; ; Save as a csv file
;; list = strarr( nscan)
;; tagn = tag_names( scan)
;; ntag = n_tags( scan[0])
;; 
;; FOR ifl = 0, nscan-1 DO BEGIN
;;   bigstr = string( scan[ ifl].(0))
;;   FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( scan[ ifl].(itag))
;;   list[ ifl] = bigstr
;; ENDFOR
;; bigstr = tagn[ 0]
;; FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( tagn[itag])
;; 
;; list = [ bigstr, list]
;; write_file, filecsv_out, list, /delete
;; ; spawn, 'oocalc ' + filecsv_out +'&'
;; 
;; ; Do an .xls in 
;; ; $SAVE/Log_IRAM with oocalc
;; 
;; return
end
