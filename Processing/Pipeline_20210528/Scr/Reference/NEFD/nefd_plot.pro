
pro nefd_plot, time_center_cumul, sigma_flux_center_cumul_mJy, nefd_list, $
               source=source, sum_one_over_sigma_flux_center_sq=sum_one_over_sigma_flux_center_sq, $
               ps=ps, file=file, png=png, q=q, u=u, comment=comment, elevation=elevation, tau=tau, $
               thick=thick, symsize=symsize, mail=mail, noplot=noplot, input_title=input_title
               

if not keyword_set(file) then file='bidon'
if not keyword_set(source) then source='Unspec. Source'
if not keyword_set(comment) then comment=''

if not keyword_set(noplot) then begin
   chars=0.5
   if not keyword_set(ps) then wind, 1, 1, /free, /ylarge
   outplot, file=file, png=png, ps=ps, thick=thick, charthick=thick
   my_multiplot, 1, 4, pp, pp1, /rev
endif

stokes = ['I', 'Q', 'U']
istokes = 0
if keyword_set(q) then istokes = 1
if keyword_set(u) then istokes = 2

tau_elev = long(keyword_set(tau)) + long(keyword_set(elevation))
if tau_elev ne 0 and tau_elev ne 2 then begin
   message, /info, "tau and elevation keywords must be set together"
   return
endif

if tau_elev ne 0 then comment = [comment, "Account for tau/sin(el)"]

nefd_list = dblarr(5)
for iarray=1, 3 do begin
   t_cumul = reform( time_center_cumul[      *,(iarray-1)*3+istokes])
   sigma   = reform( sigma_flux_center_cumul_mJy[*,(iarray-1)*3+istokes])
   if keyword_set(sum_one_over_sigma_flux_center_sq) then begin
      one_over_sigma_scans_sq = 1.d0/sum_one_over_sigma_flux_center_sq[*,(iarray-1)*3+istokes]
   endif
   w = where( sigma ne 0, nw)
   if nw ne 0 then begin
      t_cumul = t_cumul[w]
      sigma = sigma[w]
      if tau_elev ne 0 then sigma = sigma * exp(tau[iarray,w]/sin(elevation[w]*!dtor))
      xra = [100, max(t_cumul)*1.5]

      ;; strict sqrt(t) fit
      fit  = linfit( 1./sqrt(t_cumul), sigma)
      nefd_list[iarray-1] = fit[1]
      
      ;; Generic power law
;;      fit1 = linfit( alog(t_cumul), alog(sigma))

      if not keyword_set(noplot) then begin
;         if iarray eq 1 and keyword_set(input_title) then
;         title=input_title else delvarx, title
         if keyword_set(input_title) then title=input_title else title=''
         plot, t_cumul, sigma, psym=4, position=pp1[iarray-1,*], /noerase, chars=chars, $
               xtitle='Cumulative time (sec)', ytitle='Beam sensitivity', $
               yra = [min(sigma)/2.,max(sigma)*10], /ys, /xs, $
               /xlog, /ylog, xra=xra, title=title
         oplot, t_cumul, fit[0] + fit[1]/sqrt(t_cumul), col=70
         if keyword_set(sum_one_over_sigma_flux_center_sq) then $
            oplot, t_cumul, sqrt(one_over_sigma_scans_sq), col=200
         legendastro, [stokes[istokes], 'Array '+strtrim(iarray,2), source], box=0, /right
         legendastro, [comment, num2string(fit[1])+"x t!u1/2!n + "+num2string(fit[0])], $
                      box=0, textcol=[0,70], col=[0,70]
         legendastro, ['NEFD = '+string( (fit[0] + fit[1]),format=fmt)+' mJy.s1/2'], $
                      textcol=[70], /left, /bottom, box=0

;      oplot, t_cumul, exp(fit1[0])*t_cumul^fit1[1], col=250
;      legendastro, [num2string(fit[1])+"x t!u1/2!n + "+num2string(fit[0]), $
;                    num2string(exp(fit1[0]))+"xt!u"+num2string(fit1[1])+"!n"], $
;                   box=0, textcol=[70,250], col=[70,250]
;      legendastro, ['NEFD = '+string( 1000*(fit[0] + fit[1]),format=fmt)+' mJy.s1/2', $
;                    'NEFD = '+string( 1000*(exp(fit1[0])),format=fmt)+' mJy.s1/2'], $
;                   textcol=[70,250], /left, /bottom, box=0
         fmt='(F5.1)'
      endif
   endif
   
endfor
nefd_list[4] = nefd_list[1] ;; 2mm = A2

;;------------------------------------------------------
;; Combined 1mm
;; this time derived from the number of hits per pixel and grid_step
;; is already divided by two in nk_grid2info since A1 and A3 observe
;; the map at the same time
case istokes of
   0: index=9
   1: index=10
   2: index=11
endcase

t_cumul = reform( time_center_cumul[*,index])

sigma   = reform( sigma_flux_center_cumul_mJy[*,index])
w = where( sigma ne 0, nw)
t_cumul = t_cumul[w]
sigma = sigma[w]

;; strict sqrt(t) fit
fit  = linfit( 1./sqrt(t_cumul), sigma)
nefd_list[3] = fit[1]

;; ;; Generic power law
;; fit1 = linfit( alog(t_cumul), alog(sigma))

if not keyword_set(noplot) then begin
   if keyword_set(input_title) then title=input_title else title=''
   plot, t_cumul, sigma, psym=4, position=pp1[3,*], /noerase, chars=chars, $
         xtitle='Cumulative time (sec)', ytitle='Beam sensitivity', $
         yra = [min(sigma)/2.,max(sigma)*10], /ys, /xs, $
         /xlog, /ylog, xra=xra, title=title
   oplot, t_cumul, fit[0] + fit[1]/sqrt(t_cumul), col=70
;oplot, t_cumul, exp(fit1[0])*t_cumul^fit1[1], col=250

   legendastro, [stokes[istokes], 'Combined 1mm', source], box=0, /right
;legendastro, [num2string(fit[1])+"x t!u1/2!n + "+num2string(fit[0]), $
;              num2string(exp(fit1[0]))+"xt!u"+num2string(fit1[1])+"!n"], $
;             box=0, textcol=[70,250], col=[70,250]
   legendastro, [comment, num2string(fit[1])+"x t!u1/2!n + "+num2string(fit[0])], $
                box=0, textcol=[0,70], col=[0,70]

   fmt='(F4.1)'
;legendastro, ['NEFD = '+string( 1000*(fit[0] + fit[1]),format=fmt)+' mJy.s1/2', $
;              'NEFD = '+string( 1000*(exp(fit1[0])),format=fmt)+' mJy.s1/2'], $
;             textcol=[70,250], /left, /bottom, box=0
   legendastro, ['NEFD = '+string( (fit[0] + fit[1]),format=fmt)+' mJy.s1/2'], $
                textcol=[70], /left, /bottom, box=0

   print, source+" Combined 1mm: "+strtrim((exp(fit[0])),2)
   my_multiplot, /reset
   outplot, /close, mail=mail


;;============================
;; All on the same plot

;;   save, time_center_cumul, sigma_flux_center_cumul_mJy, $
;;         file = 'data.save'
;;   stop

   if not keyword_set(ps) then wind, 2, 2, /free, /large
   outplot, file=file+"_2", png=png, ps=ps, thick=thick, charthick=thick
   !p.multi=0
   chars = 1
   my_multiplot, 1, 1, pp, pp1, xmargin=0.15, ymargin=0.1
   fit_res = dblarr(4,2)
   plot_color_convention, col_a1, col_a2, col_a3, $
                          col_mwc349, col_crl2688, col_ngc7027, $
                          col_n2r9, col_n2r12, col_n2r14, col_1mm
   array_col = [col_a1, col_a2, col_a3, col_1mm]

   for iarray=1, 4 do begin
      t_cumul = reform( time_center_cumul[      *,(iarray-1)*3+istokes])
      sigma   = reform( sigma_flux_center_cumul_mJy[*,(iarray-1)*3+istokes])

;;      if iarray eq 2 then tf_corr = tf_corr_fac2 else tf_corr=tf_corr_fac1
      
      w = where( sigma ne 0, nw)
      if nw ne 0 then begin
         t_cumul = t_cumul[w]
         sigma   = sigma[w]
;         sigma = sigma[w] * tf_corr
         xra = [100, max(t_cumul)*1.5]

         ;; strict sqrt(t) fit
         fit  = linfit( 1./sqrt(t_cumul), sigma)
         fit_res[iarray-1,0] = fit[0]
         fit_res[iarray-1,1] = fit[1]
         
;;      ;; Generic power law
;;         fit1 = linfit( alog(t_cumul), alog(sigma))

         if iarray eq 1 then begin
            if keyword_set(input_title) then title=input_title else title=''
            plot, t_cumul, sigma, psym=8, chars=chars, $
                  xtitle='Effective integration time (sec)', ytitle='Flux uncertainty (stat.)  [mJy]', $
                  xra=[50,max(t_cumul)*1.2], yra = [4e-5, 1e-2]*1000, /ys, /xs, $
                  /xlog, /ylog, thick=thick, position=pp1[0,*], /nodata, title=title
            legendastro, strupcase(stokes[istokes])
         endif
         oplot, t_cumul, sigma, psym=8, col=array_col[iarray-1], thick=thick, symsize=symsize
         oplot, t_cumul, fit[0] + fit[1]/sqrt(t_cumul), col=0, thick=2
      endif
   endfor
;;    legendastro, ['A1:    '+string(fit_res[0,0],form=fmt)+" + "+string(fit_res[0,1],form=fmt)+" t!u1/2!n", $
;;                  'A2:    '+string(fit_res[1,0],form=fmt)+" + "+string(fit_res[1,1],form=fmt)+" t!u1/2!n", $
;;                  'A3:    '+string(fit_res[2,0],form=fmt)+" + "+string(fit_res[2,1],form=fmt)+" t!u1/2!n", $
;;                  'A1&A3: '+string(fit_res[3,0],form=fmt)+" + "+string(fit_res[3,1],form=fmt)+" t!u1/2!n"], $
;;                 col=[col_A1, col_a2, col_a3, col_1mm], psym=[4,4,4,4], thick=2, $
;;                 textcol = [col_A1, col_a2, col_a3, col_1mm]
;;    legendastro, '1/sqrt(time)', /right, line=0, /trad
   outplot, /close, /verb
endif

end
