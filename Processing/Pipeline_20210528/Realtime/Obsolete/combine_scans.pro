
;; Scan_list must be expressed in the form '201401s23' etc...
pro combine_scans, scan_list, maps_tot, bg_rms, reset=reset, $
                   nopng=nopng, ps=ps, param=param, $
                   xmap=xmap, ymap=ymap, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
                   noskydip=noskydip, RF=RF, lissajous=lissajous, $
                   azel=azel, diffuse=diffuse, $
                   convolve=convolve, educated=educated, focal_plane=focal_plane, $
                   map_t_fit_params=map_t_fit_params, err_map_t_fit_params=err_map_t_fit_params, check=check, $
                   calibrate=calibrate, flux_1mm=flux_1mm, flux_2mm=flux_2mm, no_acq_flag=no_acq_flag, $
                   online=online, p2cor=p2cor, p7cor=p7cor, force=force,  jump =  jump, method = method, $
                   xsize = xsize, ysize = ysize
;, imbfits=imbfits,  antimb =  antimb

imbfits = 1
antimb = 1


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, " combine_scans, scan_list, maps_tot, bg_rms, reset=reset, $"
   print, "                nopng=nopng, ps=ps, param=param, $"
   print, "                xmap=xmap, ymap=ymap, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $"
   print, "                noskydip=noskydip, RF=RF, lissajous=lissajous, $"
   print, "                azel=azel, diffuse=diffuse, $"
   print, "                convolve=convolve, educated=educated, focal_plane=focal_plane, $"
   print, "                map_t_fit_params=map_t_fit_params, err_map_t_fit_params=err_map_t_fit_params, check=check, $"
   print, "                calibrate=calibrate, flux_1mm=flux_1mm, flux_2mm=flux_2mm, no_acq_flag=no_acq_flag, $"
   print, "                online=online, imbfits=imbfits, p2cor=p2cor, p7cor=p7cor, force=force"
   return
endif

if keyword_set(diffuse) and keyword_set(fast) then begin
   message, /info, "Please do not set /diffuse together with /fast"
   return
endif

nscans = n_elements(scan_list)

if keyword_set(reset) then begin
   for iscan=0, nscans-1 do begin
      save_file = !nika.save_dir+"/maps_"+scan_list[iscan]+".save"
      spawn, "rm -f "+save_file
   endfor
endif

educated = 1
png      = 1 - keyword_set(nopng)

;; Reduce scans if not alreay done or restore results
;; The first restore ensures that all following calls to rta_map will
;; be done with the same input param (resolution, coordinates etc..)
for iscan=0, nscans-1 do begin
   
   r        = strsplit( scan_list[iscan], "s", /extract)
   day      = r[0]
   scan_num = r[1]

   xml = 1                      ; default
   if keyword_set(imbfits) then begin
      xml = 0
      init_pako_str, pako_str
      pako_str.obs_type = "pointing"
      
      nika_find_raw_data_file, scan_num, day, file, imb_fits_file, /silent
      
      test  = file_test( imb_fits_file, /dir) ; is a directory
      test2 = file_test( imb_fits_file)       ; file/dir exists
      
      antexist = (test eq 0) and (test2 eq 1)
      if antexist then begin 
         imbHeader = HEADFITS( imb_fits_file,EXTEN='IMBF-scan')
         pako_str.p2cor = SXPAR(imbHeader, 'P2COR')/!pi*180.d0*3600.d0
         pako_str.p7cor = SXPAR(imbHeader, 'P7COR')/!pi*180.d0*3600.d0
         r = mrdfits( imb_fits_file, 1, /silent)
         pako_str.NAS_OFFSET_X = r.XOFFSET/!arcsec2rad
         pako_str.NAS_OFFSET_Y = r.YOFFSET/!arcsec2rad
         a = mrdfits( imb_fits_file,0,hdr,/sil)
         pako_str.obs_type = sxpar( hdr,'OBSTYPE',/silent)
         pako_str.source = sxpar(imbheader, 'OBJECT')
         ;; iext = 1
         ;; status = 0
         ;; WHILE status EQ 0 AND  iext LT 100 DO BEGIN
         ;;    aux = mrdfits(  strtrim( imb_fits_file), iext, haux, status = status, /silent)
         ;;    extname = sxpar( haux, 'EXTNAME')
         ;;    if strupcase(extname) eq 'IMBF-SCAN' then begin
         ;;       pako_str.focusz = sxpar( haux, 'FOCUSZ')
         ;;       print, "iext, focusz: ", iext, focusz
         ;;    endif
         ;;    iext = iext + 1
         ;; endwhile
      endif else begin
         message, /info, "the AntennaIMBfits file does not exist"
         return
      endelse
   endif

   if xml eq 1 then parse_pako, scan_num, day, pako_str

   save_file = !nika.save_dir+"/maps_"+scan_list[iscan]+".save"
   if file_test(save_file) eq 1 then begin
      restore, save_file
      message, /info, "Restored "+save_file+", RMS = "+strtrim(bg_rms*1000,2)+" mJy/Beam"
   endif else begin
      message, /info, "Reducing "+scan_list[iscan]
      if defined(param) then begin
         param.scan_num = scan_num
         param.day      = param.day
      endif

      rta_map, day, scan_num, maps, rms, png=png, ps=ps, param=param, $
               xmap=xmap, ymap=ymap, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
               noskydip=noskydip, RF=RF, lissajous=lissajous, $
               azel=azel, diffuse=diffuse, $
               convolve=convolve, educated=educated, focal_plane=focal_plane, $
               map_t_fit_params=map_t_fit_params, err_map_t_fit_params=err_map_t_fit_params, check=check, $
               calibrate=calibrate, flux_1mm=flux_1mm, flux_2mm=flux_2mm, no_acq_flag=no_acq_flag, $
               online=online, imbfits=imbfits, p2cor=p2cor, p7cor=p7cor, force=force,  antimb = antimb, jump = jump,  method = method, $
               xsize = xsize, ysize = ysize

   endelse
   
   if iscan eq 0 then begin
      maps_tot = maps ; init
      nx = n_elements(maps.a.jy[*,0])
      ny = n_elements(maps.a.jy[0,*])
      maps_tot.a.jy   = dblarr( nx, ny)
      maps_tot.a.var  = dblarr( nx, ny)
      maps_tot.a.time = dblarr( nx, ny)
      maps_tot.b.jy   = dblarr( nx, ny)
      maps_tot.b.var  = dblarr( nx, ny)
      maps_tot.b.time = dblarr( nx, ny)

   endif

   w = where( finite(maps.a.var) and maps.a.var gt 0, nw)
   if nw eq 0 then message, "No pixel with a finite and positive variance at 1mm ?!"
   maps_tot.a.jy[w]   += maps.a.jy[w]/maps.a.var[w]
   maps_tot.a.var[w]  +=         1.d0/maps.a.var[w]
   maps_tot.a.time[w] += maps.a.time[w]
   ;; simple average to cross-check
   ;maps_tot.a.jy[w]   += maps.a.jy[w]
   ;maps_tot.a.var[w]  +=         1.d0

   w = where( finite(maps.b.var) and maps.b.var gt 0, nw)
   if nw eq 0 then message, "No pixel with a finite and positive variance at 2mm ?!"
   maps_tot.b.jy[w]   += maps.b.jy[w]/maps.b.var[w]
   maps_tot.b.var[w]  +=         1.d0/maps.b.var[w]
   maps_tot.b.time[w] += maps.b.time[w]
   ;; simple average to cross-check
   ;maps_tot.b.jy[w]   += maps.b.jy[w]
   ;maps_tot.b.var[w]  +=         1.d0

endfor

;; Normalize
w = where( maps_tot.a.var ne 0)
maps_tot.a.jy[w] /= maps_tot.a.var[w]
maps_tot.a.var[w] = 1.d0/maps_tot.a.var[w]

w = where( maps_tot.b.var ne 0)
maps_tot.b.jy[w] /= maps_tot.b.var[w]
maps_tot.b.var[w] = 1.d0/maps_tot.b.var[w]

;;=====================================================================
;; Analyze
nickname = pako_str.source

wind, 1, 1, /free, xs=1200
my_multiplot, 2, 1, pp, pp1

box = ['A', 'B']
phi = dindgen( 200)/199*2*!dpi

;; For now we'll assume they were all produced with the same
;; list of kids
kidpar1 = mrdfits( param.kid_file.a, 1, /silent)
kidpar2 = mrdfits( param.kid_file.b, 1, /silent)

;; Display
xtitle='RA'
ytitle='DEC'
dx_leg = "!7D!3RA"
dy_leg = "!7D!3Dec"
coord = "RA, Dec"
;;if keyword_set(convolve) then coord = [coord, "Beam convolved"]

lambda_min = 1
lambda_max = 2
offsetmap            = dblarr( 2, 2)
map_t_fit_params     = dblarr( 2, 2)
flux_mes             = dblarr( 2)
rms                  = dblarr( 2)

for lambda=lambda_min, lambda_max do begin
   junk = execute( "map     = maps_tot."+box[lambda-1])
   junk = execute( "map_var = maps."+box[lambda-1]+".var")
   junk = execute( "kidpar  = kidpar"+strtrim(lambda,2))
   
   ;; Point source photometry
   fwhm = !nika.fwhm_nom[lambda-1]
   nika_map_noise_estim, param, map, xmap, ymap, fwhm, flux, $
                         sigma_flux, sigma_bg, map_conv, fit_params, bg_rms, $
                         flux_center, sigma_flux_center, $
                         educated=educated, input_fit_par=input_fit_par

   ;; store results
   flux_mes[  lambda-1]   = flux
   offsetmap[ lambda-1,0] = fit_params[4]
   offsetmap[ lambda-1,1] = fit_params[5]
   rms[       lambda-1]   = bg_rms

   w1 = where( kidpar.type eq 1 and kidpar.array eq lambda, nw1)
   matrix_surface = nw1 * kidpar[w1[0]].grid_step^2
   ;;scan_surface   = (max(data.ofs_az)-min(data.ofs_az)) * (max(data.ofs_el)-min(data.ofs_el))
;   rho            = (matrix_surface/scan_surface) < 1.d0 ; fraction of scan spent on the source
   ndet_per_beam  = fwhm^2/kidpar[w1[0]].grid_step^2
;   sensit_toi     = sigma_flux*1000*sqrt(rho*param.integ_time[0])/sqrt(ndet_per_beam)
;   sensit_map     = sigma_bg  *1000*sqrt(rho*param.integ_time[0])/sqrt(ndet_per_beam)

   ;; Sensitivity using Remi's formula (At map center)
   d         = sqrt( xmap^2 + ymap^2)
   loc_time  = where( d lt 20.)  ; region where time per pixel is homogeneous
   time_pix  = mean( map.time[loc_time]) * kidpar[w1[0]].grid_step^2/param.map.reso^2
   NEFD      = sigma_bg * sqrt(time_pix) * 1000

   xx  = fit_params[2]*cos(phi)
   yy  = fit_params[3]*sin(phi)
   xx1 =  cos(fit_params[6])*xx + sin(fit_params[6])*yy
   yy1 = -sin(fit_params[6])*xx + cos(fit_params[6])*yy
   
   !mamdlib.coltable = 1
   if keyword_set(convolve) then disp_map = map_conv else disp_map = map.jy

   w = where( map_var gt 0, nw, compl=wcompl, ncompl=nwcompl)
   if nwcompl ne 0 then map_var[wcompl] = !values.d_nan
   var_med = median( map_var[w])
   ;imrange = minmax( disp_map[where( map_var le var_med and map_var gt 0)])
   imrange = [-1,1]*4*stddev( disp_map[where( map_var le var_med and map_var gt 0)])
   imview, disp_map, xmap=xmap, ymap=ymap, /noerase, imrange=imrange, $
           title=nickname+" "+strtrim(lambda,2)+'mm', $
           xtitle=xtitle, ytitle=ytitle, position=pp1[lambda-1,*]
   loadct, /silent, 39
   oplot, [0], [0], psym=1, syms=2, col=150
   oplot, fwhm*!fwhm2sigma*cos(phi), fwhm*!fwhm2sigma*sin(phi), col=150
   oplot, fit_params[4] + xx1, fit_params[5] + yy1, col=250
   oplot, [fit_params[4]], [fit_params[5]], psym=1, col=250
   legendastro, coord, box=0, /right, charsize=1, textcol=255
   legendastro, [dx_leg+" "+num2string(fit_params[4]), $
                 dy_leg+" "+num2string(fit_params[5]), $
                 'Peak '+num2string(fit_params[1]), $
                 'FWHM '+num2string( sqrt(fit_params[2]*fit_params[3])/!fwhm2sigma)], $
                textcol=255, box=0
   legendastro, [$;'Tau = '+num2string(kidpar[w1[0]].tau_skydip), $
                ;'Flux = '+num2string( flux)+" +- "+num2string(sigma_flux)+" ("+num2string(sigma_bg)+") Jy", $
                'Flux = '+num2string( flux)+" +- "+num2string(sigma_bg)+" Jy", $
                'Flux (center) = '+num2string(flux_center)+" +- "+num2string(sigma_flux_center), $
                'NEFD '+num2string(NEFD)+" mJy/Beam.s!u1/2!n", $
                'RMS = '+num2string(bg_rms)+" Jy/Beam"], $
                ;;'Sens. TOI (Map) = '+num2string(sensit_toi)+"
                ;;("+num2string(sensit_map)+") mJy./Beam.s!u1/2!n"], $
                textcol=[250, 150, 255, 255], box=0, /bottom, charsize=1

; FXD changed formatting to mJy
   print, ""
   print, "--------------------------------------------------------------"
   print, "   "+strtrim(lambda,2)+"mm : flux          = "+num2string( flux*1000)+" +- "+num2string(sigma_bg*1000)+" mJy"
   print, "   "+strtrim(lambda,2)+"mm : flux (center) = "+num2string(flux_center*1000)+" +- "+num2string(sigma_flux_center*1000)+" mJy"
   print, "   "+strtrim(lambda,2)+"mm : RMS           = "+num2string(bg_rms*1000)+" mJy/Beam"

   ;; print, ""
   ;; print, "--------------------------------------------------------------"
   ;; print, "   "+strtrim(lambda,2)+"mm : flux          = "+num2string( flux)+" +- "+num2string(sigma_bg)+" Jy"
   ;; print, "   "+strtrim(lambda,2)+"mm : flux (center) = "+num2string(flux_center)+" +- "+num2string(sigma_flux_center)+" Jy"
   ;; print, "   "+strtrim(lambda,2)+"mm : RMS           = "+num2string(bg_rms)+" Jy/Beam"



endfor
outplot, /close

end

