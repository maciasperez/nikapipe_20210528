

nk_init, '20140219s205', param, info, /force
nk_getdata, param, info, data, kidpar

data = data[2000:14000]

nkids = n_elements(kidpar)

;; Determine when the kids are on/off source
off_source = data.toi*0.d0
for ikid=0, nkids-1 do begin
   if kidpar[ikid].type eq 1 then begin
      nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                            0., 0., dra, ddec, nas_x_ref=kidpar[ikid].nas_center_X, nas_y_ref=kidpar[ikid].nas_center_Y
      dist_source = sqrt(ddec^2 + dra^2)
      w = where( dist_source ge param.decor_cm_dmin, nw)
      if nw ne 0 then off_source[ikid,w] = 1
   endif
endfor

;; Compute the common mode
nk_get_cm, param, info, data, kidpar, off_source, common_mode

;; Subtract the common mode
data_copy = data
templates_1mm = reform( common_mode[0,*])
templates_2mm = reform( common_mode[1,*])
nk_subtract_templates, param, info, data, kidpar, off_source, templates_1mm, templates_2mm

wind, 1, 1, /free, /large
!p.multi=[0,2,2]
for lambda=1, 2 do begin
   nk_list_kids, kidpar, valid=w1, nvalid=nw1, lambda=lambda
   make_ct, nw1, ct
   plot, data_copy.toi[w1[0]], title=strtrim(lambda,2)+"mm"
   for i=0, nw1-1 do oplot, data_copy.toi[w1[i]], col=ct[i]
   oplot, common_mode[lambda-1,*], col=0, thick=2

   plot, data.toi[w1[0]], title=strtrim(lambda,2)+"mm"
   for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]

endfor
!p.multi=0


end
