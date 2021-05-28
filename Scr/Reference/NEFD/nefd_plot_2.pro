
pro nefd_plot_2, project_dir, png=png, ps=ps

;restore, project_dir+"/nefd_plot_2_input.save"
restore, project_dir+"/nefd_sigma_res.save", /v
restore, project_dir+"/nefd_jk_center_res.save", /v
stop

nscans = n_elements( time_center_cumul[*,0])

parinfo = replicate({value:0.d0, fixed:0, limited:[0,0], $
                     limits:[0.d0, 0.d0]}, 3)

quiet = 1
fit_res    = dblarr(2, 4, 3) ; fixed_slope, 3 arrays + 1mm comb., fit parameters
perror_res = dblarr(2, 4, 3)
nrejected_points = dblarr(4)
chi2             = dblarr(2,4)
for iarray=1, 3 do begin
   sigma = dblarr(nscans)
   for i=0, nscans-1 do sigma[i] = stddev( sigma_res[iarray-1,i,*])
   ;; w = where( sigma ne 0, nw)
   w = where( sigma/sigma[0] ge 1e-3, nw, compl=wout, ncompl=nwout)
   nrejected_points[iarray-1] = nwout

   pguess = [0.d0, nefd_jk_center_res[iarray-1], -0.5]
   parinfo = replicate({value:0.d0, fixed:0, limited:[0,0], $
                        limits:[0.d0, 0.d0]}, 3)

   ;; Force slope to -0.5
   parinfo[2].fixed = 1
   parinfo.value = pguess
   start_params = parinfo.value
   fit = mpfitfun( "power_law", time_center_cumul[w,3*(iarray-1)], sigma_flux_center_cumul[w,3*(iarray-1)], $
                   sigma[w], pguess, STATUS=status, covar=covar, perror=perror, yfit=yfit, $
                   parinfo=parinfo, start_params=start_params, quiet=quiet)
   fit_res[    1,iarray-1,*] = fit
   perror_res[ 1,iarray-1,*] = perror
   chi2[1,iarray-1] = total( (sigma_flux_center_cumul[w,3*(iarray-1)]-$
                              power_law(time_center_cumul[w,3*(iarray-1)],fit))^2/sigma[w]^2)/(nw-3)

;;    message, /info, "fix me: discard outlyers"
;;    w = where( sigma gt 1d-15, nw)
;;    stop

;; Free power law
   parinfo[2].fixed = 0
   fit = mpfitfun( "power_law", time_center_cumul[w,3*(iarray-1)], sigma_flux_center_cumul[w,3*(iarray-1)], $
                   sigma[w], pguess, STATUS=status, covar=covar, perror=perror, yfit=yfit, $
                   parinfo=parinfo, start_params=start_params, quiet=quiet)
   fit_res[    0,iarray-1,*] = fit
   perror_res[ 0,iarray-1,*] = perror
   chi2[0,iarray-1] = total( (sigma_flux_center_cumul[w,3*(iarray-1)]-$
                              power_law(time_center_cumul[w,3*(iarray-1)],fit))^2/sigma[w]^2)/(nw-3)
endfor

;; Combined 1mm
sigma = dblarr(nscans)
for i=0, nscans-1 do sigma[i] = stddev( sigma_res[3,i,*])
;w = where( sigma ne 0, nw)
w = where( sigma/sigma[0] ge 1e-3, nw, compl=wout, ncompl=nwout)
nrejected_points[3] = nwout
pguess = [0.d0, nefd_jk_center_res[0]/sqrt(2), -0.5]
parinfo = replicate({value:0.d0, fixed:0, limited:[0,0], $
                     limits:[0.d0, 0.d0]}, 3)
parinfo.value = pguess
start_params = parinfo.value
parinfo[2].fixed = 0
fit = mpfitfun( "power_law", time_center_cumul[w,9], sigma_flux_center_cumul[w,9], $
                sigma[w], pguess, STATUS=status, covar=covar, perror=perror, yfit=yfit, $
                parinfo=parinfo, start_params=start_params, quiet=quiet)
fit_res[0,3,*] = fit
perror_res[0,3,*] = perror
chi2[0,3] = total( (sigma_flux_center_cumul[w,9]-$
                    power_law(time_center_cumul[w,9],fit))^2/sigma[w]^2)/(nw-3)

parinfo[2].fixed = 1
fit = mpfitfun( "power_law", time_center_cumul[w,9], sigma_flux_center_cumul[w,9], $
                sigma[w], pguess, STATUS=status, covar=covar, perror=perror, yfit=yfit, $
                parinfo=parinfo, start_params=start_params, quiet=quiet)
fit_res[1,3,*] = fit
perror_res[1,3,*] = perror
chi2[1,3] = total( (sigma_flux_center_cumul[w,9]-$
                    power_law(time_center_cumul[w,9],fit))^2/sigma[w]^2)/(nw-3)

;; Plots
if not keyword_set(ps) then wind, 1, 1, /free, /large
outplot, file=project_dir+"/nefd_mpfit_"+param.name4file, png=png, ps=ps
my_multiplot, 2, 4, pp, pp1, /rev, gap_x=0.07, gap_y=0.01, xmargin=0.07, ymargin=0.05
array_list = ['1', '2', '3', '1&3']

for iarray=1, 4 do begin
   sigma = dblarr(nscans)
   for i=0, nscans-1 do sigma[i] = stddev( sigma_res[iarray-1,i,*])
   xra = minmax(time_center_cumul[*,3*(iarray-1)])*[0.5,1]
   if iarray eq 4 then xtitle='Time (sec)' else delvarx, xtitle

   !y.charsize = 0.6
   if iarray le 3 then !x.charsize = 1e-10 else !x.charsize = 0.6

   ;;-------------
   col_fixed_slope = 250
   fixed_slope = 1
   fit_fixed_slope    = reform(fit_res[   fixed_slope,iarray-1,*])
   perror = reform(perror_res[fixed_slope,iarray-1,*])
   power_law_fixed_slope = power_law( time_center_cumul[*,3*(iarray-1)], fit_fixed_slope)
   yy = sigma_flux_center_cumul[*,3*(iarray-1)] - power_law_fixed_slope

   ;;-------------
   col_free_slope = 70
   fixed_slope = 0
   fit_free_slope    = reform(fit_res[fixed_slope,iarray-1,*])
   perror = reform(perror_res[fixed_slope,iarray-1,*])
   power_law_free_slope = power_law( time_center_cumul[*,3*(iarray-1)], fit_free_slope)
   
   plot, time_center_cumul[*,3*(iarray-1)], yy, psym=1, /xlog, $
         xra=xra, /xs, xtitle=xtitle, yra=[-1,1]*max(abs([yy-sigma,yy+sigma])), /ys, $
         position=pp[1,iarray-1,*], /noerase, /nodata
   oploterror, time_center_cumul[*,3*(iarray-1)], yy, sigma, psym=8, syms=0.5
   oplot, xra, xra*0., col=col_fixed_slope
   oplot, time_center_cumul[*,3*(iarray-1)], power_law_free_slope-power_law_fixed_slope, col=col_free_slope
   legendastro, 'Residuals', /right
   legendastro, 'A'+strtrim(iarray,2)

   if iarray eq 1 then title='At!u!7b!3!n + !7g!3' else delvarx, title
   yra = minmax(sigma_flux_center_cumul[*,3*(iarray-1)])*[0.5,2]
   plot, time_center_cumul[*,3*(iarray-1)], sigma_flux_center_cumul[*,3*(iarray-1)], psym=1, /xlog, /ylog, $
         xra=xra, /xs, xtitle=xtitle, ytitle='Err. on flux (Jy)', $
         position=pp[0,iarray-1,*], /noerase, yra=yra, /ys, title=title
   oploterror, time_center_cumul[*,3*(iarray-1)], sigma_flux_center_cumul[*,3*(iarray-1)], sigma, psym=1
   oplot, time_center_cumul[*,3*(iarray-1)], power_law_fixed_slope, col=col_fixed_slope
   oplot, time_center_cumul[*,3*(iarray-1)], power_law_free_slope,  col=col_free_slope
   legendastro, ['!7b!3 : '+strtrim(string(fit_fixed_slope[2],form='(f6.3)'),2), $
                 'A: '+strtrim(string(fit_fixed_slope[1],form='(f6.3)'),2), $
                 '!7g!3: '+strtrim(string(fit_fixed_slope[0],form='(f6.3)'),2), $
                 '!7v!3!U2!N: '+strtrim(string(chi2[fixed_slope,iarray-1],form='(F6.3)'),2)], textcol=col_fit_fixed_slope, /bottom

   legendastro, ['!7b!3 : '+strtrim(string(fit_free_slope[2],form='(f6.3)'),2), $
                 'A: '+strtrim(string(fit_free_slope[1],form='(f6.3)'),2), $
                 '!7g!3: '+strtrim(string(fit_free_slope[0],form='(f6.3)'),2), $
                 '!7v!3!U2!N: '+strtrim(string(chi2[fixed_slope,iarray-1],form='(F6.2)'),2)], textcol=col_fit_free_slope, /right
   legendastro, 'A'+strtrim(array_list[iarray-1],2)


endfor
outplot, /close, /verb


;; All on the same plot
wind, 1, 1, /free, /large
outplot, file='HLS_fit', png=png, ps=ps
col_array = [100, 250, 200, 70]
yra = [1e-4, 1e-2]
!p.multi=0
my_multiplot, /reset
line_fixed_slope = 0
line_free_slope = 2
col_fixed_slope = 0
col_free_slope  = 0
for iarray=1, 4 do begin
   sigma = dblarr(nscans)
   for i=0, nscans-1 do sigma[i] = stddev( sigma_res[iarray-1,i,*])
   xra = minmax(time_center_cumul[*,3*(iarray-1)])*[0.5,1.5]

   ;;-------------
   fixed_slope = 1
   fit_fixed_slope    = reform(fit_res[   fixed_slope,iarray-1,*])
   perror = reform(perror_res[fixed_slope,iarray-1,*])
   power_law_fixed_slope = power_law( time_center_cumul[*,3*(iarray-1)], fit_fixed_slope)
   yy = sigma_flux_center_cumul[*,3*(iarray-1)] - power_law_fixed_slope

   ;;-------------
   fixed_slope = 0
   fit_free_slope    = reform(fit_res[fixed_slope,iarray-1,*])
   perror = reform(perror_res[fixed_slope,iarray-1,*])
   power_law_free_slope = power_law( time_center_cumul[*,3*(iarray-1)], fit_free_slope)

;;    if iarray eq 1 then begin
;;       plot, time_center_cumul[*,3*(iarray-1)], yy, psym=1, /xlog, $
;;             xra=xra, /xs, xtitle=xtitle, yra=[-1,1]*max(abs([yy-sigma,yy+sigma])), /ys, $
;;             position=pp[1,iarray-1,*], /noerase, /nodata
;;    endif
;;    oploterror, time_center_cumul[*,3*(iarray-1)], yy, sigma, psym=8, syms=0.5, col=col_array[iarray], errcol=col_array[iarray]
;;    oplot, xra, xra*0., col=col_fixed_slope
;;    oplot, time_center_cumul[*,3*(iarray-1)], power_law_free_slope-power_law_fixed_slope, col=col_free_slope
;;    legendastro, 'Residuals', /right
;;    legendastro, 'A'+strtrim(iarray,2)

   if iarray eq 1 then begin
      plot, time_center_cumul[*,3*(iarray-1)], sigma_flux_center_cumul[*,3*(iarray-1)], psym=1, /xlog, /ylog, $
            xra=xra, /xs, xtitle='Integration time (sec)', ytitle='Sensitivity (Jy)', $
            yra=yra, /ys, title=title, /nodata
   endif
   oploterror, time_center_cumul[*,3*(iarray-1)], sigma_flux_center_cumul[*,3*(iarray-1)], $
               sigma, psym=8, syms=0.5, col=col_array[iarray-1], errcol=col_array[iarray-1]
   oplot, time_center_cumul[*,3*(iarray-1)], power_law_fixed_slope, col=col_fixed_slope, line=line_fixed_slope
   oplot, time_center_cumul[*,3*(iarray-1)], power_law_free_slope,  col=col_free_slope, line=line_free_slope
   legendastro, ['A1', 'A2', 'A3', 'A1&A3'], $
                col=col_array, psym=[8,8,8,8], thick=[1,1,1,1], /right
   legendastro, ['Fixed slope t!u-1/2!n', 'Free slope t!u!7b!3!n'], $
                col=[col_fixed_slope,col_free_slope], line=[line_fixed_slope,line_free_slope], /bottom

endfor
outplot, /close, /verb

;; All on the same plot
wind, 1, 1, /free, /large
outplot, file='HLS_residuals', png=png, ps=ps
col_array = [100, 250, 200, 70]
yra = [1e-4, 1e-2]
!p.multi=0
my_multiplot, /reset
line_fixed_slope = 0
line_free_slope = 2
col_fixed_slope = 0
col_free_slope  = 0
ytitle = 'Jy'
my_multiplot, 1, 4, pp, pp1, /rev, /dry, xmin=0.05, gap_y=0.02, ymin=0.02, ymax=0.95
for iarray=1, 4 do begin
   sigma = dblarr(nscans)
   for i=0, nscans-1 do sigma[i] = stddev( sigma_res[iarray-1,i,*])
   xra = minmax(time_center_cumul[*,3*(iarray-1)])*[0.5,1.5]

   if iarray lt 4 then !x.charsize=1d-10 else !x.charsize=1
   if iarray eq 1 then title='Residuals' else title=''
   
   ;;-------------
   fixed_slope = 1
   fit_fixed_slope    = reform(fit_res[   fixed_slope,iarray-1,*])
   perror = reform(perror_res[fixed_slope,iarray-1,*])
   power_law_fixed_slope = power_law( time_center_cumul[*,3*(iarray-1)], fit_fixed_slope)
   yy = sigma_flux_center_cumul[*,3*(iarray-1)] - power_law_fixed_slope

   ;;-------------
   fixed_slope = 0
   fit_free_slope    = reform(fit_res[fixed_slope,iarray-1,*])
   perror = reform(perror_res[fixed_slope,iarray-1,*])
   power_law_free_slope = power_law( time_center_cumul[*,3*(iarray-1)], fit_free_slope)

   plot, time_center_cumul[*,3*(iarray-1)], yy, psym=1, /xlog, $
         xra=xra, /xs, xtitle=xtitle, yra=[-1,1]*max(abs([yy-sigma,yy+sigma])), /ys, $
         position=pp[0,iarray-1,*], /noerase, /nodata, title=title, ytitle=ytitle
   oploterror, time_center_cumul[*,3*(iarray-1)], yy, sigma, psym=8, syms=0.5, $
               col=col_array[iarray-1], errcol=col_array[iarray-1]
   oplot, xra, xra*0., col=col_fixed_slope
   oplot, time_center_cumul[*,3*(iarray-1)], power_law_free_slope-power_law_fixed_slope, col=col_free_slope, line=line_free_slope
   if iarray lt 4 then begin
      legendastro, ['A'+strtrim(iarray-1,2)], psym=8, col=col_array[iarray-1], /right
   endif else begin
      legendastro, ['A1&A3'], textcol=col_array[iarray-1], psym=8, col=col_array[iarray-1], /right
   endelse
   legendastro, ['Fixed slope t!u-1/2!n', 'Free slope t!u!7b!3!n'], $
                col=[col_fixed_slope,col_free_slope], line=[line_fixed_slope,line_free_slope], /bottom
endfor
outplot, /close, /verb



for i=0, 3 do begin
   message, /info, "I found "+strtrim(nrejected_points[i],2)+" points for which sigma/sigma[0] was "+$
            "less than 1e-3 and did not use them in the fits"
endfor

print, "nefd_jk_center_res: ", nefd_jk_center_res
form="(F5.1)"
for i=1, 4 do begin
   print, "A"+strtrim(i,2)+" & "+string(fit_res[0,i-1,1]*1000,form=form)+" mJy.s$^{"+string(fit_res[0,i-1,2],form="(F5.2)")+"}$ & "+$
          string(fit_res[1,i-1,1]*1000,form=form)+" mJy.s$^{"+string(fit_res[1,i-1,2],form=form)+"}$ & "+$
          string(nefd_jk_center_res[i-1],form=form)+" mJy.$s^{1/2}$ & TBD\\"
endfor

if !db.lvl ne 0 then stop
end
