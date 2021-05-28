

; log_iram_tel_n2r25

;; ;; All plots
;; source_list = '0923+392'

;source_list = '0851+202'
;source_list = '3C345'
;source_list = '2251+158'
;source_list = '0355+508'
;source_list = '3C147'
source_list = ['3C279', '3C273']

;; pro check_polangle_rotation, source_list, projection, noplot=noplot

noplot = 0
projection = 'nasmyth'            ; 'radec'  
process       = 1
reset_results = 0
reset_preproc = 0

mail = 0
png  = 0
run = 32
fwhm_max = 15

array   = 'A1' ;'A1'  ;'A3'  ;'A1+A3'
version = 'v0' ; 'v1'
norm    = 0

for isource=0, n_elements(source_list)-1 do begin
   source = source_list[isource]
   dir = !nika.plot_dir+"/"+source+"_"+strupcase(projection)+"_"+version
;;   dir = !nika.plot_dir+"/"+source+"_"+strupcase(projection)+"_"+version+'_sign_new_pol_synchro_1'

   ;; List scans for this source
   get_qso_scan_list, source, scan_list_in, myday_list
   nscans = n_elements(scan_list_in)
   make_ct, n_elements(myday_list), ct_list
   nday = n_elements(myday_list) 
   p_est_day = dblarr(nday)
   
   if process eq 1 then begin
      reduce_quasars, source, scan_list_in, $
                      reset_results=reset_results, reset_preproc=reset_preproc, $
                      projection=projection, version=version, lkg_corr=lkg_corr
   endif

   if noplot eq 0 then begin
      openw, lu, "polangle_rotation_summary_"+source+"_"+array+".dat", /get_lun
      printf, lu, "# day, pol_deg, sigma_p_plus, sigma_p_minus, alpha(deg), sigma_alpha, "+$
              "p1_est, sigma_p1_est_plus, sigma_p1_est_minus, beta_est(deg), sigma_beta_est"

      ;; Loop on days
      for iday=0, n_elements(myday_list)-1 do begin
         myday_list_iday = myday_list[iday]

         if myday_list[iday] eq '-1' then begin
            nick = 'all_days'
            nw = nscans
            scan_list = scan_list_in
            ;; coltable = ct_list
         endif else begin
            ;; coltable = ct_list[iday]
            nick = strtrim(myday_list[iday],2)
            day_list = strmid(scan_list_in,0,8)
            w = where( day_list eq strtrim(myday_list[iday],2), nw)
            scan_list = scan_list_in[w]
         endelse
         if nw ne 0 then begin
            plot_file = 'polangle_summary_'+strtrim(source)+"_"+nick+"_"+projection
            delvarx, coltable
            check_polangle_plots, dir, scan_list, fwhm_max, source, myday_list_iday, $
                                  pol_deg_quasar, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                                  p1_est, sigma_p1_est_plus, sigma_p1_est_minus, beta_est, sigma_beta_est, $
                                  p_est, psi_est, $
                                  ps=ps, png=png, plot_file=plot_file, coltable=coltable, array=array, norm=norm
            
            ;; if myday_list[iday] ne '-1' then begin
            ;;    openw, 1, 'p_est_day.dat', /append
            ;;    for iscan=0, n_elements(scan_list)-1 do begin
            ;;       printf, 1, scan_list[iscan]+', '+strtrim(p_est,2)
            ;;    endfor
            ;;    close, 1
            ;; endif
 
            fmt_p = '(F5.3)'
            fmt_a = '(F7.2)'
            if myday_list[iday] eq '-1' then myday_str='all' else myday_str=myday_list[iday]
            printf, lu, $
                    myday_str+', '+$
                    string( pol_deg_quasar, form=fmt_p)+", "+$
                    string( sigma_p_plus, form=fmt_p)+", "+$
                    string( sigma_p_minus, form=fmt_p)+", "+$
                    string( alpha_deg, form=fmt_a)+", "+$
                    string( sigma_alpha_deg, form=fmt_a)+", "+$
                    string( p1_est, form=fmt_p)+", "+$
                    string( sigma_p1_est_plus, form=fmt_p)+", "+$
                    string( sigma_p1_est_minus, form=fmt_p)+", "+$
                    string( beta_est, form=fmt_a)+", "+$
                    string( sigma_beta_est, form=fmt_a)
            
            if defined(except) eq 0 then except = !d.window else except = [except, !d.window]
            wd, /all, except=except
            if mail eq 1 then exitmail, attach=plot_file+".png"
         endif
      endfor
      close, lu
   endif
   
endfor

end
