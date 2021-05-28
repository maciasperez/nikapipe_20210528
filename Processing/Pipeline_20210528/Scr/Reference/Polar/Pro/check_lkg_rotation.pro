
process = 1

;; Mars
;; scan = '20171124s110'
;; NGC
scan = '20171124s187'
;; Uranus
;; scan = '20171124s'+strtrim( [240],2)
;; scan = '20171124s254'
;; scan = '20171123s144'
;;scan = '20171124s252'
;; scan = '20171124s245'
;;scan = '20180617s136'


;; test beammap run 32 (19)
;; scan = '20180614s143'
;; scan = '20180613s157'
;; scan = '20171121s182'

reset_preproc = 1
root_dir = !nika.plot_dir+"/Leakage"

;; Param
nk_default_param, param
param.map_xsize = 600.d0
param.map_ysize = 600.d0
param.map_reso  = 2.d0
param.math = "RF"
param.alain_rf = 1
param.preproc_copy = 1
param.plot_ps = 0

;; To actually center the Nasmyth and Azel coordinates before applying
;; shear rotate for the comparison
nk_get_kidpar_ref, s, kidpar=kidpar, scan=scan
w1 = where( kidpar.type eq 1)
param.fpc_dx = kidpar[w1[0]].nas_center_x
param.fpc_dy = kidpar[w1[0]].nas_center_y

if reset_preproc eq 1 then spawn, "rm -f "+param.preproc_dir+"/data_"+scan+".save"

;; ;;------------------------------------------
;; ;; Reduce scans in all projections
if process eq 1 then begin 
   param.map_proj = "NASMYTH"
   param.project_dir = root_dir+"/"+param.map_proj
   save, scan, param, file='param_nasmyth.save'
   
   param.map_proj = "AZEL"
   param.project_dir = root_dir+"/"+param.map_proj
   save, scan, param, file='param_azel.save'
   
   param.map_proj = "RADEC"
   param.project_dir = root_dir+"/"+param.map_proj
   save, scan, param, file='param_radec.save'

   paramfile_list = ['param_nasmyth.save', 'param_azel.save', 'param_radec.save']
   np = n_elements(paramfile_list)
   if np gt 1 then begin
      split_for, 0, np-1, nsplit=np, $
                 commands=['nk_lkg_sub, i, paramfile_list'], $
                 varnames=['paramfile_list']
   endif else begin
      nk_lkg_sub, 0, paramfile_list
   endelse
endif 


;;------------------------------------------
;; Check polar and shear rotations
restore, root_dir+"/NASMYTH/v_1/"+scan+"/results.save"
info_nasmyth = info1
nhits_nas = grid1.nhits_1mm
i_nas = grid1.map_i_1mm
q_nas = grid1.map_q_1mm ; /info1.result_flux_i_1mm
u_nas = grid1.map_u_1mm ; /info1.result_flux_i_1mm
xmap  = grid1.xmap
ymap  = grid1.ymap

restore, root_dir+"/AZEL/v_1/"+scan+"/results.save"
info_azel = info1
nhits_azel = grid1.nhits_1mm
i_azel = grid1.map_i_1mm
q_azel = grid1.map_q_1mm ; /info1.result_flux_i_1mm
u_azel = grid1.map_u_1mm ; /info1.result_flux_i_1mm

;; restore, !nika.plot_dir+"/RADEC_"+ext+"/v_1/"+scan+"/results.save"
;; info_radec = info1
;; nhits_radec = grid1.nhits_1mm
;; i_radec = grid1.map_i_1mm
;; q_radec = grid1.map_q_1mm ; /info1.result_flux_i_1mm
;; u_radec = grid1.map_u_1mm ; /info1.result_flux_i_1mm

;; Quicklook
imrange_i = [-1,1]*0.2
delvarx, imrange_i
imrange_p = [-1,1]*0.5*max( abs(q_nas))
xra = [-1,1]*70
yra = [-1,1]*70
;; Check absolute levels
wind, 1, 1, /free, /xlarge
my_multiplot, 3, 1, pp, pp1, /rev
imview, i_nas, xmap=grid1.xmap, ymap=grid1.ymap, xra=xra, yra=yra, $
        position=pp1[0,*], title='I nas (Jy/beam)', imrange=imrange_i
imview, q_nas, xmap=grid1.xmap, ymap=grid1.ymap, xra=xra, yra=yra, $
        position=pp1[1,*], title='Q nas (Jy/beam)', imrange=imrange_p, /noerase
imview, u_nas, xmap=grid1.xmap, ymap=grid1.ymap, xra=xra, yra=yra, $
        position=pp1[2,*], title='U nas (Jy/beam)', imrange=imrange_p, /noerase

;; Integrated on the beam
nk_grid2info, grid1, info, /edu, /noplot
print, ';; '+scan, info.result_flux_i_1mm, info.result_flux_q_1mm, info.result_flux_u_1mm, $
       sqrt( info.result_flux_q_1mm^2+info.result_flux_u_1mm^2)/info.result_flux_i_1mm
;; 20171124s252       44.416733      0.21230525     -0.36565245    0.0095193450

stop

;;------------------------------------------------------
;; Rotation from azel to nas: image
flip_azel_map, i_azel, i_map
flip_azel_map, q_azel, q_map
flip_azel_map, u_azel, u_map
elevation_deg = info_nasmyth.result_elevation_deg
elevation_rad = elevation_deg*!dtor
paral_rad = info_nasmyth.paral*!dtor
s = size(i_map)
nk_shear_rotate, i_map, s[1], s[2], elevation_deg, i_map
nk_shear_rotate, q_map, s[1], s[2], elevation_deg, q_map
nk_shear_rotate, u_map, s[1], s[2], elevation_deg, u_map
;; apply polar rotation (mind the sign of the POLARIZATION rotation
;; matrix compared to the "GEOGRAPHICAL" convention)

angle = -1.d0*elevation_rad
q =  q_map*cos(2*(angle-!dpi/4.)) + u_map*sin(2*(angle-!dpi/4.))
u = -q_map*sin(2*(angle-!dpi/4.)) + u_map*cos(2*(angle-!dpi/4.))
i_az2nas = i_map
q_az2nas = q
u_az2nas = u

;; quicklook
xra = [-1,1]*70
yra = [-1,1]*70
!mamdlib.coltable = 39
imrange_q = imrange_p/2.
imrange_u = imrange_p/2.
chars=0.7
wind, 2, 2, /free, /large
my_multiplot, 3, 3, pp, pp1, /rev
imview, i_nas, xra=xra, yra=yra, xmap=xmap, ymap=ymap, chars=chars, position=pp1[0,*], legend_text='I nas', imrange=imrange_i
imview, q_nas, xmap=xmap, ymap=ymap, xra=xra, yra=yra, chars=chars, position=pp1[1,*], $
        legend_text='Q nas', imrange=imrange_q, /noerase
imview, u_nas, xmap=xmap, ymap=ymap, xra=xra, yra=yra, chars=chars, position=pp1[2,*], $
        legend_text='U nas', imrange=imrange_u, /noerase
imview, i_az2nas, xra=xra, yra=yra, xmap=xmap, ymap=ymap, chars=chars, position=pp1[3,*], $
        legend_text='I az2nas (th)', imrange=imrange_i, /noerase
imview, q_az2nas, xmap=xmap, ymap=ymap, xra=xra, yra=yra, chars=chars, position=pp1[4,*],$
        legend_text='Q az2nas (th)', imrange=imrange_q, /noerase
imview, u_az2nas, xmap=xmap, ymap=ymap, xra=xra, yra=yra, chars=chars, position=pp1[5,*],$
        legend_text='U az2nas (th)', imrange=imrange_u, /noerase
imview, i_nas-i_az2nas, xra=xra, yra=yra, xmap=xmap, ymap=ymap, chars=chars, position=pp1[6,*], $
        legend_text='I nas - I az2nas', imrange=imrange_i, /noerase
imview, q_nas-q_az2nas, xmap=xmap, ymap=ymap, xra=xra, yra=yra, chars=chars, position=pp1[7,*],$
        legend_text='Q nas - Q az2nas', imrange=imrange_q, /noerase
imview, u_nas-u_az2nas, xmap=xmap, ymap=ymap, xra=xra, yra=yra, chars=chars, position=pp1[8,*],$
        legend_text='U nas - U az2nas', imrange=imrange_u, /noerase
message, /info, ""
message, /info, "pi/4 is only approximative at this stage"
message, /info, ""
stop

;; Check if any residual phase
phi_step = 5
phi_min = 0
phi_max = 180
nphi = round((phi_max-phi_min)/float(phi_step))
phi_list = dindgen(nphi)*phi_step + phi_min
iqu_res = dblarr(3,nphi)
grid_temp = grid1
grid_temp.map_i_1mm = i_az2nas
for i=0, nphi-1 do begin
   percent_status, i, nphi, 10
   phi = phi_list[i]
   q = q_az2nas*cos(2*phi*!dtor) - u_az2nas*sin(2*phi*!dtor)
   u = q_az2nas*sin(2*phi*!dtor) + u_az2nas*cos(2*phi*!dtor)
;;    imview, q_nas-q, xmap=xmap, ymap=ymap, xra=xra, yra=yra, position=pp1[0,*],$
;;            legend_text='Q nas - Qphi', imrange=imrange_p/5
;;    imview, u_nas-u, xmap=xmap, ymap=ymap, xra=xra, yra=yra, position=pp1[1,*],$
;;            legend_text='U nas - Uphi', imrange=imrange_p/5, /noerase
;;    print, phi
   grid_temp.map_q_1mm = q_nas-q
   grid_temp.map_u_1mm = u_nas-u
   nk_default_info, info
   nk_grid2info, grid_temp, info, /edu, /noplot
   iqu_res[0,i] = info.result_flux_i_1mm
   iqu_res[1,i] = info.result_flux_q_1mm
   iqu_res[2,i] = info.result_flux_u_1mm
endfor

pol_deg = sqrt(iqu_res[1,*]^2+iqu_res[2,*]^2)/iqu_res[0,*]

wind, 1, 1, /free, /large
my_multiplot, 2, 2, pp, pp1, /rev
plot, phi_list, iqu_res[0,*], /xs, position=pp1[0,*]
plot, phi_list, iqu_res[1,*], /xs, position=pp1[1,*], /noerase
plot, phi_list, iqu_res[2,*], /xs, position=pp1[2,*], /noerase
plot, phi_list, pol_deg, /xs, $
      position=pp1[3,*], /noerase, xtitle='phi (deg)', psym=-8, syms=0.5

;; Iterate around minimum to be more precise
w = where( pol_deg eq min(pol_deg))
phi_min = phi_list[w[0]] - 10
phi_max = phi_list[w[0]] + 10
phi_step = 0.5
nphi = round((phi_max-phi_min)/float(phi_step))
phi_list = dindgen(nphi)*phi_step + phi_min
iqu_res = dblarr(3,nphi)
grid_temp = grid1
grid_temp.map_i_1mm = i_az2nas
for i=0, nphi-1 do begin
   percent_status, i, nphi, 10
   phi = phi_list[i]
   q = q_az2nas*cos(2*phi*!dtor) - u_az2nas*sin(2*phi*!dtor)
   u = q_az2nas*sin(2*phi*!dtor) + u_az2nas*cos(2*phi*!dtor)
;;    imview, q_nas-q, xmap=xmap, ymap=ymap, xra=xra, yra=yra, position=pp1[0,*],$
;;            legend_text='Q nas - Qphi', imrange=imrange_p/5
;;    imview, u_nas-u, xmap=xmap, ymap=ymap, xra=xra, yra=yra, position=pp1[1,*],$
;;            legend_text='U nas - Uphi', imrange=imrange_p/5, /noerase
;;    print, phi
   grid_temp.map_q_1mm = q_nas-q
   grid_temp.map_u_1mm = u_nas-u
   nk_default_info, info
   nk_grid2info, grid_temp, info, /edu, /noplot
   iqu_res[0,i] = info.result_flux_i_1mm
   iqu_res[1,i] = info.result_flux_q_1mm
   iqu_res[2,i] = info.result_flux_u_1mm
endfor

pol_deg = sqrt(iqu_res[1,*]^2+iqu_res[2,*]^2)/iqu_res[0,*]
wind, 1, 1, /free, /large
outplot, file='lkg_int_pol_deg', png=png, ps=ps
plot, phi_list, pol_deg, /xs, $
      xtitle='phi (deg)', psym=-8, ytitle='Integrated Leakage pol. deg'
outplot, /close, /verb

w = where( pol_deg eq min(pol_deg))
phi0 = phi_list[w]

;; plot for Thursday June 28th, telecon
xra = [-1,1]*70
yra = [-1,1]*70
!mamdlib.coltable = 39
chars=0.7
wind, 2, 2, /free, /large
my_multiplot, 3, 3, pp, pp1, /rev
imview, i_nas, xmap=xmap, ymap=ymap, xra=xra, yra=yra, chars=chars, units='Jy/beam', $
        position=pp1[0,*], legend_text='I nas', imrange=imrange_i
imview, q_nas, xmap=xmap, ymap=ymap, xra=xra, yra=yra, chars=chars, units='Jy/beam', position=pp1[1,*], $
        legend_text='Q nas', imrange=imrange_q, /noerase
imview, u_nas, xmap=xmap, ymap=ymap, xra=xra, yra=yra, chars=chars, units='Jy/beam', position=pp1[2,*], $
        legend_text='U nas', imrange=imrange_u, /noerase
imview, i_azel, xmap=xmap, ymap=ymap, xra=xra, yra=yra, $
        chars=chars, units='Jy/beam', position=pp1[3,*], legend_text='I azel', imrange=imrange_i, /noerase
imview, q_azel, xmap=xmap, ymap=ymap, xra=xra, yra=yra, chars=chars, units='Jy/beam', position=pp1[4,*],$
        legend_text='Q azel', imrange=imrange_q, /noerase
imview, u_azel, xmap=xmap, ymap=ymap, xra=xra, yra=yra, chars=chars, units='Jy/beam', position=pp1[5,*],$
        legend_text='U azel', imrange=imrange_u, /noerase

imview, i_nas-i_az2nas, xmap=xmap, ymap=ymap, xra=xra, yra=yra, $
        chars=chars, units='Jy/beam', position=pp1[6,*], legend_text='I nas - I az2nas', $
        imrange=[-1,1]*max(abs(imrange_i))/100., /noerase, $
        title='phase '+string(phi,form='(F6.2)')+' deg'

phi = phi0[0] ; 14.5
q = q_az2nas*cos(2*phi*!dtor) - u_az2nas*sin(2*phi*!dtor)
u = q_az2nas*sin(2*phi*!dtor) + u_az2nas*cos(2*phi*!dtor)

imview, q_nas-q, xmap=xmap, ymap=ymap, xra=xra, yra=yra, chars=chars, units='Jy/beam', position=pp1[7,*],$
        legend_text='Q nas - Q az2nas', imrange=imrange_q/2., /noerase, $
        title='phase '+string(phi,form='(F6.2)')+' deg'
imview, u_nas-u, xmap=xmap, ymap=ymap, xra=xra, yra=yra, chars=chars, units='Jy/beam', position=pp1[8,*],$
        legend_text='U nas - U az2nas', imrange=imrange_u/2., /noerase, $
        title='phase '+string(phi,form='(F6.2)')+' deg'

end
