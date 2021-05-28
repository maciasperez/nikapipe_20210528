
pro simu
;; Generate input sky, data etc...
nk_sim_polar_data, param, data_in, kidpar,info1, ps, test_toi, $
                   maps_S0_in, maps_S1_in, maps_S2_in, $
                   xmap_in, ymap_in


;;=============================================================

;; Init data
data = data_in

;; Patch f_sampling untils the correct one is in "data"
!nika.f_sampling = ps.gen.nu_sampling

;; Template subtraction
if ps.gen.add_template ne 0 then begin
   param.polar_n_template_harmonics = ps.template.n_harmonics
   nk_hwp_rm, param, kidpar, data, fit
   test_toi.template_fit = fit
endif

;; Diagnostic plots
nk_sim_polar_plots, param, kidpar, data, ps, data_in, test_toi
print, ""
print, "HERE"

;; Project maps

;; Make co-add maps at the same time to show the difference between co-add and
;; lock-in on the same input maps for the talk

nk_data_coadd_polar, param, info1, data, kidpar, map_1mm=map_1mm, $
                     map_q_1mm=map_q_1mm, map_u_1mm=map_u_1mm, $
                     map_2mm=map_2mm, map_q_2mm=map_q_2mm,$
                     map_u_2mm=map_u_2mm, /plot
;; nk_polar_maps, param, info1, data, kidpar
stop

;; Display result
if keyword_set(png) then begin
   S0_in_png  = param.output_dir+"/S0_in.png"
   q_in_png  = param.output_dir+"/q_in.png"
   u_in_png  = param.output_dir+"/u_in.png"

   S0_out_png = param.output_dir+"/S0_out.png"
   q_out_png = param.output_dir+"/q_out.png"
   u_out_png = param.output_dir+"/u_out.png"

   S0_out_coadd_png = param.output_dir+"/S0_out_coadd.png"
   q_out_coadd_png = param.output_dir+"/q_out_coadd.png"
   u_out_coadd_png = param.output_dir+"/u_out_coadd.png"

   diff_S0_png  = param.output_dir+'/diff_s0.png'
   diff_q_png  = param.output_dir+'/diff_s1.png'
   diff_u_png  = param.output_dir+'/diff_s2.png'

   diff_t1_png = param.output_dir+'/diff_s0_1.png'
   diff_q1_png = param.output_dir+'/diff_s1_1.png'
   diff_u1_png = param.output_dir+'/diff_s2_1.png'

   diff_t1_coadd_png = param.output_dir+'/diff_s0_coadd_1.png'
   diff_q1_coadd_png = param.output_dir+'/diff_s1_coadd_1.png'
   diff_u1_coadd_png = param.output_dir+'/diff_s2_coadd_1.png'
endif

nx_in = n_elements( xmap_in[*,0])
ny_in = n_elements( xmap_in[0,*])
nx    = n_elements( xmap_out[*,0])
ny    = n_elements( xmap_out[0,*])
for lambda=1, 2 do begin
   w = where( kidpar.array eq lambda, nw)
   if nw ne 0 then begin
      map_S0_coadd = reform( maps_S0_coadd[*, lambda-1], nx, ny)
      map_S1_coadd = reform( maps_S1_coadd[*, lambda-1], nx, ny)
      map_S2_coadd = reform( maps_S2_coadd[*, lambda-1], nx, ny)

      map_S0 = reform( maps_S0[  *, lambda-1], nx, ny)
      map_S1 = reform( maps_S1[  *, lambda-1], nx, ny)
      map_S2 = reform( maps_S2[  *, lambda-1], nx, ny)

      S0_ra = minmax( maps_S0_in[*,lambda-1])
      S1_ra = minmax( maps_S1_in[*,lambda-1])
      S2_ra = minmax( maps_S2_in[*,lambda-1])

      wind, 1, 1, /free, xs=1500, ys=800
      my_multiplot, 4, 3, pp, pp1, /rev, gap_x=0.1
      erase
      imview, reform( maps_S0_in[*,lambda-1], nx_in, ny_in), xmap=xmap_in, ymap=ymap_in, $
              position=pp1[0,*], title='S0 in',  imrange=S0_ra, /noerase, png=S0_in_png
      imview, map_S0, xmap=xmap_out, ymap=ymap_out, position=pp1[1,*], title='S0 out (lockin)', imrange=S0_ra, /noerase, png=S0_out_png
      imview, map_S0_coadd, xmap=xmap_out, ymap=ymap_out, position=pp1[2,*], title='S0 out (Coadd)', imrange=S0_ra, /noerase, png=S0_out_coadd_png
      w = where( finite(map_s0) and finite(map_s0_coadd))
      diff = map_s0*0.d0 + !values.d_nan
      diff[w] = map_S0[w] - map_s0_coadd[w]
      imview, diff, xmap=xmap_out, ymap=ymap_out, imrange=[-2,2]*stddev(diff[w]), position=pp1[3,*], title='Lockin-Coadd', /noerase, png=S0_lockin_coadd_diff_png

      imview, reform( maps_S1_in[*,lambda-1], nx_in, ny_in), xmap=xmap_in, ymap=ymap_in, $
              position=pp1[4,*], title='S1 in',  imrange=S1_ra, /noerase, png=S1_in_png
      imview, map_S1, xmap=xmap_out, ymap=ymap_out, position=pp1[5,*], title='S1 out (lockin)', imrange=S1_ra, /noerase, png=S1_out_png
      imview, map_S1_coadd, xmap=xmap_out, ymap=ymap_out, position=pp1[6,*], title='S1 out (Coadd)', imrange=S1_ra, /noerase, png=S1_out_coadd_png
      w = where( finite(map_s1) and finite(map_s1_coadd))
      diff = map_s1*0.d0 + !values.d_nan
      diff[w] = map_S1[w] - map_s1_coadd[w]
      imview, diff, xmap=xmap_out, ymap=ymap_out, imrange=[-2,2]*stddev(diff[w]), position=pp1[7,*], title='Lockin-Coadd', /noerase, png=S1_lockin_coadd_diff_png

      imview, reform( maps_S2_in[*,lambda-1], nx_in, ny_in), xmap=xmap_in, ymap=ymap_in, $
              position=pp1[8,*], title='S2 in',  imrange=S2_ra, /noerase, png=S2_in_png
      imview, map_S2, xmap=xmap_out, ymap=ymap_out, position=pp1[9,*], title='S2 out (lockin)', imrange=S2_ra, /noerase, png=S2_out_png
      imview, map_S2_coadd, xmap=xmap_out, ymap=ymap_out, position=pp1[10,*], title='S2 out (Coadd)', imrange=S2_ra, /noerase, png=S2_out_coadd_png
      w = where( finite(map_s2) and finite(map_s2_coadd))
      diff = map_s2*0.d0 + !values.d_nan
      diff[w] = map_S2[w] - map_s2_coadd[w]
      imview, diff, xmap=xmap_out, ymap=ymap_out, imrange=[-2,2]*stddev(diff[w]), position=pp1[11,*], title='Lockin-Coadd', /noerase, png=S2_lockin_coadd_diff_png
   endif
endfor

;;!;; 
;;!;; 
;;!;; 
;;!;; 
;;!;; 
;;!;; 
;;!;; 
;;!;;       imview, map_q,  xmap=xmap_in,  ymap=ymap_in,  position=pp1[1,*], title='S1 in',  imrange=q_ra, /noerase, png=q_in_png
;;!;;       imview, map_u,  xmap=xmap_in,  ymap=ymap_in,  position=pp1[2,*], title='S2 in',  imrange=u_ra, /noerase, png=u_in_png
;;!;; 
;;!;;       imview, map_S1, xmap=xmap_out, ymap=ymap_out, position=pp1[4,*], title='S1 out', imrange=q_ra, /noerase, png=q_out_png
;;!;;       imview, map_S2, xmap=xmap_out, ymap=ymap_out, position=pp1[5,*], title='S2 out', imrange=u_ra, /noerase, png=u_out_png
;;!;; 
;;!;; imview, map_S0_coadd, xmap=xmap_out, ymap=ymap_out, position=pp1[3,*], title='S0 out', imrange=t_ra, /noerase, png=t_out_coadd_png
;;!;; imview, map_S1_coadd, xmap=xmap_out, ymap=ymap_out, position=pp1[4,*], title='S1 out', imrange=q_ra, /noerase, png=q_out_coadd_png
;;!;; imview, map_S2_coadd, xmap=xmap_out, ymap=ymap_out, position=pp1[5,*], title='S2 out', imrange=u_ra, /noerase, png=u_out_coadd_png
;;!;; 
;;!;; ;; Differences with the original color scale
;;!;; if n_elements(xmap_in) eq n_elements(xmap_out) then begin
;;!;;    map_diff = map_t*0.
;;!;;    w = where( finite(map_S0) eq 1)
;;!;;    map_diff[w] = map_t[w]-map_S0[w]
;;!;;    imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[6,*], title='T in - out', imrange=t_ra, /noerase, png=diff_t_png
;;!;; 
;;!;;    map_diff = map_t*0. + !values.d_nan
;;!;;    map_diff[w] = map_q[w]-map_S1[w]
;;!;;    imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[7,*], title='Q in - out', imrange=q_ra, /noerase, png=diff_q_png
;;!;; 
;;!;;    map_diff = map_t*0. + !values.d_nan
;;!;;    map_diff[w] = map_u[w]-map_S2[w]
;;!;;    imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[8,*], title='U in - out', imrange=u_ra, /noerase, png=diff_u_png
;;!;; 
;;!;; ;; specific color scales
;;!;;    map_diff = map_t*0. + !values.d_nan
;;!;;    map_diff[w] = (map_t[w]-map_S0[w])/stddev(map_t[w])
;;!;;    imrange = [-3,3]*stddev(map_diff[w])
;;!;;    imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[9,*], title='(T!din!n - T!dout!n)/!7r!3(T!din!n)', imrange=imrange, /noerase, png=diff_t1_png
;;!;; 
;;!;;    map_diff = map_t*0. + !values.d_nan
;;!;;    map_diff[w] = (map_q[w]-map_S1[w])/stddev(map_q[w])
;;!;;    imrange = [-3,3]*stddev(map_diff[w])
;;!;;    imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[10,*], title='(Q!din!n - Q!dout!n)/!7r!3(Q!din!n)', imrange=imrange, /noerase, png=diff_q1_png
;;!;; 
;;!;;    map_diff = map_t*0. + !values.d_nan
;;!;;    map_diff[w] = (map_u[w]-map_S2[w])/stddev(map_u[w])
;;!;;    imrange = [-3,3]*stddev(map_diff[w])
;;!;;    imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[11,*], title='(U!din!n - U!dout!n)/!7r!3(U!din!n)', imrange=imrange, /noerase, png=diff_u1_png
;;!;; 
;;!;; ;; specific color scales (coadd)
;;!;;    map_diff = map_t*0. + !values.d_nan
;;!;;    map_diff[w] = (map_t[w]-map_S0_coadd[w])/stddev(map_t[w])
;;!;;    imrange = [-3,3]*stddev(map_diff[w])
;;!;;    imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[9,*], title='(T!din!n - T!dout!n)/!7r!3(T!din!n)', imrange=imrange, /noerase, png=diff_t1_coadd_png
;;!;; 
;;!;;    map_diff = map_t*0. + !values.d_nan
;;!;;    map_diff[w] = (map_q[w]-map_S1_coadd[w])/stddev(map_q[w])
;;!;;    imrange = [-3,3]*stddev(map_diff[w])
;;!;;    imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[10,*], title='(Q!din!n - Q!dout!n)/!7r!3(Q!din!n)', imrange=imrange, /noerase, png=diff_q1_coadd_png
;;!;; 
;;!;;    map_diff = map_t*0. + !values.d_nan
;;!;;    map_diff[w] = (map_u[w]-map_S2_coadd[w])/stddev(map_u[w])
;;!;;    imrange = [-3,3]*stddev(map_diff[w])
;;!;;    imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[11,*], title='(U!din!n - U!dout!n)/!7r!3(U!din!n)', imrange=imrange, /noerase, png=diff_u1_coadd_png
;;!;; endif else begin
;;!;;    print, ""
;;!;;    print, "Need to rebin, but careful to the interpretation of the differences then..."
;;!;; endelse
;;!;; 
;;!;; ;; ;; Stats
;;!;; ;; w = where( map_hits gt median( map_hits), nw)
;;!;; ;; wind, 1, 1, /free, /large
;;!;; ;; n_histwork, map_t[w]-map_S0[w], /fill, title='S0!din!n - S0!dout!n', position=pp1[0,*]
;;!;; ;; n_histwork, map_q[w]-map_S1[w], /fill, title='S1!din!n - S1!dout!n', position=pp1[1,*], /noerase
;;!;; ;; n_histwork, map_u[w]-map_S2[w], /fill, title='S2!din!n - S2!dout!n', position=pp1[2,*], /noerase

end
