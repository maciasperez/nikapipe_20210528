
pro check_polangle_plots, dir, scan_list_in, fwhm_max, source, myday_list_iday, $
                          pol_deg_quasar, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                          p1_est, sigma_p1_est_plus, sigma_p1_est_minus, beta_est, sigma_beta_est, $
                          p_est, psi_est,$
                          nickname=nickname, $
                          ps=ps, png=png, plot_dir=plot_dir, $
                          plot_file=plot_file, coltable=coltable, array=array, norm=norm
  
if not keyword_set(plot_dir) then plot_dir = "."
if not keyword_set(nickname) then begin
   nickname = file_basename( dir)
endif

np_warning, /reset

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
nscans    = n_elements(scan_list)

;; Gather all results in info_all
p     = 0
iscan = 0
while (p eq 0) and (iscan lt nscans) do begin
   file = dir+"/v_1/"+scan_list[iscan]+"/info.csv"
   if file_test(file) then begin
      nk_read_csv_2, file, info
      info_all = info
      p=1
   endif
   iscan++
endwhile
info_all = replicate( info_all, nscans)
keep = intarr(nscans)

for iscan=0, nscans-1 do begin
   file = dir+"/v_1/"+scan_list[iscan]+"/info.csv"
   if file_test(file) then begin
      nk_read_csv_2, file, info
      keep[iscan] = 1
      info_all[iscan] = info
   endif
endfor
wk = where( keep eq 1)
info_all = info_all[ wk]
scan_list = scan_list[wk]

np_warning, text="Cutting fwhm > 12", /add
w = where( info_all.result_fwhm_1 lt 12 and info_all.result_fwhm_3 lt 12)
info_all = info_all[w]
scan_list = scan_list[w]

opacorr = exp(info_all.result_tau_1mm/sin(info_all.result_elevation_deg*!dtor))
;plot, opacorr
w = where( opacorr lt 1.7)
scan_list = scan_list[w]
info_all = info_all[w]
message, /info, "fix me: restricting to opacorr < 1.7"
stop

nscans = n_elements(scan_list)

day_list = long(info_all.day)
day_list = day_list[UNIQ(day_list, SORT(day_list))]
ndays = n_elements(day_list)
make_ct, ndays+1, ct

;; Define quantities to monitor
array_suffix = ['1', '3', '_1mm']
array_fields  = ['fwhm', 'pol_deg', $
                 'flux_i', 'flux_q', 'flux_u']
common_fields = ['elevation_deg', 'paral', $ ;, 'phase_hwp', $
                 'tau_1mm']

nsuff = n_elements(array_suffix)
ncommon_fields = n_elements(common_fields)
if not keyword_set(plot_dir) then plot_dir = '.'
syms = 0.5
array_col = [70, 100, 200]
info_tags = tag_names(info_all)
charsize = 0.6
xsep = 0.4
xra = [-floor(0.4*nscans), nscans]
narray_fields  = n_elements(array_fields)
if not keyword_set(ps) then wind, 1, 1, /free, /large
outplot, file=plot_dir+"/cpr_"+source+"_1", png=png, ps=ps
nplots = narray_fields + ncommon_fields
my_multiplot, 1, nplots, pp, pp1, /rev, gap_y=0.02, xmax=xsep, xmargin=0.02, xmin=0.05
for ifield=0, narray_fields-1 do begin
   if ifield eq (narray_fields-1) then xcharsize=charsize else xcharsize = 1d-10
   if ifield eq 0 then title=source else title=''
   array_leg_txt = strarr(nsuff)
   for isuff=0, nsuff-1 do begin
      tag = "result_"+array_fields[ifield]+array_suffix[isuff]
      wtag = where( strupcase(info_tags) eq strupcase(tag), nwtag)
      if nwtag eq 0 then begin
         tag = "result_"+array_fields[ifield]+"_"+array_suffix[isuff]
         wtag = where( strupcase(info_tags) eq strupcase(tag), nwtag)
         if nwtag eq 0 then begin
            message, /info, "Wront tag (twice): "+tag
            stop
         endif
      endif

      if strupcase(array_fields[ifield]) eq "POL_ANGLE" or $
         strupcase(array_fields[ifield]) eq "POL_ANGLE_CENTER" then begin
         avg_ang = avg( info_all.(wtag))
         junk = info_all.(wtag)
         w = where( (info_all.(wtag)-avg_ang) gt 40, nw)
         if nw ne 0 then junk[w] -= 180
         w = where( (info_all.(wtag)-avg_ang) lt -40, nw)
         if nw ne 0 then junk[w] += 180
         info_all.(wtag) = junk
      endif
      
      tag_avg = avg(    info_all.(wtag))
      tag_std = stddev( info_all.(wtag))
      if isuff eq 0 then plot, info_all.(wtag), psym=-8, syms=syms, /xs, xra=xra, $
                               yra=tag_avg + [-5,5]*tag_std, /ys, position=pp[0,ifield,*], /noerase, $
                               xcharsize=xcharsize, ycharsize=ycharsize, $
                               title=title
      oplot, info_all.(wtag), psym=-8, syms=syms, col=array_col[isuff]
      array_leg_txt[isuff] = 'A'+array_suffix[isuff]+": "+strtrim(tag_avg,2)+" +- "+strtrim(tag_std,2)
   endfor
   legendastro, [array_fields[ifield], array_leg_txt], $
                textcol=[!p.color, array_col], charsize=charsize
   
   if strupcase(array_fields[ifield]) eq "FLUX_I" then begin
      opacorr = exp(info_all.result_tau_1mm/sin(info_all.result_elevation_deg*!dtor))
      plot, opacorr, xra=xra, /xs, yra=[0,2], /ys, $
            position=pp[0,ifield,*], col=250, /noerase, $
            charsize=1d-10
      axis, /yaxis, col=250
      legendastro, 'e!u(tau/sin(el))!n', /right, textcol=250, /bottom
   endif
endfor

for ifield=0, ncommon_fields-1 do begin
   if ifield eq (ncommon_fields-1) then xcharsize=charsize else xcharsize = 1d-10
   tag = "result_"+common_fields[ifield]
   wtag = where( strupcase(info_tags) eq strupcase(tag), nwtag)
   if nwtag eq 0 then begin
      wtag = where( strupcase(info_tags) eq strupcase(common_fields[ifield]), nwtag)
      if nwtag eq 0 then begin
         message, /info, "Wront tag (twice): "+tag
         stop
      endif
   endif
   tag_avg = avg(    info_all.(wtag))
   tag_std = stddev( info_all.(wtag))
   print, nplots-ncommon_fields-ifield
   if common_fields[ifield] eq 'tau_1mm' then yra=[0,1] else yra=minmax(info_all.(wtag))
   plot, info_all.(wtag), psym=-8, syms=syms, /xs, xra=xra, $
         yra=yra, /ys, position=pp[0,nplots-ncommon_fields+ifield,*], /noerase, $
         xcharsize=xcharsize, ycharsize=ycharsize
   leg_txt = common_fields[ifield]
   leg_col = !p.color

   for iday=0, ndays-1 do begin
      w = where( long(info_all.day) eq day_list[iday], nw)
      oplot, w, info_all[w].(wtag), psym=8, syms=syms, col=ct[iday]
   endfor
   
   if common_fields[ifield] eq 'tau_1mm' then begin
      wtag = where( strupcase(info_tags) eq "TAU225", nwtag)
      if nwtag eq 0 then begin
         message, /info, "No tau225 available for this scan"
         stop
      endif
      oplot, info_all.(wtag), col=250, psym=-8, syms=syms
      leg_txt = [leg_txt, 'Tau 225']
      leg_col = [!p.color, 250]
   endif
   legendastro, leg_txt, textcol=leg_col
   
endfor


;;============================================================================================================
;; Closer look at angles variations
array_suffix = ['1', '3', '_1mm']
array_fields  = ['pol_angle']
common_fields = ['elevation_deg', 'paral']

nsuff = n_elements(array_suffix)
ncommon_fields = n_elements(common_fields)
if not keyword_set(plot_dir) then plot_dir = '.'
syms = 0.5
array_col = [70, 100, 200]
info_tags = tag_names(info_all)
charsize = 0.6
xsep = 0.4
xra = [-floor(0.4*nscans), nscans]
narray_fields  = n_elements(array_fields)
outplot, file=plot_dir+"/cpr_"+source+"_1", png=png, ps=ps
nplots = narray_fields + ncommon_fields
my_multiplot, 1, nplots, pp, pp1, /rev, gap_y=0.02, xmin=xsep+0.05, $
              xmargin=0.02, xmax=0.7, ymin=0.5, ymax=0.95, ymargin=1d-3
for ifield=0, narray_fields-1 do begin
   if ifield eq (narray_fields-1) then xcharsize=charsize else xcharsize = 1d-10
   if ifield eq 0 then title=source else title=''
   array_leg_txt = strarr(nsuff)
   for isuff=0, nsuff-1 do begin
      tag = "result_"+array_fields[ifield]+array_suffix[isuff]
      wtag = where( strupcase(info_tags) eq strupcase(tag), nwtag)
      if nwtag eq 0 then begin
         tag = "result_"+array_fields[ifield]+"_"+array_suffix[isuff]
         wtag = where( strupcase(info_tags) eq strupcase(tag), nwtag)
         if nwtag eq 0 then begin
            message, /info, "Wront tag (twice): "+tag
            stop
         endif
      endif

      if strupcase(array_fields[ifield]) eq "POL_ANGLE" or $
         strupcase(array_fields[ifield]) eq "POL_ANGLE_CENTER" then begin
         avg_ang = avg( info_all.(wtag))
         junk = info_all.(wtag)
         w = where( (info_all.(wtag)-avg_ang) gt 40, nw)
         if nw ne 0 then junk[w] -= 180
         w = where( (info_all.(wtag)-avg_ang) lt -40, nw)
         if nw ne 0 then junk[w] += 180
         info_all.(wtag) = junk
      endif
      
      tag_avg = avg(    info_all.(wtag))
      tag_std = stddev( info_all.(wtag))
      if isuff eq 0 then plot, info_all.(wtag), psym=-8, syms=syms, /xs, xra=xra, $
                               yra=tag_avg + [-5,5]*tag_std, /ys, position=pp[0,ifield,*], /noerase, $
                               xcharsize=xcharsize, ycharsize=ycharsize, $
                               title=title
      oplot, info_all.(wtag), psym=-8, syms=syms, col=array_col[isuff]
      array_leg_txt[isuff] = 'A'+array_suffix[isuff]+": "+strtrim(tag_avg,2)+" +- "+strtrim(tag_std,2)
   endfor
   legendastro, [array_fields[ifield], array_leg_txt], $
                textcol=[!p.color, array_col], charsize=charsize
endfor

for ifield=0, ncommon_fields-1 do begin
   if ifield eq (ncommon_fields-1) then xcharsize=charsize else xcharsize = 1d-10
   tag = "result_"+common_fields[ifield]
   wtag = where( strupcase(info_tags) eq strupcase(tag), nwtag)
   if nwtag eq 0 then begin
      wtag = where( strupcase(info_tags) eq strupcase(common_fields[ifield]), nwtag)
      if nwtag eq 0 then begin
         message, /info, "Wront tag (twice): "+tag
         stop
      endif
   endif
   tag_avg = avg(    info_all.(wtag))
   tag_std = stddev( info_all.(wtag))
   print, nplots-ncommon_fields-ifield
   if common_fields[ifield] eq 'tau_1mm' then yra=[0,1] else yra=minmax(info_all.(wtag))
   plot, info_all.(wtag), psym=-8, syms=syms, /xs, xra=xra, $
         yra=yra, /ys, position=pp[0,nplots-ncommon_fields+ifield,*], /noerase, $
         xcharsize=xcharsize, ycharsize=ycharsize
   leg_txt = common_fields[ifield]
   leg_col = !p.color
   legendastro, leg_txt, textcol=leg_col
   
endfor


plot, info_all.result_elevation_deg - info_all.paral, info_all.result_pol_deg_1mm, $
      psym=8, syms=syms, /xs, /ys, position=[0.7+0.05, 0.5, 0.95, 0.95], $
      /noerase, ytitle='Pol. Deg', xtitle='elev-paral'
legendastro, 'pol. deg'


;; Fitting the angle and the leakage term in Q and U space

chars=0.7
info_all_copy = info_all
wind, 1, 1, /free, /large
my_multiplot, ndays, 2, aa, aa1, /rev, gap_x=0.05, xmax=0.7, xmin=0.02
my_multiplot, 1, 2, pp_all, pp1_all, /rev, xmargin=0.01, xmin=0.72, xmax=0.97
pp = dblarr(ndays+1,2,4)
pp[0:ndays-1,*,*] = aa
pp[ndays,*,*] = pp_all

;; for iday=0, ndays-1 do begin
for iday=0, ndays do begin
   info_all = info_all_copy
   if iday le (ndays-1) then begin
      w = where( long(info_all.day) eq day_list[iday], nscans)
      info_all = info_all[w]
   endif

   phi_deg     = info_all.result_elevation_deg - info_all.paral
   phi_rad     = phi_deg*!dtor
   phi_fit_deg = (dindgen(720)-360)

;; Build the A^TN^-1A matrix and fit:
;; Q_nas_measured =  cos2phi*Q_eff + sin2phi*U_eff + Q_eff_lkg
;; U_nas_measured = -sin2phi*Q_eff + cos2phi*U_eff + U_eff_lkg
;; where
;; Q_eff =  Q_sky*cos4w0 + U_sky*sin4w0
;; U_eff = -Q_sky*sin4w0 + U_sky*cos4w0

   d   = dblarr(2*nscans)
   a   = dblarr(4,2*nscans)
   atd = dblarr(4)
   nm1 = dblarr(2*nscans,2*nscans)

   wi     = where( strupcase(info_tags) eq "RESULT_FLUX_I_1MM")
   wq     = where( strupcase(info_tags) eq "RESULT_FLUX_Q_1MM")
   wq_err = where( strupcase(info_tags) eq "RESULT_ERR_FLUX_Q_1MM")
   wu     = where( strupcase(info_tags) eq "RESULT_FLUX_U_1MM")
   wu_err = where( strupcase(info_tags) eq "RESULT_ERR_FLUX_U_1MM")

   for i=0, nscans-1 do begin
      d[2*i]   = info_all[i].(wq)/info_all[i].(wi)
      d[2*i+1] = info_all[i].(wu)/info_all[i].(wi)

      a[0,2*i]   =  cos(2*phi_rad[i])
      a[1,2*i]   = -sin(2*phi_rad[i])
      a[2,2*i]   =  1.d0
      a[3,2*i]   = 0.d0
      
      a[0,2*i+1] =  sin(2*phi_rad[i])
      a[1,2*i+1] =  cos(2*phi_rad[i])
      a[2,2*i+1] = 0.d0
      a[3,2*i+1] =  1.d0

      nm1[2*i,2*i]     = 1.d0/(info_all[i].(wq_err)/info_all[i].(wi))^2
      nm1[2*i+1,2*i+1] = 1.d0/(info_all[i].(wu_err)/info_all[i].(wi))^2
   endfor

   atam1 = invert(transpose(a)##nm1##a)
   atd   = transpose(a)##nm1##d
   s     = atam1##atd

;; derive fitting curves with the regress model
   phi_fit = phi_fit_deg*!dtor
   qfit = s[0]*cos(2*phi_fit) - s[1]*sin(2*phi_fit) + s[2]
   ufit = s[0]*sin(2*phi_fit) + s[1]*cos(2*phi_fit) + s[3]

;; Object estimated polarization degree from the fit
   p_est   = sqrt( s[0]^2 + s[1]^2)
   psi_est = 0.5*atan( s[1], s[0])
   fmt= '(F7.2)'
   leg_txt = ['p_est(fit): '+strtrim(string(p_est,form=fmt),2), $
              'psi_est(fit) (deg): '+strtrim(string(psi_est*!radeg,form=fmt),2)]

;; Approx uncertainties, assuming high SNR and alternative estimates
;; of pol. deg. and angle
   sigma_i = 0.d0
   q       = s[0]
   u       = s[1]
   sigma_q = sqrt( atam1[0,0])
   sigma_u = sqrt( atam1[1,1])
   iqu2poldeg, 1.d0, q, u, $
               sigma_i, sigma_q, sigma_u, pol_deg_quasar, sigma_p_plus, sigma_p_minus
   alpha_deg = 0.5*atan( u, q)*!radeg
   sigma_alpha_deg = 0.5d0/(q^2+u^2)*sqrt( q^2*sigma_u^2 + u^2*sigma_q^2)*!radeg
   leg_txt = [leg_txt, $
              'p: '+strtrim(string(pol_deg_quasar,form=fmt),2)+" +- ["+$
              strtrim( string(sigma_p_minus,form=fmt),2)+", "+$
              strtrim( string(sigma_p_plus,form=fmt),2)+"]", $
              'alpha(deg): '+strtrim(string(alpha_deg,form=fmt),2)+" +- "+$
              strtrim(string(sigma_alpha_deg,form=fmt),2)]

;; Leakage estimated polarization degree from the fit
   p1_est = sqrt( s[2]^2 + s[3]^2)
   beta_est = 0.5*atan( s[3], s[2])
   leg_txt = [leg_txt, $
              'p_lkg (fit): '+strtrim( string(p1_est,form=fmt),2), $
              'beta_lkg (fit) (deg): '+strtrim( string(beta_est*!radeg,form=fmt),2)]


   xra = minmax(phi_deg)+[-10,10]
;   my_multiplot, 1, 2, pp, pp1, /rev, gap_y=0.02, xmin=xsep+0.05, $
;                 xmargin=0.02, xmax=0.95, ymin=0.02, ymax=0.4, ymargin=1d-3

   ploterror, phi_deg, info_all.(wq)/info_all.(wi), info_all.(wq_err)/info_all.(wi), psym=8, syms=syms, $
              position=pp[iday,0,*], /noerase, xra=xra, /xs, chars=chars, $
              xtitle='elev-paral', col=ct[iday], errcol=ct[iday]
   if iday eq ndays then begin
      for ii=0, ndays-1 do begin
         w = where( long(info_all.day) eq day_list[ii], nw)
         oploterror, phi_deg[w], info_all[w].(wq)/info_all[w].(wi), $
                     info_all[w].(wq_err)/info_all[w].(wi), psym=8, sym=syms, col=ct[ii], errcol=ct[ii]
      endfor
   endif
   oplot, phi_fit_deg, qfit, col=0
   legendastro, leg_txt
   legendastro, 'Q/I', psym=8, col=250, textcol=250, /right, charsize=charsize

   ploterror, phi_deg, info_all.(wu)/info_all.(wi), info_all.(wu_err)/info_all.(wi), psym=8, syms=syms, $
              position=pp[iday,1,*], /noerase, xra=xra, /xs, chars=chars, $
              xtitle='elev-paral', col=ct[iday], errcol=ct[iday]
   if iday eq ndays then begin
      for ii=0, ndays-1 do begin
         w = where( long(info_all.day) eq day_list[ii], nw)
         oploterror, phi_deg[w], info_all[w].(wu)/info_all[w].(wi), $
                     info_all[w].(wu_err)/info_all[w].(wi), psym=8, sym=syms, col=ct[ii], errcol=ct[ii]
      endfor
   endif
   oplot, phi_fit_deg, ufit, col=0
   legendastro, leg_txt
   legendastro, 'U/I', psym=8, col=250, textcol=250, /right, charsize=charsize
endfor

outplot, /close, /verb

np_warning, /stars
stop

end
