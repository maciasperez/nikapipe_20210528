;; Add param to the inputs to add flexibilty (NP)

pro focus_liss, day, scan_num_list, focus_opt, $
                param=param, focus_list=focus_list, size=size, $
                numdet1_in=numdet1_in, numdet2_in=numdet2_in, $
                nopng=nopng, ps=ps, online=online, common_mode_radius=common_mode_radius, $
                polar=polar, noskydip=noskydip, RF=RF, sn_min_list=sn_min_list, sn_max_list=sn_max_list, $
                check=check, no_acq_flag=no_acq_flag, slow=slow, reset=reset, force=force, k_noise=k_noise, $
                jump = jump;, imbfits=imbfits, antimb = antimb

 
imbfits =  1
antimb =  1

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, " focus_liss, day, scan_num_list, $"
   print, "             param=param, focus_list=focus_list, size=size, $"
   print, "             numdet1_in=numdet1_in, numdet2_in=numdet2_in, $"
   print, "             nopng=nopng, ps=ps, online=online, imbfits=imbfits, common_mode_radius=common_mode_radius, $"
   print, "             polar=polar, noskydip=noskydip, RF=RF, sn_min_list=sn_min_list, sn_max_list=sn_max_list, $"
   print, "             check=check, no_acq_flag=no_acq_flag, slow=slow, reset=reset, force=force, k_noise=k_noise, $"
   print, "             antimb = antimb, jump = jump"
   return
endif

if keyword_set(online) and keyword_set(imbfits) then begin
   message, /info, "Please do not set /online and /imbfits at the same time"
   return
endif

if keyword_set(online) and (not keyword_set(focus_list)) then begin
   message, /info, "Please set focus_list keyword while working /online"
   return
endif

;; Ensure correct format for "day"
t = size( day, /type)
if t eq 7 then day = strtrim(day,2) else day = string( day, format="(I8.8)")

if not keyword_set(size) then size = 300.0

png = 1 - keyword_set(nopng)
if keyword_set(ps) then png=0

lambda_min = 1
lambda_max = 2
if keyword_set(one_mm_only) then lambda_max = 1
if keyword_set(two_mm_only) then lambda_min = 2


;; Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/"+day+"_"+strtrim(scan_num_list[0],2)
spawn, "mkdir -p "+output_dir

nscans = n_elements( scan_num_list)

var_list = ['Flux', 'FWHM', 'Ellipt', 'offaz', 'offel']

phi       = dindgen(100)/99.*2*!dpi
nvar      = n_elements( var_list)
res       = dblarr( 2, nvar, nscans) ; 2 bands, nvar variables, nscans scans
sigma_res = dblarr( 2, nvar, nscans) ; 2 bands, nvar variables, nscans scans
focus_opt = dblarr( 2, nvar)

if not keyword_set(param) then begin
   nika_pipe_default_param, scan_num_list[0], day, param
   param.map.size_ra    = size
   param.map.size_dec   = size
   param.map.reso       = 3.d0
   param.decor.method   = 'COMMON_MODE_KIDS_OUT'
   param.decor.common_mode.d_min = 40.
   param.decor.iq_plane.apply = 'no'
endif

if not keyword_set(focus_list) then focus_list = dblarr( nscans)

if not keyword_set(common_mode_radius) then common_mode_radius = 40.
nterms = 5
my_multiplot, 2, 2, pp, pp1, /rev, gap_x=0.1, gap_y=0.1

if keyword_set(reset) then begin
   for iscan=0, nscans-1 do begin
      scan_num = scan_num_list[iscan]
      save_file = !nika.save_dir+"/maps_"+strtrim(day,2)+"s"+strtrim(scan_num,2)+".save"
      spawn, "rm -f "+save_file
   endfor
endif

;; Main loop
for iscan=0, nscans-1 do begin

   scan_num = scan_num_list[iscan]

   ;;------------------------------------
   ;; Get focus information
   xml = 1                      ; default
   if keyword_set(online) then xml = 0
   
   if keyword_set(imbfits) then begin
      xml = 0

      nika_find_raw_data_file, scan_num, day, file, imb_fits_file, /silent

      iext = 1
      status = 0
      fooffset = [0]
      WHILE status EQ 0 AND  iext LT 100 DO BEGIN
         aux = mrdfits(  strtrim( imb_fits_file), iext, haux, status = status, /silent)
         extname = sxpar( haux, 'EXTNAME')
         if strupcase(extname) eq 'IMBF-SCAN' then begin
            focus_list[iscan] = sxpar( haux, 'FOCUSZ')
            print, "iext, focusz: ", iext, focus_list[iscan]
         endif
         iext = iext + 1
      endwhile


      imbHeader = HEADFITS( imb_fits_file,EXTEN='IMBF-scan')
      param.source = sxpar(imbheader, 'OBJECT')
   endif

   if xml eq 1 then begin
      parse_pako, scan_num, day, pako_str
      focus_list[iscan] = pako_str.focusz
   endif

   ;;----------------------------------------------
   ;; Process file
   
   save_file = !nika.save_dir+"/maps_"+strtrim(day,2)+"s"+strtrim(scan_num,2)+".save"
   if file_test(save_file) eq 1 then begin
      restore, save_file
      message, /info, "Restored "+save_file
   endif else begin
      message, /info, "Processing scan "+strtrim(scan_num,2)
      delvarx, sn_min, sn_max
      if keyword_set(sn_min_list) then sn_min = sn_min_list[iscan]
      if keyword_set(sn_max_list) then sn_max = sn_max_list[iscan]
      rta_map, day, scan_num, maps, slow=slow, /azel, /educated, map_t_fit_params=map_t_fit_params, $
               err_map_t_fit_params=err_map_t_fit_params, RF=RF, $
               sn_min=sn_min, sn_max=sn_max, check=check, no_acq_flag=no_acq_flag, force=force, png=png, $
               k_noise=k_noise,  imbfits = imbfits, jump = jump

; save alreay done in rta_map
;      save, file = save_file, $
;            maps, map_t_fit_params, err_map_t_fit_params
   endelse

   ;; Retrieve results
   for lambda=lambda_min, lambda_max do begin
      res[       lambda-1, 0, iscan] = map_t_fit_params[lambda-1,0] ; flux
      res[       lambda-1, 1, iscan] = map_t_fit_params[lambda-1,1] ; fwhm
      sigma_res[ lambda-1, 0, iscan] = err_map_t_fit_params[ lambda-1,0] ; sqrt( covar[1,1])
      sigma_res[ lambda-1, 1, iscan] = err_map_t_fit_params[ lambda-1,1]
   endfor

endfor


;; Fits
if nscans lt 3 then begin
   message, /info, "not enough scans to fit anything yet"
   return
endif else begin
   xra = max(focus_list)-min(focus_list)
   xra = min(focus_list) + [-0.2, 1.2]*xra
   xx = dindgen(100)/99.*(max(xra)-min(xra)) + min(xra)
   make_ct, n_elements(focus_list), ct
   wind, 1, 1, /free, /large
   outplot, file=output_dir+'/fits', png=png, ps=ps
   my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1
   for lambda=lambda_min, lambda_max do begin
      for ivar=0, 1 do begin
         coeff = poly_fit( focus_list, res[lambda-1,ivar,*], measure_errors=sigma_res[lambda-1,ivar,*], 2)
         fit = xx*0.d0
         for ii=0, n_elements(coeff)-1 do fit += coeff[ii]*xx^ii
         ;;yra = max(res[lambda-1,ivar,*])-min(res[lambda-1,ivar,*])
         yra = max(fit) - min(fit)
         yra = min(fit) + [-0.2, 1.4]*yra
         ploterror, focus_list, res[lambda-1,ivar,*], sigma_res[lambda-1,ivar,*], $
                    xtitle='Focus', psym=8, position=pp[lambda-1,ivar,*], /noerase, yra=yra, /ys, $
                    title=param.source
         for ii=0, n_elements(focus_list)-1 do $
            oploterror, [focus_list[ii]], [res[lambda-1,ivar,ii]], [sigma_res[lambda-1,ivar,ii]], $
                        psym=8, col=ct[ii], errcol=ct[ii]
         oplot, xx, fit, col=250
         legendastro, var_list[ivar]+" ("+strtrim(lambda,2)+"mm)", box=0
         legendastro, 'Opt. Focus: '+num2string(-coeff[1]/2.0/coeff[2]), box=0, /right, /bottom
         legendastro, day+"s"+strtrim(scan_num_list,2), /right, box=0, textcol=ct
         focus_opt[lambda-1,ivar] = -coeff[1]/2.0/coeff[2]

         ;;--------------------
         ;; Derive a posteriori error bars and see if the fit changes
         coeff = poly_fit( focus_list, res[lambda-1,ivar,*], 2)
         fit = focus_list*0.d0
         for ii=0, n_elements(coeff)-1 do fit += coeff[ii]*focus_list^ii
         ;oplot, focus_list, fit, psym=5
         measure_errors = abs( res[lambda-1,ivar,*]-fit)

         chi2 = total( (res[lambda-1,ivar,*]-fit)^2/measure_errors^2)/n_elements(focus_list)

         ;; Renormalize the errors to have a chi2=1 if the fit is
         ;; good                                                                       
         measure_errors *= sqrt( chi2)

         coeff = poly_fit( focus_list, res[lambda-1,ivar,*], measure_errors=measure_errors, 2)
         fit = xx*0.d0
         for ii=0, n_elements(coeff)-1 do fit += coeff[ii]*xx^ii
         oploterror, focus_list, res[lambda-1,ivar,*], measure_errors, psym=6
         oplot, xx, fit
         legendastro, num2string(-coeff[1]/2.0/coeff[2]), /bottom, box=0
         ;;--------------------


      endfor
   endfor
   !p.multi = 0
   outplot, /close

   sfmt = "(A10)"
   fmt  = "(F10.2)"
   print, ''
   print, '_________________________________________________________________________________________'
   print, "      "+$
          string("Scan", format=sfmt)+", "+string("Focus", format=sfmt)+", "+$
          string("Flux", format=sfmt)+", "+string("FWHM", format=sfmt)+", "+$
          string("Ellip.", format=sfmt)+", "+string("Cor az", format=sfmt)+", "+string("Cor el", format=sfmt)
   print, '_________________________________________________________________________________________'
;;---------------- Print the param found
   idx =  sort(focus_list)        ;reorder by focus
   for i=0, n_elements(idx)-1 do begin
      ii = idx[i]
      print, '1mm   '+string( scan_num_list[ii], format=sfmt)+", "+$
             string( focus_list[ii],  format=fmt)+", "+$
             string( res[0, 0, ii], format=fmt)+", "+$
             string( res[0, 1, ii], format=fmt)+", "+$
             string( res[0, 2, ii], format=fmt)+", "+$
             string( res[0, 3, ii], format=fmt)+", "+$
             string( res[0, 4, ii], format=fmt)

      print, '2mm   '+string( scan_num_list[ii], format=sfmt)+", "+$
             string( focus_list[ii],  format=fmt)+", "+$
             string( res[1, 0, ii], format=fmt)+", "+$
             string( res[1, 1, ii], format=fmt)+", "+$
             string( res[1, 2, ii], format=fmt)+", "+$
             string( res[1, 3, ii], format=fmt)+", "+$
             string( res[1, 4, ii], format=fmt)
      
      print, '--------------------------------------------------------------------------------------'
   endfor

   print, ""
   print, "      "+$
          string("Flux", format=sfmt)+", "+$
          string("Cor az", format=sfmt)+", "+$
          string("Cor el", format=sfmt)
   diff = abs(focus_list-focus_opt[0,0])
   w = (where( diff eq min(diff)))[0]
   print, '1mm   '+string( res[0, 0, w], format=fmt)+", "+$
          string( res[0, 3, w], format=fmt)+", "+$
          string( res[0, 4, w], format=fmt)
   diff = abs(focus_list-focus_opt[1,0])
   w = (where( diff eq min(diff)))[0]
   print, '2mm   '+string( res[1, 0, w], format=fmt)+", "+$
          string( res[1, 3, w], format=fmt)+", "+$
          string( res[1, 4, w], format=fmt)

   print, ""
   print, "      "+$
          string("Beam", format=sfmt)+", "+$
          string("Cor az", format=sfmt)+", "+$
          string("Cor el", format=sfmt)
   diff = abs(focus_list-focus_opt[0,1])
   w = (where( diff eq min(diff)))[0]
   print, '1mm   '+string( res[0, 1, w], format=fmt)+", "+$
          string( res[0, 3, w], format=fmt)+", "+$
          string( res[0, 4, w], format=fmt)
   diff = abs(focus_list-focus_opt[1,1])
   w = (where( diff eq min(diff)))[0]
   print, '2mm   '+string( res[1, 0, w], format=fmt)+", "+$
          string( res[1, 3, w], format=fmt)+", "+$
          string( res[1, 4, w], format=fmt)

   print, '----------------------------------------------------------------------------'
   print, ''
   print, ''
   print, 'Focus found (Flux)   1mm', string(focus_opt[0,0],format='(F10.2)')
   print, '                     2mm', string(focus_opt[1,0],format='(F10.2)')
   print, '----------------------------------------------------------------------------'
   print, 'Focus found (Beam)   1mm', string(focus_opt[0,1],format='(F10.2)')
   print, '                     2mm', string(focus_opt[1,1],format='(F10.2)')
endelse

;; Get useful information for the logbook
;; use the first scan
restore, output_dir+"/log_info.save"
i=0
while log_info.result_name[i] ne "" do i++
log_info.result_name[i] = "Opt focus 1mm (flux)"
log_info.result_value[i] = focus_opt[0,0]
log_info.result_name[i+1] = "Opt focus 2mm (flux)"
log_info.result_value[i+1] = focus_opt[1,0]
log_info.result_name[i+2] = "Opt focus 1mm (FWHM)"
log_info.result_value[i+2] = focus_opt[0,1]
log_info.result_name[i+3] = "Opt focus 2mm (FWHM)"
log_info.result_value[i+3] = focus_opt[1,1]

save, file=output_dir+"/log_info.save", log_info

;; Create a html page with plots from this scan
nika_logbook_sub, scan_num_list[0], day

end
