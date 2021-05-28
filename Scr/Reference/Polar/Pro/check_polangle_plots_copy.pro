
pro check_polangle_plots, dir, scan_list_in, fwhm_max, source, $
                          pol_deg_quasar, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                          p1_est, sigma_p1_est_plus, sigma_p1_est_minus, beta_est, sigma_beta_est, $
                          nickname=nickname, $
                          ps=ps, png=png, plot_dir=plot_dir, $
                          plot_file=plot_file, coltable=coltable, array=array
  
if not keyword_set(plot_dir) then plot_dir = "."
if not keyword_set(nickname) then begin
   nickname = file_basename( dir)
endif

;; Init default values to protect the output when we loop over several days
pol_deg_quasar     = !values.d_nan
sigma_p_plus       = !values.d_nan
sigma_p_minus      = !values.d_nan
alpha_deg          = !values.d_nan
sigma_alpha_deg    = !values.d_nan
p1_est             = !values.d_nan
sigma_p1_est_plus  = !values.d_nan
sigma_p1_est_minus = !values.d_nan
beta_est           = !values.d_nan
sigma_beta_est     = !values.d_nan


; backup input
scan_list = scan_list_in

nscans           = n_elements(scan_list)
fwhm_res         = dblarr(nscans)
polangle         = dblarr(nscans)
err_polangle     = dblarr(nscans)
polangle_a1      = dblarr(nscans)
err_polangle_a1  = dblarr(nscans)
polangle_a3      = dblarr(nscans)
err_polangle_a3  = dblarr(nscans)
polangle_1mm     = dblarr(nscans)
err_polangle_1mm = dblarr(nscans)
elevation        = dblarr(nscans)
paral            = dblarr(nscans)
mjd              = dblarr(nscans)
keep             = intarr(nscans)
tau225           = dblarr(nscans)
phase_hwp        = dblarr(nscans)
pol_deg          = dblarr(nscans)
err_pol_deg      = dblarr(nscans)

i_1mm_res            = dblarr(nscans)
q_1mm_res            = dblarr(nscans)
u_1mm_res            = dblarr(nscans)
err_i_1mm_res        = dblarr(nscans)
err_q_1mm_res        = dblarr(nscans)
err_u_1mm_res        = dblarr(nscans)

i_a1_res            = dblarr(nscans)
q_a1_res            = dblarr(nscans)
u_a1_res            = dblarr(nscans)
err_i_a1_res        = dblarr(nscans)
err_q_a1_res        = dblarr(nscans)
err_u_a1_res        = dblarr(nscans)

i_a3_res            = dblarr(nscans)
q_a3_res            = dblarr(nscans)
u_a3_res            = dblarr(nscans)
err_i_a3_res        = dblarr(nscans)
err_q_a3_res        = dblarr(nscans)
err_u_a3_res        = dblarr(nscans)

phase_motor      = dblarr(nscans)
imr = [-1,1]/10.
;; Check for stripes on the I maps and retrieve results
!p.charsize = 0.7
for iscan=0, nscans-1 do begin
   file = dir+"/v_1/"+scan_list[iscan]+"/results.save"
   if file_test(file) then begin
      keep[iscan] = 1
      nk_read_csv_2, dir+"/v_1/"+scan_list[iscan]+"/info.csv", info1
      
      fwhm_res[iscan]        = info1.result_fwhm_1mm
      polangle[iscan]        = info1.result_pol_angle_1mm
      err_polangle[iscan]    = info1.result_err_pol_angle_1mm

      polangle_a1[iscan]     = info1.result_pol_angle_1
      err_polangle_a1[iscan] = info1.result_err_pol_angle_1
      polangle_a3[iscan]     = info1.result_pol_angle_3
      err_polangle_a3[iscan] = info1.result_err_pol_angle_3
      polangle_1mm[iscan]     = info1.result_pol_angle_1mm
      err_polangle_1mm[iscan] = info1.result_err_pol_angle_1mm

      elevation[iscan]       = info1.result_elevation_deg
      paral[iscan]           = info1.paral
      mjd[iscan]             = info1.mjd
      tau225[iscan]          = info1.tau225
      phase_hwp[iscan]       = info1.phase_hwp*!radeg
      phase_motor[iscan]     = info1.phase_hwp_motor_position

      ;; i_res[iscan]           = info1.result_flux_center_i_1mm
      ;; q_res[iscan]           = info1.result_flux_center_q_1mm
      ;; u_res[iscan]           = info1.result_flux_center_u_1mm
      ;; err_i_res[iscan]       = info1.result_err_flux_center_i_1mm
      ;; err_q_res[iscan]       = info1.result_err_flux_center_q_1mm
      ;; err_u_res[iscan]       = info1.result_err_flux_center_u_1mm

      i_1mm_res[iscan]           = info1.result_flux_i_1mm
      q_1mm_res[iscan]           = info1.result_flux_q_1mm
      u_1mm_res[iscan]           = info1.result_flux_u_1mm
      err_i_1mm_res[iscan]       = info1.result_err_flux_i_1mm
      err_q_1mm_res[iscan]       = info1.result_err_flux_q_1mm
      err_u_1mm_res[iscan]       = info1.result_err_flux_u_1mm

      i_a1_res[iscan]           = info1.result_flux_i1
      q_a1_res[iscan]           = info1.result_flux_q1
      u_a1_res[iscan]           = info1.result_flux_u1
      err_i_a1_res[iscan]       = info1.result_err_flux_i1
      err_q_a1_res[iscan]       = info1.result_err_flux_q1
      err_u_a1_res[iscan]       = info1.result_err_flux_u1
      
      i_a3_res[iscan]           = info1.result_flux_i3
      q_a3_res[iscan]           = info1.result_flux_q3
      u_a3_res[iscan]           = info1.result_flux_u3
      err_i_a3_res[iscan]       = info1.result_err_flux_i3
      err_q_a3_res[iscan]       = info1.result_err_flux_q3
      err_u_a3_res[iscan]       = info1.result_err_flux_u3

      pol_deg[iscan]     = info1.result_pol_deg_1mm
      err_pol_deg[iscan] = info1.result_err_pol_deg_1mm
   endif
endfor

;; Plots and fits
w = where( keep eq 1 and fwhm_res lt fwhm_max, nw)
if nw eq 0 then begin
   message, /info, "No scan was processed ?"
   return
endif
scan_list        = scan_list[w]
fwhm_res         = fwhm_res[w]
polangle         = polangle[w]
err_polangle     = err_polangle[w]
polangle_a1      = polangle_a1[w]
err_polangle_a1  = err_polangle_a1[w]
polangle_a3      = polangle_a3[w]
err_polangle_a3  = err_polangle_a3[w]
polangle_1mm     = polangle_1mm[w]
err_polangle_1mm = err_polangle_1mm[w]
elevation        = elevation[w]
paral            = paral[w]
mjd              = mjd[w]
tau225           = tau225[w]
phase_hwp        = phase_hwp[w]
i_1mm_res        = i_1mm_res[w]
q_1mm_res        = q_1mm_res[w]
u_1mm_res        = u_1mm_res[w]
err_i_1mm_res    = err_i_1mm_res[w]
err_q_1mm_res    = err_q_1mm_res[w]
err_u_1mm_res    = err_u_1mm_res[w]

i_a1_res        = i_a1_res[w]
q_a1_res        = q_a1_res[w]
u_a1_res        = u_a1_res[w]
err_i_a1_res    = err_i_a1_res[w]
err_q_a1_res    = err_q_a1_res[w]
err_u_a1_res    = err_u_a1_res[w]

i_a3_res        = i_a3_res[w]
q_a3_res        = q_a3_res[w]
u_a3_res        = u_a3_res[w]
err_i_a3_res    = err_i_a3_res[w]
err_q_a3_res    = err_q_a3_res[w]
err_u_a3_res    = err_u_a3_res[w]

pol_deg          = pol_deg[w]
err_pol_deg      = err_pol_deg[w]
phase_motor      = phase_motor[w]

mjd -= mjd[0]
nscans = n_elements(scan_list)

message, /info, "fix me: adding 180 to negative parallactic angles ?"
w = where( paral lt 0, nw)
if nw ne 0 then paral[w] += 180

print, ""
message, /info, "fix me: correcting paral by hand"
w = where( paral le 50, nw)
if nw ne 0 then paral[w] += 180
;;stop

day = strmid( scan_list, 0, 8)
myday = day[UNIQ(day, SORT(day))]
ndays = n_elements(myday)
index = indgen(nscans)

;; Put angles between [-90,90] for convenience
polangle_a1  = atan( tan(polangle_a1*!dtor))*!radeg
polangle_a3  = atan( tan(polangle_a3*!dtor))*!radeg
polangle_1mm = atan( tan(polangle_1mm*!dtor))*!radeg

wind, 1, 1, /free, /large
!p.multi=[0,2,2]
plot, polangle_a1, psym=-8, title='Polangle A1',/xs
legendastro, 'See if you need to add/remove 180 somewhere'
plot, polangle_a3, psym=-8, title='Polangle A3',/xs
legendastro, 'See if you need to add/remove 180 somewhere'
plot, polangle_1mm, psym=-8, title='Polangle 1mm',/xs
legendastro, 'See if you need to add/remove 180 somewhere'
plot, paral, psym=-8, /xs, title='Paral'
legendastro, 'See if you need to add/remove 180 somewhere'
!p.multi=0
print, "polangle_a1: ", polangle_a1
print, ""
print, "polangle_a3: ", polangle_a3
print, ""
print, "polangle_1mm: ", polangle_1mm
print, ""
print, 'paral: ', paral
print, ""
print, 'phase_hwp', phase_hwp 

;; wind, 1, 1, /free, /large
;; my_multiplot, 1, 5, pp, pp1, /rev
;; plot, polangle, psym=8, position=pp1[0,*], title='polangle '+strtrim(myday)
;; plot, phase_hwp, psym=8, position=pp1[1,*], /noerase, title='phase hwp'
;; plot, elevation, psym=8, position=pp1[2,*], /noerase, title='elevation'
;; plot, paral, psym=8, position=pp1[3,*], /noerase, title='paral'
;; plot, tau225, psym=8, position=pp1[4,*], /noerase, title='tau225'
   

;stop
;;wd, !d.window
if array eq 'A1' then begin 

   ext_title = 'A1 '+strjoin(myday+" ")
   check_polangle_plots_sub, index, fwhm_res, elevation, paral, polangle_a1, err_polangle_a1, $
                             day, myday, phase_hwp, source, nickname, fwhm_max, ext_title, $
                             i_a1_res, q_a1_res, u_a1_res, pol_deg, err_pol_deg, tau225, $
                             err_i_a1_res, err_q_a1_res, err_u_a1_res, phase_motor, $
                             pol_deg_quasar, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                             p1_est, sigma_p1_est_plus, sigma_p1_est_minus, beta_est, sigma_beta_est, $
                             p_est, psi_est, beta_est, $
                             coltable=coltable, png=png, ps=ps, plot_file=plot_file+"_A1"
     
   
;;    check_polangle_plots_sub, index, fwhm_res, elevation, paral, polangle_a1, err_polangle_a1, $
;;                              day, myday, phase_hwp, source, nickname, fwhm_max, ext_title, $
;;                              i_a1_res, q_a1_res/p_est, u_a1_res/p_est, pol_deg, err_pol_deg, tau225, $
;;                              err_i_a1_res, err_q_a1_res/p_est, err_u_a1_res/p_est, phase_motor, $
;;                              pol_deg_quasar, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
;;                              p1_est, sigma_p1_est_plus, sigma_p1_est_minus, beta_est, sigma_beta_est, $
;;                              p_est, psi_est, beta_est, $
;;                              coltable=coltable, png=png, ps=ps, plot_file=plot_file+"_A1"

;; stop
;; wind, 1, 1, /f
;; plot, i_a3_res, title='i'
;; wind, 1, 1, /f
;; plot, q_a3_res, title='q'
;; stop

endif else begin
   if array eq 'A3' then begin  

      ext_title = 'A3 '+strjoin(myday+" ")
      check_polangle_plots_sub, index, fwhm_res, elevation, paral, polangle_a3, err_polangle_a3, $
                                day, myday, phase_hwp, source, nickname, fwhm_max, ext_title, $
                                i_a3_res, q_a3_res, u_a3_res, pol_deg, err_pol_deg, tau225, $
                                err_i_a3_res, err_q_a3_res, err_u_a3_res, phase_motor, $
                                pol_deg_quasar, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                                p1_est, sigma_p1_est_plus, sigma_p1_est_minus, beta_est, sigma_beta_est, $
                                coltable=coltable, png=png, ps=ps, plot_file=plot_file+"_A3"
   endif else begin
      if array eq 'A1+A3' then begin 
   
         ext_title = 'A1&A3 '+strjoin(myday+" ")
         check_polangle_plots_sub, index, fwhm_res, elevation, paral, polangle_1mm, err_polangle_1mm, $
                                   day, myday, phase_hwp, source, nickname, fwhm_max, ext_title, $
                                   i_1mm_res, q_1mm_res, u_1mm_res, pol_deg, err_pol_deg, tau225, $
                                   err_i_1mm_res, err_q_1mm_res, err_u_1mm_res, phase_motor, $
                                   pol_deg_quasar, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                                   p1_est, sigma_p1_est_plus, sigma_p1_est_minus, beta_est, sigma_beta_est, $
                                   coltable=coltable, png=png, ps=ps, plot_file=plot_file+"_1MM"
      endif
   endelse
endelse




end
