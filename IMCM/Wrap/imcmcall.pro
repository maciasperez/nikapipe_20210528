;+
;
; SOFTWARE: imcm
;
; NAME:
;   imcmcall
;
; CATEGORY: general
;
; CALLING SEQUENCE:
; imcmcall, source, $
;              mapra, mapdec, $
;              mapxsize, mapysize, mapreso, $
;              method_num, ext, version, $
;              scanlist, $
;              iter_min,  iter_max, $
;              nharm1 = nharm_subscan1mm, nharm2 = nharm_subscan2mm, $
;              param_modifier = param_modifier, $
;              help = k_help, silent= silent, $
;              simpar = simparfile, $
;              cat_snr_min = cat_snr_min, input_cat = input_cat, $
;              infout = info_all, $
;              only_plot = only_plot, png = k_png, pdf = k_pdf, $
;              iterplot = k_iterplot, image_max = image_max
;   
; PURPOSE: 
;   wrapper for imcm, especially method 120+  
; 
; INPUT: 
;       - source  ; String Name of the source
;       - mapra, mapdec  ; float, degrees. Center of final map
;       - mapxsize, mapysize, mapreso  ; arcsecond. Map size and
;           pixel size
;       - method_num  ; String ; which method e.g. '120'
;       - ext, version  ; String  ; All output will be in
;         !nika.save_dir+'/'+ext  ; Version (string) gives a
;flexibility of naming, within the same ext different attempts with
;different parameters 
;       - scanlist ; string array containing the list of scan names
;         e.g. '20190120s189'
;       
;    
; OUTPUT: 
;       - infout= info_all ; array of info structure, one per scan. to
;         check housekeeping.
;       - otherwise all outputs are in
;         !nika.save_dir+'/'+ext+'/'+source
;       - imcmin : a directory where inputs are written for
;         traceability. It contains the
;         inputs scans and the script parameters in 2 files
;       - imcmout contains the final catalogs : one per iteration,
;         done on the same sources (a merge position catalog of 1 and
;2mm sources)
;       - method_num directory: contains all other outputs (for
;         example the list of retained scan). One
;         subdirectory per iteration.
;         iter0, iter1, ...
;         these subdirectories contain a Plot subdirectory where maps
;and housekeeping parameter plots are given, in particular something
;called merge++detect.pdf contains the maps with source number given
;in the final catalogs. In these subdirectories, you will find the
; fits maps (maps.fits and maps_JK.fits) that contain signal,
;noise, number of hits for the arrays and the wavelengths 1 and
;2mm. JK is for a jack-knife operation
;(cancelling the sources but not the noise).
;You will also find photometry.csv that contains
;housekeeping results per scan.
; The final maps are in  method_num directory  map and map_JK +
;source name + method_num+version+iter .fits     
; 
; KEYWORDS:
;       - iter_min, iter_max ; integer. imcm iteration limits. Process
;         can be resumed by adjusting these values
;       - nharm1, nharm2 : integer >= 1, the main tuning variables of
;         method 120 (how many harmonics to be filtered out, one
;harmonic is one cos, one sin)
;       - param_modifier ; string array if need to specify some
;         parameters e.g. if one wants param.flag=0 write
;param_modifier='flag = 0'  (remove param. It will taken care of)
;         another example can be 'reset_preproc_data=1' in order to
;recompute preprocessed data
;       - /help  ; do nothing but say the plan (in order to check the
;         consistency)
;       - /silent  ; i.e. less verbose
;       - simpar= simparfile ; for simulations
;       - cat_snr_min= ; float. Which minimum SNR do we keep for the
;         point-source catalog (default 3)
;       - input_cat= ; string a catalog of input positions instead of
;         the pgrm finding the positions on its own
;       - /only_plot  ; redo the plots and catalogs only (do not run
;         imcm, supposed to have happened before)
;       - /png  ; makes png files (overriden by /pdf)
;       - /pdf  ; makes pdf files as plot outputs
;       - iterplot= ; integer if one needs only plots and catalogs for
;         one iteration
;       - image_max = [mm1max,mm2max] ; 2 floats to give the range of
;         output images (default is [5, 2] mJy/beam)
; SIDE EFFECT:
;       
; EXAMPLE:
; source = 'HR8799'
; mapreso = 2.
; mapxsize = 20.*60
; mapysize = 20.*60
; method_num = '120'
; ext = 'imcmcall'
; version = 'A'
; scan= nk_get_source_scanlist(source, nscan)
; scan = scan[100:109]
; scanlist = scan.day + 's' + strtrim(scan.scannum,2)
; mapra    = scan[0].ra_deg
; mapdec   = scan[0].dec_deg
; iter_min = 0
; iter_max = 2
; nharm1 = 2
; nharm2 = 2
; imcmcall, source, $
;               mapra, mapdec, $
;               mapxsize, mapysize, mapreso, $
;               method_num, ext, version, $
;               scanlist, $
;               iter_min,  iter_max, $
;               nharm1 = nharm1, nharm2 = nharm2, /pdf
; 
;   
; MODIFICATION HISTORY: 
;        - ; FXD 12 Nov 2020 : introduced to help spread imcm usage, tested with
;          method 120. Run the example to make sure that the setup is
;in place
;================================================================================================
pro imcmcall, source, $
              mapra, mapdec, $
              mapxsize, mapysize, mapreso, $
              method_num, ext, version, $
              scanlist, $
              iter_min,  iter_max, $
              nharm1 = nharm1, nharm2 = nharm2, $
              nsubscan = nsubscan, $
              filt_time1 = filt_time1, filt_time2 = filt_time2, $
              defilter = defilter, $
              param_modifier = param_modifier, $
              strong_source = strong_source, $
              help = k_help, silent= silent, $
              simpar = simparfile, $
              init_subtract_file = init_subtract_file, $
              cat_snr_min = cat_snr_min, $
              input_cat = input_cat, $
              output_cat = output_cat, $
              infout = info_all, fileout = fileout, $
              only_plot = k_only_plot, png = k_png, pdf = k_pdf, $
              iterplot = k_iterplot, image_max = image_max



if n_params() lt 1 then begin
   dl_unix, 'imcmcall'
   return
endif

if keyword_set( k_only_plot) then only_plot = k_only_plot else $
   only_plot = 0
root_dir = !nika.save_dir+'/'+ext
spawn, 'mkdir -p '+ root_dir
source_dir = !nika.save_dir+'/'+ext+'/'+strupcase(source)
spawn, 'mkdir -p '+ source_dir  ; everything will go there
imcmin_dir = source_dir+'/imcmin'  ; input files
spawn, 'mkdir -p '+imcmin_dir
imcmout_dir = source_dir+'/imcmout' ; output ascii files (catalogs)
spawn, 'mkdir -p '+imcmout_dir
; NB: !nika.project_dir is source_dir+'/'+method_num

filpa = imcmin_dir+ '/imcm_input_'+source+'_'+strtrim(method_num, 2)+version+'.txt'
filsc = imcmin_dir+ '/scan_'+source+'_'+strtrim(method_num, 2)+version+'.txt'
fileout = [filpa, filsc]        ; info if needed
;   for example to redo the map averaging of one iteration: iter=2 & imcm_avg_and_mask, fileout[0], fileout[1], iter

if not keyword_set( only_plot) then begin
; Fill in the files
   write_file, filsc, scanlist, /delete
   nscan = n_elements( scanlist)
   if not keyword_set( silent) then begin
      print, 'Scan list contains ', nscan,  ' scans'
   endif
;
   if keyword_set( strong_source) then begin
      mastr = 'no_mask = 0'
      maigno = 'ignore_mask_for_decorr=0'
   endif else begin
      mastr = 'no_mask = 1'  ; very important
      maigno = 'ignore_mask_for_decorr = 1'  ; default (as a precaution)
   endelse
      
   pmod = [$
;          'source = "'+ source+ '"', $
          "source = '"+ source+ "'", $ ; Works better for a name starting
                                ; with a number e.g. 0355+508
          'method_num  =  '+ strtrim(method_num, 2), $
          'version = "'+ strtrim( version, 2)+ '"', $
          'iter_min = '+ strtrim(iter_min, 2), $
          'iter_max = '+ strtrim(iter_max, 2), $
          'ext = "'+ ext+ '"', $
          mastr, maigno]   ; forgotten: added in Jan 2021 (0 in case of strong source)
   if keyword_set( silent) then pmod = [pmod, 'silent = 1'] else $
      pmod = [pmod, 'silent = 0'] 
   if keyword_set( defilter) then $
      pmod = [pmod, 'atmb_defilter = '+ strtrim( iter_max, 2)] 
   if keyword_set( nsubscan) then $
      pmod = [pmod, 'atmb_nsubscan = '+ strtrim( long(nsubscan), 2)] 
   if keyword_set( init_subtract_file) then $
      pmod = [pmod, "atmb_init_subtract_file = '" + $
              strtrim( init_subtract_file)+ "'"]
   ; additional standard options
   pmod = [pmod, 'keep_save_files =  1']
   if keyword_set( simparfile) then $
      pmod = [pmod, $
              'simpar_file = "'+ simparfile+ '"']
   
   if keyword_set( nharm1) or keyword_set( nharm2) then $
      pmod = [pmod, $
              'nharm_subscan1mm = '+ strtrim( nharm1, 2), $
              'nharm_subscan2mm = '+ strtrim( nharm2, 2)]
   
   if keyword_set( filt_time1) or keyword_set( filt_time2) then $
                                ; Will compute consistently the nharm
                                ; and nsubscan params
                                ; This option is used if the scanning
                                ; strategy depends on the scan: e.g in Goodsnorth
      pmod = [pmod, $
              'atmb_filt_time1mm = '+ string( filt_time1), $
              'atmb_filt_time2mm = '+ string( filt_time2)]
   
   pmod = [pmod, $
           'info_longobj =  ' + string(mapra), $  ; make sure it is double
           'info_latobj =   ' + string(mapdec), $
           'map_xsize = '+ string( mapxsize), $   ; param. is filled in
           'map_ysize = '+ string( mapysize), $
           'map_reso  = '+ string( mapreso), $
           'keep_save_files_all_iter = 1']
   if keyword_set( param_modifier) then pmod = [pmod, $
           param_modifier]
   
; NEED to put reso, ra, dec
   write_file, filpa, pmod, /delete

   if not keyword_set( silent) then begin
      print, 'Parameters are '
      for i = 0, n_elements( pmod)-1 do print, i, ' ', pmod[ i]
   endif
   
; Run
   if keyword_set( k_help) then print, 'imcm, ', filpa,', ',  filsc, ' will be launched. Is it correct? If yes relaunch with help=0 ' else $
      imcm, filpa, filsc

endif                           ; End run part


; Start the analysis
; Plot, analyse, make catalog

if keyword_set( k_png) then begin
   png = 1                      ; default 1,  1 for all png
   ps = 0
   pdf = 0
endif else if keyword_set( k_pdf) then begin
; OR
   png = 0
   ps = 1
   pdf = 1
endif else begin
   ; or nothing
   png = 0
   ps = 0
   pdf = 0
endelse


if keyword_set(k_iterplot) then itest = k_iterplot else $
   itest = 0                ; default 0 to have all iterations  ; itest=2 to test iteration 2 only, or itest=-1 to test iter=0

if iter_min eq iter_max then begin
   itest = iter_min             ; Logical to plot only the wanted iteration
   if itest eq 0 then itest = -1
endif


if keyword_set( image_max) then fmax = image_max else delvarx, fmax
;fmax = [0.5, 0.5] ; range away from default eg for MWC

if keyword_set( cat_snr_min) then snr_thresh = cat_snr_min else snr_thresh = 3
; print, iter_min, iter_max

if keyword_set( only_plot) then begin
   iplot_min = iter_min
   iplot_max = iter_max
   if keyword_set(k_iterplot) then iplot_min = k_iterplot
   if keyword_set(k_iterplot) then iplot_max = k_iterplot
   
endif

if keyword_set( k_help) then $
   print, 'Will do the output analysis' $
else begin
   ;In order to plot the changes (A1,A3,1mm,2mm)
   diff_stat = replicate({mean:0., median:0., min:0., max:0., stddev:0.}, 4, iter_max+1)
   diff_stat_jk = replicate({mean:0., median:0., min:0., max:0., stddev:0.}, 4, iter_max+1)

   if only_plot le 1 then begin
@imcmcall_analysis.scr
   endif 
; Make the catmerge catalog or use an input catalog of positions
  if keyword_set( input_cat) then k_catmerge = input_cat else k_catmerge = ''
  if keyword_set( output_cat) then k_catoutmerge = output_cat else k_catoutmerge = ''
  if only_plot le 2 then begin
@imcmcall_analysis2.scr
  endif

  if only_plot le 3 then begin
; Incremental images from one iter to another
@imcmcall_analysis3.scr
  endif

  if only_plot le 4 then begin
; HORVER images
@imcmcall_analysis4.scr
  endif

  if only_plot le 5 then begin
; Noise and Filtering analysis
@imcmcall_analysis5.scr
  endif
endelse

return
end
