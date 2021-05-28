
;+
;
; SOFTWARE:
;
; NAME: 
; nk_save_scan_results_3
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;            - nk_save_scan_results_2, param, info, data, kidpar, filing=filing
; 
; PURPOSE: 
;        Save intermediate quantities relevant to this scan for
;        further combination with other scans
; 
; INPUT: 
;       - param, info, kidpar, grid
; 
; OUTPUT: 
;      - a .save for the moment in
;        !nika.plot_dir+"/Pipeline/scan_YYYYMMDD
;      - an .csv file containing photometry information on the scan
;        processed as if it was a single pointi source at the map center.
; 
; KEYWORDS:
;      - map_1mm, map_2mm: maps of the current scan *only* (not the
;        cumulative of all scans until this one)
;
; SIDE EFFECT:
;      - creates directories and writes results on disk
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 14th, 2014: Nicolas Ponthieu
;        - Oct. 2015: NP
;-
;================================================================================================

pro nk_main_beam_fwhm, param, info, kidpar, grid, output_dir=output_dir, file_suffixe=file_suffixe, $
                       filing=filing, xguess=xguess, yguess=yguess, $
                       chisquare=chisquare
  
if n_params() lt 1 then begin
   message, /info, 'Calling sequence:'
   print, "nk_main_beam_fwhm, param, info, grid, kidpar, filing=filing"
   return
endif

;; Do not exit if info.status here !
;; You do want to save the parameters and info and everything to diagnose a
;; problem that might have occured when the pipeline was running

;; Compute photometry if everything went fine
if info.status eq 1 then return

;; noplot is useful to compute fluxes while not displaying the maps
noplot = 1 - long( param.do_plot)

;; Gather information from the maps (photometry, centroid position...)
if strupcase( param.map_proj) eq "NASMYTH" then coltable=3 else coltable=39
;; LP add (for focus study using small maps)
if (param.rmax_keep le 100. and strupcase( param.map_proj) eq "NASMYTH") then guess_fit_par=1. 
charsize=0.7

 if keyword_set(file_suffixe) then file_suffixe=file_suffixe else file_suffixe=''

 if keyword_set(output_dir) then outdir = output_dir else outdir = param.output_dir

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; nk_grid2info_lp, grid, info_out, info_in=info, noplot=(1-param.do_plot), $
;;               educated = param.educated, iconic = param.iconic, ps = param.plot_ps, $
;;               plot_dir = param.plot_dir, nickname = param.scan, coltable=coltable, xguess=xguess, yguess=yguess,$
;;               guess_fit_par=guess_fit_par, dmax=param.educated_fit_dmax, old_formula=param.old_pol_deg_formula, $
;;               all_time_matrix_center=all_time_matrix_center, ata_fit_beam_rmax=param.ata_fit_beam_rmax, $
;;               charsize=charsize, /nefd_maps

title   = ''
noplot_in = (1-param.do_plot)

nickname = param.scan

ps  = param.plot_ps
png = param.plot_png

educated = param.educated
iconic   = param.iconic
dmax     = param.educated_fit_dmax

if strupcase(grid.map_proj) eq "NASMYTH" then !mamdlib.coltable = 3

;; init info_out with information from the pipeline if available
info_out = info

if info_out.status eq 1 then begin
   message, /info, 'info_out.status is 1 at start'
   return
endif

stokes = ["I", "Q", "U"]
grid_tags = tag_names( grid)
info_tags = tag_names(info_out)

plot_dir = param.plot_dir

if noplot_in eq 0 then begin
   
   if ps eq 0 then begin
      ;; Quick scan on grid tags to initialize display parameters
      grid_tags = tag_names(grid)
      narrays = 3 ; 0
      nstokes = 1               ; I at least
      for iarray=1, 3 do begin
         w = where( strupcase(grid_tags) eq "MAP_VAR_Q"+strtrim(iarray,2), nw)
         if nw ne 0 then nstokes=3
      endfor
      ;;my_multiplot, narrays+2, nstokes, pp, pp1, /rev, xmargin=0.05
      my_multiplot, narrays+1, nstokes, pp, pp1, /rev, xmargin=0.05
      if nstokes gt 1 then $
         wind, 1, 1, /free, /large, iconic = iconic else $
            wind, 1, 1, /free, /xlarge, iconic = iconic
   endif
   if png eq 1 then outplot, file=plot_dir+"/maps_"+info_out.scan, /png
   
endif


suffix        = ['1', '2', '3', "_1MM", "_2MM"]
suffix_1      = ['1', '2', '3', '1MM', '2MM']
hits_field    = ["NHITS_1", "NHITS_2", "NHITS_3", "NHITS_1MM", "NHITS_2MM"]
grid_step     = [!nika.grid_step[0], !nika.grid_step[1], !nika.grid_step[2], !nika.grid_step[0], !nika.grid_step[1]]
iarray_list   = [1, 2, 3, 1, 2]
nfields       = n_elements(suffix)

;; re-order plots: do it here and not in an additional field to "param"
;; otherwise param cannot be passed easily to the output fits header
plot_position = [0, 3, 1, 2, 4]

all_time_matrix_center = dblarr(15)
all_flux_source        = dblarr(15)
all_sigma_flux_source  = dblarr(15)
all_flux_center        = dblarr(15)
all_sigma_flux_center  = dblarr(15)
all_nefd_center        = dblarr(15)

if keyword_set(chisquare) then chisquare = dblarr(nfields)
alpha = dblarr(nfields)
radius = dblarr(nfields)

alpha_flux_cuts = [0.35, 0.2, 0.35, 0.35, 0.2]

;; Main loop
init_title = 0
for ifield=0, nfields-1 do begin

   iarray = iarray_list[ifield]
   
   ;; Display A1, A3, combined 1mm, A2
   if ifield ge 4 then noplot=1 else noplot=noplot_in
   
   ;; Loop on I, Q and U
   for istokes=0, 2 do begin

      delvarx, imrange
      if noplot_in eq 0 then begin
         if iarray eq 1 or iarray eq 3 then begin
            if istokes eq 0 and keyword_set(imrange_i1) then imrange = imrange_i1
            if istokes eq 1 and keyword_set(imrange_q1) then imrange = imrange_q1
            if istokes eq 2 and keyword_set(imrange_u1) then imrange = imrange_u1
         endif else begin
            if istokes eq 0 and keyword_set(imrange_i2) then imrange = imrange_i2
            if istokes eq 1 and keyword_set(imrange_q2) then imrange = imrange_q2
            if istokes eq 2 and keyword_set(imrange_u2) then imrange = imrange_u2
         endelse            
      endif

      ;; Check if the map exists (in particular, are we in polarized mode ?)
      wmap = where( strupcase(grid_tags) eq "MAP_"+stokes[istokes]+suffix[ifield], nwmap)

      if nwmap eq 0 then begin
         ;message, /info, "No MAP_"+stokes[istokes]+suffix[ifield]+" in grid"
      endif else begin
         
         ;; check if the map is not empty => look at its associated
         ;; variance
         wvar = where( strupcase(grid_tags) eq "MAP_VAR_"+stokes[istokes]+suffix[ifield], nwvar)
         if nwvar eq 0 then begin
            message, /info, "no MAP_VAR_"+stokes[istokes]+suffix[ifield]+" tag in grid ?"
            stop
         endif
         if total( grid.(wvar), /nan) ne 0 then begin
            whits = where( strupcase(grid_tags) eq hits_field[ifield], nwhits)
            
            ;; Re-init fit parameters
            if istokes eq 0 then begin
               if keyword_set(force_input_fit_par) then begin
                  input_fit_par = force_input_fit_par
               endif else begin
                  ;; delvar to re-init with the fit on the intensity map
                  delvarx, input_fit_par
               endelse
            endif

            if defined(pp) and noplot eq 0 then position = pp[plot_position[ifield],istokes,*]
            if ps gt 0 then begin
               noplot=0
               if nickname ne '' then begin
                  ps_file = plot_dir+"/maps_"+strtrim(nickname, 2)+"_"+ $
                            stokes[istokes]+suffix[ifield]+'.ps'  
               endif else begin
                  ps_file = plot_dir+"/map_"+stokes[istokes]+suffix[ifield]+".ps"
               endelse
            endif

            ;; To derive the NEFD, we need the (human) time spent by
            ;; NIKA2 on the source. If we use directly nhits_1mm, it
            ;; overestimates this time by a factor about two because
            ;; it's the sum of hits from array1 and array3 if
            ;; the two matrices sample the map in the same way.
            ;; Here, we build an hybrid map with arrays 1 and 3 when
            ;; they're present to have exactly the 'human' time spent by pixel
            if suffix[ifield] eq "_1MM" then begin
               w1 = where( strupcase(grid_tags) eq "NHITS_1", nw1)
               if nw1 ne 0 then begin
                  human_obs_time = grid.(w1)/!nika.f_sampling
               endif else begin
                  human_obs_time = grid.xmap * 0.d0
               endelse
               w3 = where( strupcase(grid_tags) eq "NHITS_3", nw3)
               if nw3 ne 0 then begin
                  w = where( human_obs_time eq 0 and grid.(w3) ne 0, nw)
                  if nw ne 0 then begin
                     a = (grid.(w3))/!nika.f_sampling  ; Intermediate step required
                     human_obs_time[w] = a[w]
                  endif
               endif
            endif else begin
               delvarx, human_obs_time
            endelse


            if init_title eq 1 then title=stokes[istokes]+suffix[ifield] else title=''


            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ;; nk_map_photometry_lp, grid.(wmap), grid.(wvar), grid.(whits), $
            ;;                       grid.xmap, grid.ymap, !nika.fwhm_array[iarray-1], $
            ;;                       flux, sigma_flux, sigma_bg, output_fit_par, output_fit_par_error, $
            ;;                       bg_rms, flux_center, sigma_flux_center, sigma_bg_center, $
            ;;                       integ_time_center, sigma_beam_pos, grid_step=!nika.grid_step[iarray-1], $
            ;;                       time_matrix_center=time_matrix_center, $
            ;;                       input_fit_par=input_fit_par, educated=educated, dmax=dmax, $
            ;;                       k_noise=k_noise, noplot=noplot, position=position, $
            ;;                       info=info_out, nefd_source=nefd_source, nefd_center=nefd_center, $
            ;;                       beam_pos_list = beam_pos_list, syst_err=syst_err, $
            ;;                       ps_file=ps_file, imrange=imrange, chars=charsize, $
            ;;                       title=title, $
            ;;                       image_only = image_only, $
            ;;                       human_obs_time=human_obs_time, coltable=coltable, $
            ;;                       xguess=xguess, yguess=yguess, guess_fit_par=guess_fit_par, source=info_out.object, $
            ;;                       ata_fit_beam_rmax=ata_fit_beam_rmax, map_var_flux=map_var_flux



            map      = grid.(wmap)
            map_var  = grid.(wvar)
            nhits    = grid.(whits)
            xmap     = grid.xmap
            ymap     = grid.ymap
            input_fwhm = !nika.fwhm_array[iarray-1]

            grid_step  = !nika.grid_step[iarray-1]
            source     = info_out.object
            
            reso              = abs(xmap[1] - xmap[0])
            
            dist_fit   = 40. ; arcsec
            imzoom     = 0
        
            
            ;; Use the input variance map as a starting point to locate the source with
            ;; mpfit (via nk_fitmap) unless it's already known from input_fit_par.
            xx   = reform(xmap[*,0])
            yy   = reform(ymap[0,*])
            w = where( map_var le 0 or finite(map_var) ne 1, nw)
                                ;radius = sqrt(xmap^2+ymap^2)
                                ;w1 = where(radius gt dist_fit, nw1)
                                ;map_var_temp = map_var
                                ;if nw1 ne 0 then map_var_temp[w1] = !values.d_nan
                                ;if nw  ne 0 then map_var_temp[w]  = !values.d_nan
            if keyword_set(xguess) or keyword_set(yguess) then educated = 1
            ;; LP notes: the sigma_guess value will be taken into acount only if guess_fit_par is
            ;; also selected. 
            input_sigma_beam = input_fwhm*!fwhm2sigma
            nk_fitmap, map, map_var, xmap, ymap, output_fit_par, covar, output_fit_par_error, $
                       educated=educated, k_noise=k_noise, info=info_out, status=status, dmax=dmax, $
                       xguess=xguess, yguess=yguess, guess_fit_par=guess_fit_par, sigma_guess=input_sigma_beam, map_fit=best_model
            

            ;; Fit only near the very center and far from it to
            ;; avoid side lobes
            wtag = where( strupcase(info_tags) eq "RESULT_FLUX_"+strtrim(stokes[istokes],2)+suffix[ifield], nwtag)
            flux = info_out.(wtag)

            ;; d    = sqrt( (xmap-output_fit_par[4])^2 + (ymap-output_fit_par[5])^2)
            ;; rbg  = 100.
            ;; ;;
            ;; ;; alpha_flux_cuts = indgen(51)/50.
            ;; alpha_flux_cuts = indgen(27)/30.+0.05
            ;; alpha_flux_cuts = indgen(35)/60.+0.1
            ;; ntest = n_elements(alpha_flux_cuts)
            ;; output_fit_par_test = dblarr(7, ntest)
            ;; chi2_test = dblarr(ntest)
            ;; fwhm_test = dblarr(ntest)
            ;; radius_test = dblarr(ntest)       
            ;; max = max(map(where(d le 40.)))
            ;; for ia= 0, ntest-1 do begin
            ;;    alpha_flux_cut = alpha_flux_cuts[ia]
            ;;    wfit = where( (map gt alpha_flux_cut*flux and d le rbg) or (d ge rbg and map_var lt mean(map_var)), nwfit, compl=wout)
            ;;    map_var0 = map_var
            ;;    map_var0[wout] = 0.d0
            ;;    nk_fitmap, map, map_var0, xmap, ymap, output_fit_par, covar, output_fit_par_error, $
            ;;               educated=educated, k_noise=k_noise, info=info_out, status=status, dmax=dmax, $
            ;;               xguess=xguess, yguess=yguess, guess_fit_par=guess_fit_par, sigma_guess=input_sigma_beam, map_fit=best_model
            ;;    output_fit_par_test[*,ia] = output_fit_par[*]
            ;;    ww = where(map_var0 gt 0., ndata)
            ;;    chi2 = total((map[ww]-best_model[ww])^2/map_var0[ww])/(ndata-7.)
            ;;    chi2_test[ia] = chi2
            ;;    fwhm_test[ia] = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma
            ;;    radius_test[ia] = max(d[where( (map gt alpha_flux_cut*flux))])
            ;; endfor

            ;; bestchi2 = min(abs(chi2_test - 1.d0))
            ;; w=where(abs(chi2_test - 1.d0) eq bestchi2)
            ;; output_fit_par = output_fit_par_test[*,w[0]]
            ;; chisquare[ifield] = bestchi2
            ;; alpha[ifield] = alpha_flux_cuts[w[0]]
            ;; radius[ifield] = radius_test[w[0]]
            
            center_x = output_fit_par[4]
            center_y = output_fit_par[5]
            external_radius = 100.
            internal_radius = 0
            flux_thresh     = 0
            alpha_flux      = 0
            optimise_radius = 1
            fit_main_beam_fwhm, map, map_var, xmap, ymap, center_x, center_y, $
                                output_fit_par, output_covar, output_fit_par_error, $
                                internal_radius=internal_radius, external_radius=external_radius, $
                                flux_thresh=flux_thresh, chi2=chi2, $
                                optimise_radius=optimise_radius, alpha_flux=alpha_flux
                    
            chisquare[ifield] = chi2
            alpha[ifield]     = alpha_flux
            radius[ifield]    = internal_radius 
            
            
            if noplot lt 1 then begin
               phi = dindgen(200)/199*2*!dpi
               xx  = output_fit_par[2]*cos(phi)/!fwhm2sigma/2. ; apparent diam = FWHM
               yy  = output_fit_par[3]*sin(phi)/!fwhm2sigma/2. ; apparent diam = FWHM
               xx1 = cos(output_fit_par[6])*xx - sin(output_fit_par[6])*yy
               yy1 = sin(output_fit_par[6])*xx + cos(output_fit_par[6])*yy
               !mamdlib.coltable = coltable
               w = where( map_var gt 0, nw, compl=wcompl, ncompl=nwcompl)
               if nw eq 0 then begin
                  message, /info, "no pixel with variance > 0 to compute imrange."
                  stop
               endif
               var_med = median( map_var[w])
               if not keyword_set(imrange) then imrange = [-1,1]*4*stddev( map[where( map_var le var_med and map_var gt 0)]) 
;;print, ps_file
               if imzoom gt 0 then begin 
                  imview, map, xmap=xmap, ymap=ymap, position=position, /noerase, imrange=imrange, $
                          title=title, xtitle=xtitle, ytitle=ytitle, /noclose, postscript=ps_file, charsize=charsize, $
                          xcharsize=xcharsize, ycharsize=ycharsize, inside_bar=inside_bar, orientation=orientation, nobar=nobar, $
                          charbar=charsize, xrange=xrange, yrange=yrange
                  if source ne '' then legendastro, source, box=0, /right, textcol=255
               endif else begin
                  ;; display a sub-map of 2x2 arcmin square size
                  x0=0.
                  if keyword_set(xguess) then x0=xguess
                  y0=0.
                  if keyword_set(yguess) then y0=yguess
                  xmin = max([min(xmap),x0-60.])
                  xmax = min([max(xmap),x0+60.])
                  ymin = max([min(ymap),y0-60.])
                  ymax = min([max(ymap),y0+60.])
                  
                  imview, map, xmap=xmap, ymap=ymap, xr=[xmin, xmax], yr=[ymin, ymax], position=position, /noerase, $
                          imrange=imrange, title=title, xtitle=xtitle, ytitle=ytitle, /noclose, postscript=ps_file, charsize=charsize, $
                          xcharsize=xcharsize, ycharsize=ycharsize, inside_bar=inside_bar, orientation=orientation, nobar=nobar, $
                          charbar=charsize        
               endelse
               
               theta = dindgen(200)/199.*2.d0*!dpi
               
               if image_only lt 1 or show_fit gt 0 then begin
                  if coltable eq 3 then myct = 70 else myct=250
                  loadct, 39, /silent
                  oplot, [0], [0], psym=1, col=150
                  oplot, 0.5*input_fwhm*cos(phi), 0.5*input_fwhm*sin(phi), col=150
                  oplot, output_fit_par[4] + xx1, output_fit_par[5] + yy1, col=myct
                  oplot, [output_fit_par[4]], [output_fit_par[5]], psym=1, col=myct
                  loadct, 39,  /silent
                  if defined(param) then begin
                     if param.do_aperture_photometry then begin
                        oplot, param.aperture_photometry_zl_rmin*cos(theta), $
                               param.aperture_photometry_zl_rmin*sin(theta), line=2, col=150
                        oplot, param.aperture_photometry_zl_rmax*cos(theta), $
                   param.aperture_photometry_zl_rmax*sin(theta), line=2, col=150
                        oplot, param.aperture_photometry_rmeas*cos(theta), $
                               param.aperture_photometry_rmeas*sin(theta), line=2, col=myct
                     endif
                  endif
               endif
               
               x_coor = 'x'
               y_coor = 'y'
               if keyword_set(param) then begin
                  if strupcase( param.map_proj) eq "RADEC" then begin
                     x_coor = "RA"
                     y_coor = "Dec"
                  endif
                  if strupcase( param.map_proj) eq "AZEL" then begin
                     x_coor = "az"
                     y_coor = "el"
                  endif
               endif
               
               if image_only lt 1 then begin
                  fwhm1 = output_fit_par[2]/!fwhm2sigma
                  fwhm2 = output_fit_par[3]/!fwhm2sigma
                  legendastro, ['!7D!3'+x_coor+' '+num2string(output_fit_par[4]), $
                                '!7D!3'+y_coor+' '+num2string(output_fit_par[5]), $
                                'Peak '+num2string(output_fit_par[1]), $
                                ;'FWHM '+num2string( sqrt(output_fit_par[2]*output_fit_par[3])/!fwhm2sigma)], $
                                'FWHM '+string(fwhm1,format="(F5.2)")+"x"+$
                                string(fwhm2,format="(F5.2)")+" = "+$
                                string(sqrt(fwhm1*fwhm2),format="(F5.2)")], $
                               textcol=255, box=0, charsize=charsize
                               
               endif
               if ps gt 0 then close_imview
            endif
            
            
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            
            if init_title eq 0 then begin
               if tag_exist( info_out, 'UT') and noplot eq 0 then nika_title, info_out, /ut, /az, /el, /scan, charsize=0.6
               init_title=1
            endif


            if istokes eq 0 then begin
               wtag = where( strupcase(info_tags) eq "RESULT_OFF_X_"+suffix_1[ifield], nwtag)
               info_out.(wtag) = output_fit_par[4]

               wtag = where( strupcase(info_tags) eq "RESULT_OFF_Y_"+suffix_1[ifield], nwtag)
               info_out.(wtag) = output_fit_par[5]

               wtag = where( strupcase(info_tags) eq "RESULT_FWHM_X_"+suffix_1[ifield], nwtag)
               info_out.(wtag) = output_fit_par[2]/!fwhm2sigma

               wtag = where( strupcase(info_tags) eq "RESULT_FWHM_Y_"+suffix_1[ifield], nwtag)
               info_out.(wtag) = output_fit_par[3]/!fwhm2sigma

               wtag = where( strupcase(info_tags) eq "RESULT_FWHM_"+suffix_1[ifield], nwtag)
               info_out.(wtag) = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma

               wtag = where( strupcase(info_tags) eq "RESULT_PEAK_"+suffix_1[ifield], nwtag)
               info_out.(wtag) = output_fit_par[1]
            endif

         endif  ;else message, /info, 'Empty map'             ; map is not empty
      endelse                   ; map exists
   endfor                       ; stokes parameters
endfor                          ; loop on arrays



if png eq 1 then outplot, /close
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Change names of variables for easier comparison to the current ones
;; when we restore them
param1 = param
;; postponed to the end of this script
;; NP. Sept. 15th, 2016
;; info = info_out
;; info1  = info
info1 = info_out
grid1  = grid
if defined(kidpar) then kidpar1 = kidpar

;; Write the summary .csv file
tags = tag_names(info1)
w = where( strupcase( strmid(tags,0,6)) eq "RESULT", nw)
tag_length = strlen( tags)
get_lun,  lu
openw, lu, outdir+"/photometry"+file_suffixe+".csv"
title_string = 'Scan, Source, RA, DEC'
res_string   = strtrim(param.scan,2)+", "+strtrim(param.source,2)+", "+strtrim(info1.longobj,2)+", "+strtrim(info1.latobj,2)
for i=0, nw-1 do begin
   title_string = title_string+", "+strmid( tags[w[i]],7,tag_length[w[i]]-7)
   res_string   = res_string+", "+strtrim( info1.(w[i]),2)
endfor

if keyword_set(chisquare) then begin
   for j=0, nfields-1 do begin
      title_string = title_string+", "+strtrim( "CHI2_"+suffix_1[j])
      res_string   = res_string+", "+strtrim( string(chisquare[j]),2)
   endfor
   for j=0, nfields-1 do begin
      title_string = title_string+", "+strtrim( "ALPHA_"+suffix_1[j])
      res_string   = res_string+", "+strtrim( string(alpha[j]),2)
   endfor
   for j=0, nfields-1 do begin
      title_string = title_string+", "+strtrim( "RADIUS_"+suffix_1[j])
      res_string   = res_string+", "+strtrim( string(radius[j]),2)
   endfor
endif

printf, lu, title_string
printf, lu, res_string

close, lu

save, file=outdir+'/results'+file_suffixe+'.save', param1, info1, kidpar1, grid1
if param.silent eq 0 then message, /info, "saved "+param.output_dir+'/results'+file_suffixe+'.save'

;; restore info for online studies
;; NP. Sept. 15th, 2016
info = info1


if keyword_set(filing) then begin
   spawn, "rm -f "+param.bp_file
   spawn, "touch "+param.ok_file
   ;; removed UnProcessed file only if everything went well
   ;;if info.status eq 0 then spawn, "rm -f "+param.up_file
endif

end
