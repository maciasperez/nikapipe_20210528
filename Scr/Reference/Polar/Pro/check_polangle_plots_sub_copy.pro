

pro check_polangle_plots_sub, index, fwhm_res, elevation, paral, polangle, err_polangle, $
                              day, myday, phase_hwp, source, nickname, fwhm_max, ext_title, $
                              i_res, q_res, u_res, pol_deg, err_pol_deg, tau225, $
                              err_i_res, err_q_res, err_u_res, phase_motor, $
                              pol_deg_quasar, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                              p1_est, sigma_p1_est_plus, sigma_p1_est_minus, beta_est_deg, sigma_beta_est, $
                              p_est, psi_est, beta_est, $
                              coltable=coltable, png=png, ps=ps, plot_file=plot_file, $
                              grid_angle=grid_angle, chi2=chi2
                              

ndays = n_elements(myday)
if keyword_set(coltable) then ct=coltable else make_ct, ndays, ct

wind, 2, 2, /free, /large
window2 = !d.window
wind, 1, 1, /free, /large
window1 = !d.window

;--------------------------------------------------------
;; Measure plots and variation fits

;; Forcing 1.d0*(elevation+paral) and fitting only a constant
leg_txt1 = 'Meas. Pol. Angle (deg)'
sym_list1 = 8
col_list1 = !p.color
phi = elevation+paral
myphase = long( phase_hwp)
myphase_uniq = myphase[UNIQ(myphase, SORT(myphase))]
nn = n_elements(myphase_uniq)
const_fit = dblarr(nn)
yfit1 = polangle*0.d0
const_fit = 1./total(1.d0/err_polangle^2)*total( (polangle-phi)/err_polangle^2)
yfit1 = phi + const_fit
leg_txt = strtrim( string(const_fit,form='(F7.2)'),2)+" +(elev+paral)"
leg_col = [0]
psym_list = [6]

;; Fitting against the variation
phi = elevation + paral
fit = linfit( phi-phi[0], polangle-polangle[0], measure_err=err_polangle)
yfit3 = polangle[0] + fit[0] + fit[1]*(phi-phi[0])
nangles = n_elements(phi)
chi2fit3 = total( (yfit3-polangle)^2/err_polangle^2)/(nangles-1)

;; ;; in the case of 'constant' radec angle
;; const_fit = 1./total(1.d0/err_polangle^2)*total( polangle/err_polangle^2)
;; chi2const = total( (polangle-const_fit)^2/err_polangle^2)/(nangles-1)
;; wind, 1, 1, /f
;; x = dindgen(100)/99*(max(phi)-min(phi)) + min(phi)
;; ploterror,  phi, polangle, err_polangle, psym=8
;; oplot, x, polangle[0] + fit[0] + fit[1]*x - fit[1]*phi[0], col=70
;; oplot, x, x*0 + const_fit, col=250
;; stop

leg_txt = [leg_txt, $
           strtrim( string( fit[0]+polangle[0], form='(F7.2)'),2)+" + "+$
           strtrim( string( fit[1], form='(F7.2)'),2)+" x !7D!3(elev+paral)"]
psym_list = [psym_list, 7]
leg_col = [leg_col, 70]

;; Accouting for the inclination of the grid (40, not 45 deg !)
if not keyword_set(grid_angle) then grid_angle = 40.d0
polangle_in = atan( cos(grid_angle*!dtor)*tan(polangle*!dtor))*!radeg
err_plus    = atan( cos(grid_angle*!dtor)*tan( (polangle+err_polangle)*!dtor))*!radeg
err_minus   = atan( cos(grid_angle*!dtor)*tan( (polangle-err_polangle)*!dtor))*!radeg
err_polangle_in = abs(err_plus-err_minus)/2.
wind, 1, 1, /free
!p.multi=[0,1,2]
plot, polangle, /xs, psym=-8, title='Input polangle'
plot, polangle_in, /xs, psym=-8, title='Polangle_in'
legendastro, 'see if you need to +- 180 somewhere'
!p.multi=0
message, /info, ""
print, "polangle_in: ", polangle_in
;stop
wd, !d.window
;; fit against (elev+paral) free slope, hoping to find 1.00 blindly...
phi = elevation+paral
yfit5 = polangle*0.d0
const_fit5 = 1./total(1.d0/err_polangle^2)*total( (polangle_in-phi)/err_polangle^2)
yfit5 = phi + const_fit5
leg_txt1 = [leg_txt1, 'Polang. in Th.']
sym_list1 = [sym_list1, 8]
col_list1 = [col_list1, 250]
leg_txt = [leg_txt, strtrim( string(const_fit5,form='(F7.2)'),2)+" +(elev+paral)"]
psym_list = [psym_list, 6]
leg_col = [leg_col, 250]

;;---------------
if not keyword_set(plot_file) then plot_file = 'polangle_summary_'+nickname
window_list = [window1, window2]
for iwind=0, 1 do begin
   mywindow = window_list[iwind]
   wset, mywindow
   delvarx, xtitle
   outplot, file=plot_file+'_'+strtrim(iwind,2), png=png, ps=ps
   if mywindow eq window1 then begin

      ;;------------------------------------------------
      ;; plot fwhm, elevation, phase, paral
      !p.charsize = 0.7
      xra = minmax(index)
      xra = xra + [-0.3,0.1]*(xra[1]-xra[0])

      ysep=0.2
      xcharsize = 1d-10
      my_multiplot, 1, 11, pp, pp1, /rev, gap_y=0.01;, ymax=0.95, ymin=ysep
      plot, index,  fwhm_res, /xs, psym=-8, syms=0.5, position=pp[0,0,*], $
            title=source+" "+nickname, /ys, xra=xra, xcharsize=xcharsize, yra=[10, 20]
      legendastro, ['fwhm_max: '+string(fwhm_max,form='(F4.1)')], /right
      legendastro, 'FWHM', /bottom
      yra = minmax(elevation)
      plot,      index, elevation, /xs, psym=-8, syms=0.5, position=pp[0,1,*], /noerase, xra=xra, xcharsize=xcharsize, yra=yra, /ys
      legendastro, 'Elevation (deg)', /bottom
      ndays = n_elements(myday)
      for iday=0, ndays-1 do begin
         w = where( day eq myday[iday],nw)
         if nw ne 0 then begin
            oplot, index[w], elevation[w], psym=8, syms=0.5, col=ct[iday]
         endif
      endfor

      yra = minmax(paral)
      plot,      index, paral, /xs, psym=-8, syms=0.5, position=pp[0,2,*], /noerase, $
                 yra=yra, /ys, xra=xra, xcharsize=xcharsize
      legendastro, 'Parallactic angle (deg)', /bottom
      for iday=0, ndays-1 do begin
         w = where( day eq myday[iday],nw)
         if nw ne 0 then begin
            oplot, index[w], paral[w], psym=8, syms=0.5, col=ct[iday]
         endif
      endfor

      plot, index, phase_hwp, /ys, position=pp[0,3,*], /noerase, $
            psym=-8, syms=0.5, /xs, xra=xra, xcharsize=xcharsize
      legendastro, 'Phase hwp (deg)', /bottom
      yra = minmax(phase_hwp)
      for iday=0, ndays-1 do begin
         w = where( day eq myday[iday],nw)
         if nw ne 0 then begin
            oplot, index[w], phase_hwp[w], psym=8, syms=0.5, col=ct[iday]
         endif
      endfor

      plot, index, phase_motor, /ys, position=pp[0,4,*], /noerase, $
            psym=-8, syms=0.5, /xs, xra=xra, xcharsize=xcharsize
      legendastro, 'Phase MOTOR (deg)', /bottom
      yra = minmax(phase_motor)
      for iday=0, ndays-1 do begin
         w = where( day eq myday[iday],nw)
         if nw ne 0 then begin
            oplot, index[w], phase_motor[w], psym=8, syms=0.5, col=ct[iday]
         endif
      endfor

      yra = minmax(i_res+err_i_res)
      plot,      index, i_res, /xs, psym=-8, syms=0.5, position=pp[0,5,*], /noerase, $
                 yra=yra, /ys, xra=xra, xcharsize=xcharsize
      legendastro, 'I flux', /bottom
      for iday=0, ndays-1 do begin
         w = where( day eq myday[iday],nw)
         if nw ne 0 then begin
            oploterror, index[w], i_res[w], err_i_res[w], psym=8, syms=0.5, col=ct[iday], errcol=ct[iday]
         endif
      endfor

      yra = minmax(q_res + err_q_res)
      plot,      index, q_res, /xs, psym=-8, syms=0.5, position=pp[0,6,*], /noerase, $
                 yra=yra, /ys, xra=xra, xcharsize=xcharsize
      legendastro, 'Q flux', /bottom
      for iday=0, ndays-1 do begin
         w = where( day eq myday[iday],nw)
         if nw ne 0 then begin
            oploterror, index[w], q_res[w], err_q_res[w], psym=8, syms=0.5, col=ct[iday], errcol=ct[iday]
         endif
      endfor

      yra = minmax(u_res+err_u_res)
      plot,      index, u_res, /xs, psym=-8, syms=0.5, position=pp[0,7,*], /noerase, $
                 yra=yra, /ys, xra=xra, xcharsize=xcharsize
      legendastro, 'U flux', /bottom
      for iday=0, ndays-1 do begin
         w = where( day eq myday[iday],nw)
         if nw ne 0 then begin
            oploterror, index[w], u_res[w], err_u_res[w], psym=8, syms=0.5, col=ct[iday], errcol=ct[iday]
         endif
      endfor

      yra = minmax( pol_deg + err_pol_deg)
      plot,      index, pol_deg, /xs, psym=-8, syms=0.5, position=pp[0,8,*], /noerase, $
                 yra=yra, /ys, xra=xra, xcharsize=xcharsize
      legendastro, 'Pol. deg', /bottom
      for iday=0, ndays-1 do begin
         w = where( day eq myday[iday],nw)
         if nw ne 0 then begin
            oploterror, index[w], pol_deg[w], err_pol_deg[w], psym=8, syms=0.5, col=ct[iday], errcol=ct[iday]
         endif
      endfor

      ipol = sqrt(q_res^2 + u_res^2)
      yra = minmax( ipol)
      plot,      index, ipol, /xs, psym=-8, syms=0.5, position=pp[0,9,*], /noerase, $
                 yra=yra, /ys, xra=xra, xcharsize=xcharsize
      legendastro, 'I Pol.', /bottom
      for iday=0, ndays-1 do begin
         w = where( day eq myday[iday],nw)
         if nw ne 0 then begin
            oploterror, index[w], ipol[w], psym=8, syms=0.5, col=ct[iday], errcol=ct[iday]
         endif
      endfor

      xcharsize = 0.7
      yra = minmax( tau225)
      plot,      index, tau225, /xs, psym=-8, syms=0.5, position=pp[0,10,*], /noerase, $
                 yra=yra, /ys, xra=xra, xcharsize=xcharsize
      legendastro, 'Tau225', /bottom
      for iday=0, ndays-1 do begin
         w = where( day eq myday[iday],nw)
         if nw ne 0 then begin
            oplot, index[w], tau225[w], psym=8, syms=0.5, col=ct[iday]
         endif
      endfor
      
;;      ;;------------ polangle ---------
;;      my_position = [pp1[7,0], 0.02, pp1[7,2], ysep-0.02]
;;      my_yra = yra
;;      my_syms = 0.5
      xcharsize=1
   endif else begin
      ysep1 = 0.2
      my_multiplot, 1, 1, pp, pp1, ymin=ysep1, ymax=0.95
      my_position = reform(pp1[0,*])
      ;;my_multiplot, 1, 2, pp, pp1, ymax=ysep1, /rev, gap_y=0.02
      my_multiplot, 1, 1, pp, pp1, ymax=ysep1, /rev, gap_y=0.02
      my_syms=1
      xcharsize=1

      ;; Residuals
      yra = [-1,1]*8
      plot, xra, xra*0, /xs, xra=xra, position=pp1[0,*], /noerase, $
            yra=yra, /ys, xcharsize=0.7
      res_leg_txt = 'Polangle-fit residuals'
      res_leg_col = !p.color
      fmt = '(F5.2)'
      if defined(yfit1) then begin
         oplot, index, polangle - yfit1, psym=6
         res_leg_txt = [res_leg_txt, '!7r!3 = '+string( stddev(polangle - yfit1), form=fmt)]
         res_leg_col = [res_leg_col, !p.color]
      endif
      if defined(yfit2) then begin
         oplot, index, polangle - yfit2, psym=4, col=70
         res_leg_txt = [res_leg_txt, '!7r!3 = '+string( stddev(polangle - yfit2), form=fmt)]
         res_leg_col = [res_leg_col, 70]
      endif
      if defined(yfit3) then begin
         oplot, index, polangle - yfit3, psym=7, col=70
         res_leg_txt = [res_leg_txt, '!7r!3 = '+string( stddev(polangle - yfit3), form=fmt)]
         res_leg_col = [res_leg_col, 70]
      endif
      if defined(yfit4) then begin
         oplot, index, polangle - yfit4, psym=1, col=100
         res_leg_txt = [res_leg_txt, '!7r!3 = '+string( stddev(polangle - yfit4), form=fmt)]
         res_leg_col = [res_leg_col, 100]
      endif
      if defined(polangle_in) then begin
         oplot, index, polangle_in-yfit5, psym=6, col=250
         res_leg_txt = [res_leg_txt, '!7r!3 = '+string( stddev(polangle_in - yfit5), form=fmt)]
         res_leg_col = [res_leg_col, 250]
         chi2 = total( (polangle_in-yfit5)^2/err_polangle_in^2)/(n_elements(polangle_in)-1)
      endif
      legendastro, res_leg_txt, col=res_leg_col

;; ;; Cumulative distance of the residuals (to distinguish between random
;; ;; points and systematic trend)
;;       ymin = 1000
;;       ymax = -1000
;;       if defined(yfit1) then begin
;;          y = total( polangle - yfit1, /cumul)
;;          if min(y) lt ymin then ymin = min(y)
;;          if max(y) gt ymax then ymax = max(y)
;;       endif
;;       if defined(yfit2) then begin
;;          y = total( polangle - yfit2, /cumul)
;;          if min(y) lt ymin then ymin = min(y)
;;          if max(y) gt ymax then ymax = max(y)
;;       endif
;;       if defined(yfit3) then begin
;;          y = total( polangle - yfit3, /cumul)
;;          if min(y) lt ymin then ymin = min(y)
;;          if max(y) gt ymax then ymax = max(y)
;;       endif
;;       if defined(yfit4) then begin
;;          y = total( polangle - yfit4, /cumul)
;;          if min(y) lt ymin then ymin = min(y)
;;          if max(y) gt ymax then ymax = max(y)
;;       endif
;;       if defined(polangle_in) then begin
;;          y = total(polangle_in-yfit5,/cumul)
;;          if min(y) lt ymin then ymin = min(y)
;;          if max(y) gt ymax then ymax = max(y)
;;       endif
;; 
;;       n = n_elements(index)
;;       yra = [ymin, ymax]/float(n)
;;       yra += [-0.4,0.4]*(yra[1]-yra[0])
;; 
;;       plot, xra, xra*0, /xs, xra=xra, yra=yra, /ys, position=pp1[1,*], /noerase, xtitle='Scan index'
;;       if defined(yfit1) then oplot, index, total( polangle - yfit1, /cumul)/n, psym=6
;;       if defined(yfit2) then oplot, index, total( polangle - yfit2, /cumul)/n, psym=4, col=70
;;       if defined(yfit3) then oplot, index, total( polangle - yfit3, /cumul)/n, psym=7, col=70
;;       if defined(yfit4) then oplot, index, total( polangle - yfit4, /cumul)/n, psym=1, col=100
;;       if defined(polangle_in) then oplot, index, total(polangle_in-yfit5,/cumul)/n, psym=6, col=250
;;       legendastro, 'Normalized cumulative distance to fit'

   endelse

   ;; Plot of angles
   if mywindow eq window2 then begin
      my_yra = minmax( [polangle+err_polangle, polangle_in+err_polangle_in, $
                        polangle-err_polangle, polangle_in-err_polangle_in])
      my_yra = my_yra + [-0.5,0.5]*(my_yra[1]-my_yra[0])
      plot, xra, yra, /xs, xra=xra, $
            position=my_position, /noerase, $
            yra=my_yra, /ys, /nodata, xcharsize=1d-10, title=ext_title+' '+nickname, $
            ytitle='Degrees', xtitle=xtitle
;   d = convert_coord( xra[0], yra[1], /data, /to_device)
      for iday=0, ndays-1 do begin
         w = where( day eq myday[iday],nw)
         if nw ne 0 then begin
            oploterror, index[w], polangle[w], err_polangle[w], psym=8, syms=my_syms ;, col=ct[iday], errcol=ct[iday]
         endif
;      xyouts, d[0]+iday*100, d[1]+10, strtrim(myday[iday],2), col=ct[iday], /device
      endfor
      oplot, index, yfit1, psym=6
      oplot, index, yfit3, psym=7, col=70
      oploterror, index, polangle_in, err_polangle_in[w], psym=8, col=250, syms=my_syms, errcol=250
      oplot, index, yfit5, psym=6, col=250
      legendastro, leg_txt1, col=col_list1, psym=sym_list1
      legendastro, leg_txt, col=leg_col, psym=psym_list, /right
   endif

   outplot, /close
endfor


;;------------------------------------------------------------------------
;; Trying to fit in Stokes space
; beta : model leakage 
qm     = q_res/i_res
um     = u_res/i_res
err_qm = err_q_res/i_res
err_um = err_u_res/i_res

nsn = n_elements( index)
phi = (elevation+paral)*!dtor
;phi = atan( cos(grid_angle*!dtor)*tan(phi)) & add_warning, 'phi grid'

d = dblarr(2*nsn)
for i=0, nsn-1 do begin
   d[2*i]   = qm[i]
   d[2*i+1] = um[i]
endfor
a = dblarr(4,2*nsn)
atd = dblarr(4)
for i=0, nsn-1 do begin
   a[0,2*i]   =  cos(2*phi[i])
   a[0,2*i+1] =  sin(2*phi[i])
   a[1,2*i]   = -sin(2*phi[i])
   a[1,2*i+1] =  cos(2*phi[i])
   a[2,2*i]   =  1.d0
   a[3,2*i+1] =  1.d0
endfor
nm1 = dblarr(2*nsn,2*nsn)
for i=0, nsn-1 do begin
   nm1[2*i,2*i]     = 1.d0/err_qm[i]^2
   nm1[2*i+1,2*i+1] = 1.d0/err_um[i]^2
endfor
atam1 = invert(transpose(a)##nm1##a)
atd = transpose(a)##nm1##d
s = atam1##atd

p_est   = sqrt( s[0]^2 + s[1]^2)
psi_est = 0.5*Atan( s[1], s[0])
p1_est = sqrt( s[2]^2 + s[3]^2)
beta_est = 0.5*atan( s[3], s[2])


sigma_i = 0.d0 ; not used in this formula where we limit to high I SNR
q = s[0]
u = s[1]
sigma_q = sqrt( atam1[0,0])
sigma_u = sqrt( atam1[1,1])
iqu2poldeg, 1.d0, q, u, $
            sigma_i, sigma_q, sigma_u, pol_deg_quasar, sigma_p_plus, sigma_p_minus
;; Angle (high S/N case)
alpha_deg = 0.5*atan( u, q)*!radeg
sigma_alpha_deg = 0.5d0/(q^2+u^2)*sqrt( q^2*sigma_u^2 + u^2*sigma_q^2)*!radeg

q = s[2]
u = s[3]
sigma_q = sqrt( atam1[2,2])
sigma_u = sqrt( atam1[3,3])
iqu2poldeg, 1.d0, q, u, $
            sigma_i, sigma_q, sigma_u, p1_est_junk, sigma_p1_est_plus, sigma_p1_est_minus
sigma_beta_est = 0.5d0/(q^2+u^2)*sqrt( q^2*sigma_u^2 + u^2*sigma_q^2)*!radeg
beta_est_deg = beta_est*!radeg

qfit_2 = p_est*cos(2.d0*(psi_est+phi)) + p1_est*cos(2.*beta_est)
ufit_2 = p_est*sin(2.d0*(psi_est+phi)) + p1_est*sin(2.*beta_est)
;; leg_txt = ["P: "+strtrim(p_est,2)+" +- "+strtrim( sigma_p_est, 2), $
;;            "Psi: "+strtrim(psi_est*!radeg,2)+" +- "+strtrim( sigma_psi_est, 2), $
;;            "p_const: "+strtrim(p1_est,2)+" +- "+strtrim( sqrt( sigma_p1_est, 2), $
;;            "beta_est: "+strtrim(beta_est*!radeg,2)+" +- "+strtrim( sigma_beta_est,2)]
leg_txt = ["P: "+strtrim(pol_deg_quasar,2)+" +- "+strtrim( (sigma_p_plus+sigma_p_minus)/2., 2), $
           "Psi: "+strtrim(alpha_deg,2)+" +- "+strtrim( sigma_alpha_deg, 2), $
           "p_const: "+strtrim(p1_est,2)+" +- "+strtrim( (sigma_p1_est_plus+sigma_p1_est_minus)/2., 2), $
           "beta_est: "+strtrim(beta_est*!radeg,2)+" +- "+strtrim( sigma_beta_est,2)]

chi2_q  = 1.d0/(nsn-1)*total( (qm-qfit_2)^2/err_qm^2)
chi2_u  = 1.d0/(nsn-1)*total( (um-ufit_2)^2/err_um^2)
chi2_qu = 1.d0/(nsn-1)*total( (qm-qfit_2)^2/err_qm^2 + (um-ufit_2)^2/err_um^2)

leg_fit = ['!7w = !3a + b x !7(d+g)!3']
leg_fit_col = [70]

;; ;; simple independent regress (for memory)
;; templates = dblarr(2,nsn)
;; templates[0,*] = cos(2.d0*phi)
;; templates[1,*] = sin(2.d0*phi)
;; cq = regress( templates, qm, measure_err=err_qm, /double, const=const_q)
;; qfit = const_q + cq[0]*templates[0,*] + cq[1]*templates[1,*]
;; cu = regress( templates, um, measure_err=err_qm, /double, const=const_u)
;; ufit = const_u + cu[0]*templates[0,*] + cu[1]*templates[1,*]
;; psi_ra_q = 0.5*atan(-cq[1]/cq[0])*!radeg
;; psi_ra_u = 0.5*atan(cu[0]/cu[1])*!radeg
;; p_qso_q  = sqrt( total( cq^2))
;; p_qso_u  = sqrt( total( cu^2))
;; ;;***********
;; ;; **IF** there is only the leakage term as an extra contribution and
;; ;; no polarized constant background (or even worse, a background that
;; ;; would rotate with elevation).
;; beta = 0.5*Atan(const_u/const_q)*!radeg
;; p_beta = sqrt( const_q^2 + const_u^2)
;; ;;***********
;; print, "psi_ra_q = ", psi_ra_q
;; print, "psi_ra_u = ", psi_ra_u
;; print, "p_qso_q  = ", p_qso_q 
;; print, "p_qso_u  = ", p_qso_u 
;; print, "beta     = ", beta    
;; print, "p_beta   = ", p_beta  

;;------------------------------------------------------------------
;; Fitting an extra component that would depend on elevation only
;; 1. method 1 (global fit with regress)
templates = dblarr(4,nsn)
templates[0,*] = cos(2.d0*phi)
templates[1,*] = sin(2.d0*phi)
templates[2,*] = cos(2.d0*elevation*!dtor)
templates[3,*] = sin(2.d0*elevation*!dtor)
cq = regress( templates, qm, measure_err=err_qm, /double, const=const_q)
qfit_1 = const_q + cq[0]*templates[0,*] + cq[1]*templates[1,*] + cq[2]*templates[2,*] + cq[3]*templates[3,*]
cu = regress( templates, um, measure_err=err_qm, /double, const=const_u)
ufit_1 = const_u + cu[0]*templates[0,*] + cu[1]*templates[1,*] + cu[2]*templates[2,*] + cu[3]*templates[3,*]

chi2_q1  = 1.d0/(nsn-1)*total( (qm-qfit_1)^2/err_qm^2)
chi2_u1  = 1.d0/(nsn-1)*total( (um-ufit_1)^2/err_um^2)
chi2_qu1 = 1.d0/(nsn-1)*total( (qm-qfit_1)^2/err_qm^2 + (um-ufit_1)^2/err_um^2)

leg_fit = [leg_fit, '!7w = !3c + d x !7(d+g) + !3e x !7d!3']
leg_fit_col = [leg_fit_col, 150]


;; Method 2 (global fit with mpfit)


;; Method 3 (fit only the residuals to the 1st fit)
templates = dblarr(2,nsn)
templates[0,*] = cos(2.d0*elevation*!dtor)
templates[1,*] = sin(2.d0*elevation*!dtor)
cq_3 = regress( templates, qm-qfit_2, measure_err=err_qm, /double, const=const_q_3)
qfit_3 = const_q_3 + cq_3[0]*templates[0,*] + cq_3[1]*templates[1,*]
cu_3 = regress( templates, um-ufit_2, measure_err=err_um, /double, const=const_u_3)
ufit_3 = const_u_3 + cu_3[0]*templates[0,*] + cu_3[1]*templates[1,*]

chi2_q3  = 1.d0/(nsn-1)*total( (qm-qfit_2-qfit_3)^2/err_qm^2)
chi2_u3  = 1.d0/(nsn-1)*total( (um-ufit_2-ufit_3)^2/err_um^2)
chi2_qu3 = 1.d0/(nsn-1)*total( (qm-qfit_2-qfit_3)^2/err_qm^2 + (um-ufit_2-ufit_3)^2/err_um^2)
leg_fit = [leg_fit, '!7w = !3a + b x !7(d+g) + !3f x !7d!3']
leg_fit_col = [leg_fit_col, 200]

phi_fit = dindgen(760) - 360
xtitle='elevation+paral'
wind, 1, 1, /free, /large
fmt = '(F6.3)'
outplot, file=plot_file+'_2', png=png, ps=ps
!p.charsize = 0.7
;yra = [-0.1,0.2]
;stop
my_multiplot, 2, 2, pp, pp1, /rev, gap_x=0.05
ploterror, phi*!radeg, qm, err_qm, psym=8, position=pp1[0,*], $
           title=ext_title+' '+nickname, xtitle=xtitle, /nodata ;, yra=yra
for iday=0, ndays-1 do begin
   w = where(day eq myday[iday], nw)
   if nw ne 0 then begin
      oploterror, phi[w]*!radeg, qm[w], err_qm[w], psym=8, symsize=0.5, $
                  col=ct[iday], errcol=ct[iday]
   endif
endfor
;; oplot,     phi_fit, const_q + cq[0]*cos(2*phi_fit*!dtor) + cq[1]*sin(2*phi_fit*!dtor)
oplot,     phi_fit, p_est*cos(2.d0*(psi_est+phi_fit*!dtor)) + p1_est*cos(2*beta_est), col=70
legendastro, ['Q/I', leg_txt], col=[0, 70,70,70,70]
legendastro, ['chi2_q: '+string(chi2_q,form=fmt), $
              'chi2_qu: '+string(chi2_qu,form=fmt)], /bottom

ploterror, phi*!radeg, um, err_um, psym=8, position=pp1[1,*], /noerase, xtitle=xtitle,$
           /nodata ;, yra=yra
for iday=0, ndays-1 do begin
   w = where(day eq myday[iday], nw)
   if nw ne 0 then begin
      oploterror, phi[w]*!radeg, um[w], err_um[w], psym=8, symsize=0.5, $
                  col=ct[iday], errcol=ct[iday]
   endif
endfor
;;oplot,     phi_fit, const_u + cu[0]*cos(2*phi_fit*!dtor) + cu[1]*sin(2*phi_fit*!dtor)
oplot,     phi_fit, p_est*sin(2.d0*(psi_est+phi_fit*!dtor)) + p1_est*sin(2*beta_est), col=70
legendastro, 'U/I'
legendastro, ['chi2_u: '+string(chi2_u,form=fmt), $
              'chi2_qu: '+string(chi2_qu,form=fmt)], /bottom


;; Residuals
ploterror, index, qm-qfit_2, err_qm, psym=8, syms=0.5, position=pp1[2,*], /noerase, $
           xtitle='scan index', xra=minmax(index)+[-1,1]*0.1*(max(index)-min(index)), /xs, $
           ytitle='Jy'
oplot, [-1,1]*360, [0,0]
oploterror, index, qm-qfit_2, err_qm, psym=8, syms=0.5, col=70, errcol=70
oploterror, index+0.1, qm-qfit_2-qfit_3, err_qm, psym=8, syms=0.5, col=150, errcol=150
oploterror, index+0.2, qm-qfit_1, err_qm, psym=8, syms=0.5, col=200, errcol=200
legendastro, 'Q/I residuals'

legendastro, ['chi2_q, chi2_qu: '+string(chi2_q,form=fmt)+", "+string(chi2_qu,form=fmt), $
              'chi2_q1, chi2_qu1: '+string(chi2_q1,form=fmt)+", "+string(chi2_qu1,form=fmt), $
              'chi2_q3, chi2_qu3: '+string(chi2_q3,form=fmt)+", "+string(chi2_qu3,form=fmt)], $
             col=[70,150,200], /bottom
legendastro, leg_fit, col=leg_fit_col, /right

ploterror, index, um-ufit_2, err_um, psym=8, syms=0.5, position=pp1[3,*], /noerase, $
           xtitle='scan index', xra=minmax(index)+[-1,1]*0.1*(max(index)-min(index)), /xs, $
           ytitle='Jy'
oplot, [-1,1]*360, [0,0]
oploterror, index, um-ufit_2, err_um, psym=8, syms=0.5, col=70, errcol=70
oploterror, index+0.1, um-ufit_2-ufit_3, err_um, psym=8, syms=0.5, col=150, errcol=150
oploterror, index+0.2, um-ufit_1, err_um, psym=8, syms=0.5, col=200, errcol=200
legendastro, 'U/I residuals'
fmt = '(F6.3)'
legendastro, ['chi2_u, chi2_qu: '+string(chi2_u,form=fmt)+", "+string(chi2_qu,form=fmt), $
              'chi2_u1, chi2_qu1: '+string(chi2_u1,form=fmt)+", "+string(chi2_qu1,form=fmt), $
              'chi2_u3, chi2_qu3: '+string(chi2_u3,form=fmt)+", "+string(chi2_qu3,form=fmt)], $
             col=[70,150,200], /bottom
outplot, /close

print, 'multifit QU results: '
for i=0, n_elements(leg_txt)-1 do print, leg_txt[i]
print, "chi2_q: "+strtrim(chi2_q)
print, "chi2_u: "+strtrim(chi2_u)
print, "chi2_qu: "+strtrim(chi2_qu)

reset_warning

end
