
;+
;
; SOFTWARE:
;
; NAME: 
; nk_grid2info
;
; CATEGORY: general
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Oct. 2015: NP
;================================================================================================

pro nk_grid2info, grid, info_out, info_in=info_in, param=param, $
                  png=png, ps=ps, plot_dir=plot_dir, $
                  aperture_photometry=aperture_photometry, $
                  noplot_in=noplot_in, rta_title=rta_title, $
                  educated=educated, title=title, coltable=coltable, $
                  imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
                  imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
                  imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
                  imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
                  image_only = image_only, charsize=charsize, iconic = iconic, $
                  beam_pos_list = beam_pos_list, syst_err=syst_err, sigma_beam_pos = sigma_beam_pos, $
                  nickname = nickname, xguess=xguess, yguess=yguess, guess_fit_par=guess_fit_par, dmax=dmax, $
                  all_time_matrix_center=all_time_matrix_center, all_flux_source=all_flux_source, $
                  all_sigma_flux_source=all_sigma_flux_source, source=source, $
                  all_flux_center=all_flux_center, all_sigma_flux_center=all_sigma_flux_center, $
                  force_input_fit_par=force_input_fit_par, old_formula=old_formula, nefd_maps=nefd_maps, $
                  ata_fit_beam_rmax=ata_fit_beam_rmax, $
                  noboost = noboost, silent=silent, all_t_gauss_beam=all_t_gauss_beam, $
                  commissioning_plot=commissioning_plot, mb3d=mb3d, pdf = k_pdf
;-
if n_params() lt 1 then begin
   message, /info, 'Calling sequence:'
   dl_unix, 'nk_grid2info'
   return
endif

if keyword_set(title) then in_title=title else in_title=''

if strupcase(grid.map_proj) eq "NASMYTH" then !mamdlib.coltable = 3

;; init info_out with information from the pipeline if available
if keyword_set(info_in) then info_out = info_in else nk_default_info, info_out
if info_out.status eq 1 then begin
   message, /info, 'info_out.status is 1 at start'
   return
endif

if not keyword_set(param) then nk_default_param, param

;; Aperture photometry directly puts all the results into info_out
if keyword_set(aperture_photometry) then begin
   nk_aperture_photometry_3, param, info_out, grid, nickname = nickname, source=source
endif

stokes = ["I", "Q", "U"]
grid_tags = tag_names( grid)
info_tags = tag_names(info_out)

if not keyword_set(noplot_in) then noplot_in = 0

if noplot_in eq 0 then begin

   if not keyword_set(plot_dir) then plot_dir = "."
   
   if not keyword_set(ps) then begin
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
   if keyword_set(png) eq 1 then outplot, file=plot_dir+"/maps_"+info_out.scan, /png
   
endif

suffix        = ['1', '2', '3',  '_1MM', '2']
suffix_1      = ['1', '2', '3', '_1MM', '_2MM']
suffix_2      = ['1', '2', '3', '1MM', '2MM']
hits_field    = ['NHITS_1', 'NHITS_2', 'NHITS_3', 'NHITS_1MM', 'NHITS_2']
grid_step     = [!nika.grid_step[0], !nika.grid_step[1], !nika.grid_step[2], $
                 (!nika.grid_step[0]+!nika.grid_step[2])/2., !nika.grid_step[1]]
iarray_list   = [1, 2, 3, 1, 2]
nfields       = n_elements(suffix)

;; re-order plots: do it here and not in an additional field to "param"
;; otherwise param cannot be passed easily to the output fits header
plot_position = [0, 3, 1, 2, 4]

; FXD, output 2mm in the fields to avoid breaking backward compatibility
all_t_gauss_beam       = dblarr(15)
all_time_matrix_center = dblarr(15)
all_flux_source        = dblarr(15)
all_sigma_flux_source  = dblarr(15)
all_flux_center        = dblarr(15)
all_sigma_flux_center  = dblarr(15)
all_nefd_center        = dblarr(15)

;; No more "2mm" field, Oct. 22nd, 2017 NP
;; all_t_gauss_beam       = dblarr(12)
;; all_time_matrix_center = dblarr(12)
;; all_flux_source        = dblarr(12)
;; all_sigma_flux_source  = dblarr(12)
;; all_flux_center        = dblarr(12)
;; all_sigma_flux_center  = dblarr(12)
;; all_nefd_center        = dblarr(12)

;; Main loop
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
         if total( grid.(wvar), /nan) eq 0 then begin
            message, /info, "Only infinite variance pixels for "+grid_tags[wvar]
            ;;stop
         endif else begin
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
            if keyword_set(ps) then begin
               noplot=0
               if keyword_set(nickname) then begin
                  ps_file = plot_dir+"/maps_"+strtrim(nickname, 2)+"_"+ $
                            stokes[istokes]+suffix_1[ifield]+'.ps'  
               endif else begin
                  ps_file = plot_dir+"/map_"+stokes[istokes]+suffix_1[ifield]+".ps"
               endelse
            endif

            title = in_title+" "+stokes[istokes]+suffix_1[ifield]

            ;; useless conditions i've just tested that the
            ;; variance map had finite values
;;            if max(grid.(whits)) gt 0 then begin
            map_nefd = 1        ; init
            ;; correct the displayed nefd if this is the 1mm map
            if suffix_2[ifield] eq '1MM' then one_mm_correct_integ_time = 1 else one_mm_correct_integ_time = 0
;           We truncate at the co-addition phase only,

;;            we compute
;;           noiseup to correct NEFD but we do not apply noiseup to the
;;           map to keep the photometry of strong source correct.
;;             if param.method_num eq 120 and keyword_set( param.noiseup) then begin
;;                if strmid(suffix_2[ifield], 0, 1) ne '2' then begin '1mm case'
;;                   Nsa = info_out.subscan_arcsec/!nika.fwhm_nom[0] how many beams per subscan
;; How many parameters in atmb method: atm, atmbis, datm, atm^2 and max 5 subbands for
;; 1 scan, 2*nharm+ (offset and slope) per subscan
;;                   if param.nharm_subscan1mm gt 0 then Np = (4.+5.)/info_out.nsubscans+ (2*param.nharm_subscan1mm+2) $
;;                   else Np = (4.+5.)/info_out.nsubscans+ (param.polynom_subscan1mm+1)
;; Noise ( and low signal) is reduced by 
;;                   noiseup = (1./(1.-1.505*Np/Nsa)) this part is done at the map making level now: here
;;                endif else begin '2mm case'
;;                   Nsa = info_out.subscan_arcsec/!nika.fwhm_nom[1]
;;                   if param.nharm_subscan2mm gt 0 then np = (4.+5.)/info_out.nsubscans+ (2*param.nharm_subscan2mm+2) $
;;                   else np = (4.+5.)/info_out.nsubscans+ (param.polynom_subscan2mm+1)
;;                   noiseup = (1./(1.-1.505*Np/Nsa)) this part is done at the map making level now: here
;;                endelse
;;             endif else noiseup = 1.
            noiseup = 1.  ; noise and signal corrections are done at the nk_w8 level Feb 2021
            nk_map_photometry, grid.(wmap), grid.(wvar), grid.(whits), $  
                               grid.xmap, grid.ymap, !nika.fwhm_array[iarray-1], $
                               flux, sigma_flux, sigma_bg, output_fit_par, output_fit_par_error, $
                               bg_rms, flux_center, sigma_flux_center, sigma_bg_center, $
                               sigma_beam_pos=sigma_beam_pos, $
                               grid_step=grid_step[ ifield], $
                               time_matrix_center=time_matrix_center, $
                               input_fit_par=input_fit_par, educated=educated, dmax=dmax, $
                               k_noise=k_noise, noplot=noplot, position=position, $
                               info=info_out, nefd_source=nefd_source, nefd_center=nefd_center, $
                               err_nefd=err_nefd, $
                               beam_pos_list = beam_pos_list, syst_err=syst_err, $
                               ps_file=ps_file, imrange=imrange, chars=charsize, $
                               title=title, $
                               image_only = image_only, $
                               coltable=coltable, $
                               ;; human_obs_time=human_obs_time, $
                               xguess=xguess, yguess=yguess, guess_fit_par=guess_fit_par, source=info_out.object, $
                               ata_fit_beam_rmax=ata_fit_beam_rmax, map_var_flux=map_var_flux, map_nefd=map_nefd, $
                               silent=silent, noboost = noboost, t_gauss_beam=t_gauss_beam, sigma_boost=sigma_boost, $
                               sigma_1hit=sigma_1hit, one_mm_correct_integ_time=one_mm_correct_integ_time, $
                               commissioning_plot=commissioning_plot, xrange=xrange, yrange=yrange, param=param, $
                               noiseup = noiseup
                                ; noiseup is 1 (nk_w8 has done the
                                ; correction before): it is used for NEFD but not applied to data. k_snr = param.k_snr do not apply the k_snr correction at the individual map level but at the coaddition only. 
                                ; Convert ps to pdf
            if keyword_set(k_pdf) then begin
               pdf_file = strmid(ps_file, 0, strlen(ps_file) - 3)+'.pdf'
               if defined( listpdf) then $
                  listpdf = [listpdf, pdf_file] else listpdf = pdf_file
               command = 'ps2pdf '+ ps_file+ ' '+pdf_file
               spawn,  command,  res
               command = 'rm -f '+ ps_file
               spawn,  command,  res
            endif
            
            cmd = "info_out.result_sigma_boost_"+stokes[istokes]+suffix_1[ifield]+" = sigma_boost"
            junk = execute( cmd)

            cmd = "info_out.result_sigma_1hit_"+stokes[istokes]+suffix_1[ifield]+" = sigma_1hit"
            junk = execute( cmd)
            
            ;; Sept 25th
            if suffix_1[ifield] eq "_1MM" then begin
               time_matrix_center /= 2.d0
               t_gauss_beam       /= 2.d0
            endif
            
            www = where( sqrt( grid.xmap^2+grid.ymap^2) lt 20.)
            nn = total( (grid.(whits))[www])
;               if init_title eq 0 then begin
;                  init_title=1
;               endif
            
;;               ;; Derives NEFD maps
;;               wnefd = where( strupcase(grid_tags) eq "NEFD_"+stokes[istokes]+suffix[ifield], nwnefd)
;;               if nwnefd ne 0 then begin
;;                  if ifield eq 3 then map_nefd /= sqrt(2.d0) ; correct to the cumulated integration time at 1mm A1+A3
;;                  grid.(wnefd) = map_nefd
;;               endif

;;            endif
            
            all_t_gauss_beam[       ifield*3+istokes] = t_gauss_beam
            all_time_matrix_center[ ifield*3+istokes] = time_matrix_center
            all_flux_source[        ifield*3+istokes] = flux
            all_sigma_flux_source[  ifield*3+istokes] = sigma_flux
            all_flux_center[        ifield*3+istokes] = flux_center
            all_sigma_flux_center[  ifield*3+istokes] = sigma_flux_center
            all_nefd_center[        ifield*3+istokes] = nefd_center
            
            ;; Force the I centroid position for the Q and U maps
            if istokes eq 0 then begin
               if keyword_set(force_input_fit_par) then begin
                  input_fit_par = force_input_fit_par
               endif else begin
                  input_fit_par = output_fit_par
               endelse
            endif

            ;; Fill the info structure
            wtag = where( strupcase(info_tags) eq "RESULT_ERR_FLUX_LIST_"+strtrim(stokes[istokes],2)+suffix_1[ifield], nwtag)
            info_out.(wtag) = sigma_beam_pos

            wtag = where( strupcase(info_tags) eq "RESULT_FLUX_"+strtrim(stokes[istokes],2)+suffix_1[ifield], nwtag)
            info_out.(wtag) = flux

            wtag = where( strupcase(info_tags) eq "RESULT_ERR_FLUX_"+strtrim(stokes[istokes],2)+suffix_1[ifield], nwtag)
            info_out.(wtag) = sigma_flux  ; FXD was missing

            wtag = where( strupcase(info_tags) eq "RESULT_FLUX_CENTER_"+strtrim(stokes[istokes],2)+suffix_1[ifield], nwtag)
            info_out.(wtag) = flux_center
            
            wtag = where( strupcase(info_tags) eq "RESULT_ERR_FLUX_CENTER_"+strtrim(stokes[istokes],2)+suffix_1[ifield], nwtag)
            info_out.(wtag) = sigma_flux_center

            wtag = where( strupcase(info_tags) eq "RESULT_NEFD_"+strtrim(stokes[istokes],2)+suffix_1[ifield], nwtag)
            info_out.(wtag) = nefd_source

            wtag = where( strupcase(info_tags) eq "RESULT_NEFD_CENTER_"+strtrim(stokes[istokes],2)+suffix_1[ifield], nwtag)
            info_out.(wtag) = nefd_center

            wtag = where( strupcase(info_tags) eq "RESULT_ERR_NEFD_"+strtrim(stokes[istokes],2)+suffix[ifield], nwtag)
            info_out.(wtag) = err_nefd

            wtag = where( strupcase(info_tags) eq "RESULT_BG_RMS_"+strtrim(stokes[istokes],2)+suffix[ifield], nwtag)
; FXD 1Dec2020, redefine the bg_rms as the sqrt of the average map flux
; variance where the number of hits is gt than half the max
            wm = where( strupcase( tag_names(grid)) eq hits_field[ ifield], nwm)
            if nwm ne 0 then begin
               ww = where( grid.(wm) ge max( grid.(wm))/2., nww)
               if nww ne 0 then info_out.(wtag) = sqrt( avg( map_var_flux[ ww]))
            endif
            ;; if suffix[ifield] eq '1' or suffix[ifield] eq '3' then begin
            ;;    wm = where( strupcase( tag_names(grid)) eq "MASK_SOURCE_1MM", nwm)
            ;; endif else begin
            ;;    wm = where( strupcase( tag_names(grid)) eq "MASK_SOURCE_2MM", nwm)
            ;; endelse
            ;; if nwm ne 0 then begin
            ;;    ww = where( grid.(wm) ne 0, nww)
            ;;    if nww ne 0 then info_out.(wtag) = stddev( (grid.(wmap))[ww])
            ;; endif

            if istokes eq 0 then begin
               wtag = where( strupcase(info_tags) eq "RESULT_TIME_MATRIX_CENTER_"+suffix_2[ifield], nwtag)
               if nwtag ne 0 then info_out.(wtag) = time_matrix_center

               wtag = where( strupcase(info_tags) eq "RESULT_OFF_X_"+suffix_2[ifield], nwtag)
               info_out.(wtag) = output_fit_par[4]

               wtag = where( strupcase(info_tags) eq "RESULT_OFF_Y_"+suffix_2[ifield], nwtag)
               info_out.(wtag) = output_fit_par[5]

               wtag = where( strupcase(info_tags) eq "RESULT_FWHM_X_"+suffix_2[ifield], nwtag)
               info_out.(wtag) = output_fit_par[2]/!fwhm2sigma

               wtag = where( strupcase(info_tags) eq "RESULT_FWHM_Y_"+suffix_2[ifield], nwtag)
               info_out.(wtag) = output_fit_par[3]/!fwhm2sigma

               wtag = where( strupcase(info_tags) eq "RESULT_FWHM_"+suffix_2[ifield], nwtag)
               info_out.(wtag) = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma

               wtag = where( strupcase(info_tags) eq "RESULT_PEAK_"+suffix_2[ifield], nwtag)
               info_out.(wtag) = output_fit_par[1]
            endif

         endelse                ; there are finite variance pixels
      endelse                   ; map exists
   endfor                       ; stokes parameters
endfor                          ; loop on arrays


nk_patch_info, info_out

if tag_exist( grid, "MAP_Q_1MM") then begin

   ;;---------------------------------------------------------------------------------------------------------
   ;; Compute degrees of polarization per arrays
   for iarray=1, 3 do begin
      nk_get_info_tag, info_out, "flux_i", iarray, wi, wir
      nk_get_info_tag, info_out, "flux_q", iarray, wq, wqr
      nk_get_info_tag, info_out, "flux_u", iarray, wu, wur
      
      ;; Changed iqu2poldeg (AR+NP, May 25th, 2016 -> sigma_p_plus,
      ;; sigma_p_minus
      iqu2pol_info, info_out.(wi), info_out.(wq), info_out.(wu), $
                    info_out.(wir), info_out.(wqr), info_out.(wur), $
                    pol_deg, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                    old_formula=old_formula, mb3d=mb3d

      nk_get_info_tag, info_out, "pol_deg", iarray, wp, wpr
      info_out.(wp)  = pol_deg
      info_out.(wpr) = (sigma_p_plus+sigma_p_minus)/2.

      nk_get_info_tag, info_out, "pol_angle", iarray, wa, war
      info_out.(wa) = alpha_deg
      info_out.(war) = sigma_alpha_deg
   endfor

   ;; For the combined map
   nk_get_info_tag, info_out, "flux_i_1mm", iarray, wi, wir
   nk_get_info_tag, info_out, "flux_q_1mm", iarray, wq, wqr
   nk_get_info_tag, info_out, "flux_u_1mm", iarray, wu, wur
   
   ;; Changed iqu2poldeg (AR+NP, May 25th, 2016 -> sigma_p_plus, sigma_p_minus
   iqu2pol_info, info_out.(wi), info_out.(wq), info_out.(wu), $
                 info_out.(wir), info_out.(wqr), info_out.(wur), $
                 pol_deg, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                 old_formula=old_formula, mb3d=mb3d
   
   nk_get_info_tag, info_out, "pol_deg_1mm", 1, wp, wpr
   info_out.(wp)  = pol_deg
   info_out.(wpr) = sigma_p_plus ; take only the upper bound (will be the largest one in any case) May, 25th, 2016
   
   nk_get_info_tag, info_out, "pol_angle_1mm", 1, wa, war
   info_out.(wa) = alpha_deg
   info_out.(war) = sigma_alpha_deg
   
   ;;---------------------------------------------------------------------------------------------------------   
   ;; Also compute the results at the center when sources are weak and
   ;; may have not been properly located, hence biasing the results
   for iarray=1, 3 do begin
      nk_get_info_tag, info_out, "flux_center_i", iarray, wi, wir
      nk_get_info_tag, info_out, "flux_center_q", iarray, wq, wqr
      nk_get_info_tag, info_out, "flux_center_u", iarray, wu, wur
      
      ;; Changed iqu2poldeg (AR+NP, May 25th, 2016 -> sigma_p_plus, sigma_p_minus
      iqu2pol_info, info_out.(wi), info_out.(wq), info_out.(wu), $
                    info_out.(wir), info_out.(wqr), info_out.(wur), $
                    pol_deg, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                    old_formula=old_formula, mb3d=mb3d

      nk_get_info_tag, info_out, "pol_deg_center", iarray, wp, wpr
      info_out.(wp)  = pol_deg
      info_out.(wpr) = (sigma_p_plus+sigma_p_minus)/2.
      
      nk_get_info_tag, info_out, "pol_angle_center", iarray, wa, war
      info_out.(wa) = alpha_deg
      info_out.(war) = sigma_alpha_deg
   endfor

   ;; For the combined map
   nk_get_info_tag, info_out, "flux_center_i_1mm", 1, wi, wir
   nk_get_info_tag, info_out, "flux_center_q_1mm", 1, wq, wqr
   nk_get_info_tag, info_out, "flux_center_u_1mm", 1, wu, wur
   
   ;; Changed iqu2poldeg (AR+NP, May 25th, 2016 -> sigma_p_plus, sigma_p_minus
   iqu2pol_info, info_out.(wi), info_out.(wq), info_out.(wu), $
                 info_out.(wir), info_out.(wqr), info_out.(wur), $
                 pol_deg, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                 old_formula=old_formula, mb3d=mb3d
   
   nk_get_info_tag, info_out, "pol_deg_center_1mm", 1, wp, wpr
   info_out.(wp)  = pol_deg
   info_out.(wpr) = sigma_p_plus ; take only the upper bound (will be the largest one in any case) May, 25th, 2016
   
   nk_get_info_tag, info_out, "pol_angle_center_1mm", 1, wa, war
   info_out.(wa) = alpha_deg
   info_out.(war) = sigma_alpha_deg

   ;;------------------------------------------------------------------------------------------------------------
   ;; With aperture photometry to cross-check
   if keyword_set(aperture_photometry) or param.do_aperture_photometry then begin
      for iarray=1, 3 do begin
         nk_get_info_tag, info_out, "aperture_photometry_i", iarray, wi, wir
         nk_get_info_tag, info_out, "aperture_photometry_q", iarray, wq, wqr
         nk_get_info_tag, info_out, "aperture_photometry_u", iarray, wu, wur
         
         iqu2pol_info, info_out.(wi), info_out.(wq), info_out.(wu), $
                       info_out.(wir), info_out.(wqr), info_out.(wur), $
                       pol_deg, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                       old_formula=old_formula, mb3d=mb3d

         nk_get_info_tag, info_out, "pol_deg_apphot", iarray, wp, wpr
         info_out.(wp)  = pol_deg
         info_out.(wpr) = (sigma_p_plus+sigma_p_minus)/2.
         
         nk_get_info_tag, info_out, "pol_angle_apphot", iarray, wa, war
         info_out.(wa) = alpha_deg
         info_out.(war) = sigma_alpha_deg
      endfor

      nk_get_info_tag, info_out, "aperture_photometry_i_1mm", 1, wi, wir
      nk_get_info_tag, info_out, "aperture_photometry_q_1mm", 1, wq, wqr
      nk_get_info_tag, info_out, "aperture_photometry_u_1mm", 1, wu, wur
      
      iqu2pol_info, info_out.(wi), info_out.(wq), info_out.(wu), $
                    info_out.(wir), info_out.(wqr), info_out.(wur), $
                    pol_deg, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                    old_formula=old_formula, mb3d=mb3d
      
      nk_get_info_tag, info_out, "pol_deg_apphot_1mm", 1, wp, wpr
      info_out.(wp)  = pol_deg
      info_out.(wpr) = (sigma_p_plus+sigma_p_minus)/2.
      
      nk_get_info_tag, info_out, "pol_angle_apphot_1mm", 1, wa, war
      info_out.(wa) = alpha_deg
      info_out.(war) = sigma_alpha_deg
   endif
endif

if keyword_set(png) eq 1 then outplot, /close
if keyword_set(k_pdf) then begin
   pdf_file = strmid(ps_file, 0, strlen(ps_file) - 6)+'all.pdf'
   command = 'pdfunite ' + strjoin( listpdf+' ')+ ' '+ pdf_file
   spawn, command, res
   command = 'rm -f '+ strjoin( listpdf + ' ')
   spawn, command, res
endif


end
