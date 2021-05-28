

pro scan_simulator, scan_params, array_nefd, scan_obs_time, $
                    ofs_x, ofs_y, $
                    dra, ddec, $
                    grid, kidpar, $
                    ra_source=ra_source, dec_source=dec_source, $
                    kidpar_file=kidpar_file, $
                    info=info, data=data, $
                    ofs_x_min=ofs_x_min, ofs_x_max=ofs_x_max, $
                    ofs_y_min=ofs_y_min, ofs_y_max=ofs_y_max, nomaps=nomaps, $
                    header_in=header_in, time_inter_subscan=time_inter_subscan;, astr=astr

if keyword_set(header_in) then begin
   header = header_in
   if not keyword_set( ra_source) then  ra_source = sxpar(header,"crval1")
   if not keyword_set(dec_source) then dec_source = sxpar(header,"crval2")
endif

nk_default_info, info

if not keyword_set(kidpar_file) then begin
   ;; Then take the most recent one
   julday = systime( 0, /julian)
   caldat, julday, month, day, year
   myscan = string(year,format="(I4.4)")+string(month,format="(I2.2)")+string(day,"(I2.2)")+"s1"
   nk_get_kidpar_ref, 1, day, info, kidpar_file, scan=myscan
endif
kidpar = mrdfits( kidpar_file, 1)

;; hack param to produce the input simulated grid
;; nk_default_param, simpar
;;nk_init_grid, scan_params, info, grid, header=header
extast, header, astr
nk_init_grid_2, scan_params, info, grid, astr=astr

;; time between two subscans (not realistic if the speed is too high and ystep
;; too small
;; time_inter_subscan = scan_params.y_step/scan_params.y_speed
if not keyword_set(time_inter_subscan) then time_inter_subscan = 2.d0 ; sec

scan_params.y_speed = scan_params.y_step/time_inter_subscan

;; Scanning strategy
y_min                     = -scan_params.n_subscans/2*scan_params.y_step
n_samples_per_subscan     = round(scan_params.x_width/scan_params.x_speed*scan_params.f_sampling)
n_sample_per_intersubscan = round(scan_params.y_step/scan_params.y_speed*scan_params.f_sampling)
nsn                       = scan_params.n_subscans*n_samples_per_subscan + $
                            n_sample_per_intersubscan*(scan_params.n_subscans-1)
ofs_x                     = dblarr(nsn)
ofs_y                     = dblarr(nsn)
scan_obs_time             = nsn/scan_params.f_sampling + (scan_params.n_subscans-1)*time_inter_subscan

;; Compute pointing offsets of the FOV center w.r.t the target
;; coordinates
subscan = intarr(nsn)
n_samples_per_subscan_eff = n_samples_per_subscan + n_sample_per_intersubscan
for i=0, scan_params.n_subscans-1 do begin

   i_scan_start = i*n_samples_per_subscan_eff
   i_scan_end   = i_scan_start + n_samples_per_subscan - 1
   
   ;; All subscans but the last one include the transition to the next subscan
   if i lt (scan_params.n_subscans-1) then begin
      subscan[i*n_samples_per_subscan_eff: (i+1)*n_samples_per_subscan_eff-1] = i

      ;; Scan in x
      ofs_x[i_scan_start:i_scan_end] = $
         (-1)^(i+1)*scan_params.x_width/2.d0 + (-1)^(i)*dindgen( n_samples_per_subscan)/scan_params.f_sampling*scan_params.x_speed
      ;; stay at the end of the subscan
      ofs_x[i_scan_end+1:(i_scan_end+1)+n_sample_per_intersubscan-1] = ofs_x[i_scan_end]

      ;; Constant elevation during scan
      ofs_y[i_scan_start:i_scan_end] = y_min + i*scan_params.y_step
      ;; Elevation step at the end
      ofs_y[i_scan_end+1:(i_scan_end+1)+n_sample_per_intersubscan-1] = $
         ofs_y[i_scan_end]+dindgen(n_sample_per_intersubscan)/scan_params.f_sampling*scan_params.y_speed
   endif else begin
      subscan[i_scan_start:i_scan_end] = i
      ;; Scan in x
      ofs_x[i_scan_start:i_scan_end] = $
         (-1)^(i+1)*scan_params.x_width/2.d0 + (-1)^(i)*dindgen( n_samples_per_subscan)/scan_params.f_sampling*scan_params.x_speed
      ;; Constant elevation during scan
      ofs_y[i_scan_start:i_scan_end] = y_min + i*scan_params.y_step
   endelse
endfor
   
;; Account for an angle if requested
;; The sign in front of the sin is to match PAKO's convention in radec
x     =  cos(scan_params.angle_deg*!dtor)*ofs_x + sin(scan_params.angle_deg*!dtor)*ofs_y
ofs_y = -sin(scan_params.angle_deg*!dtor)*ofs_x + cos(scan_params.angle_deg*!dtor)*ofs_y
ofs_x = temporary(x)

;; Account for an offset if requested
ofs_y += scan_params.y_offset
ofs_x += scan_params.x_offset

;; Compute pointing per kid and project
nkids = n_elements(kidpar)
ofs_x_min = min(ofs_x)
ofs_x_max = max(ofs_x)
ofs_y_min = min(ofs_y)
ofs_y_max = max(ofs_y)

;; get_kid_pointing
;; I use a rotation by elevation to simulate by default a scan in
;; azel.
;; It can be viewed as a radec scan though, but then the "alpha"
;; rotation of the focal plane is arbitrary.
;; To simulate a true radec scan on a source, one would need to
;; simulate also the exact LST and date of obs... TBD in the next version.
alpha = dblarr(nsn) + alpha_nasmyth( scan_params.elevation_deg*!dtor)
dx    = kidpar.nas_x - kidpar.nas_center_x
dy    = kidpar.nas_y - kidpar.nas_center_y
daz   = cos(alpha)##dx - sin(alpha)##dy
del   = sin(alpha)##dx + cos(alpha)##dy
dra   = -daz + ofs_x##( dblarr(nkids)+1)
ddec  = -del + ofs_y##( dblarr(nkids)+1)

;; ;; get_ipix
;; wkill = where( finite(dra) eq 0 or finite(ddec) eq 0, nwkill)
;; ix    = (dra  - grid.xmin)/grid.map_reso
;; iy    = (ddec - grid.ymin)/grid.map_reso
;; if nwkill ne 0 then begin
;;    ix[wkill] = -1
;;    iy[wkill] = -1
;; endif
;; ipix_all = double( long(ix) + long(iy)*grid.nx)
;; w = where( long(ix) lt 0 or long(ix) gt (grid.nx-1) or $
;;            long(iy) lt 0 or long(iy) gt (grid.ny-1), nw)
;; if nw ne 0 then ipix_all[w] = -1

;; from nk_get_ipix:
;; 1. dra has been corrected for the cos(dec) to have orthonormal
;; xmap and ymap by default. But adx2y requires true ra and dec, so
;; I need to back correct.
;; 2. the opposite sign convention in dra noted in nk_get_ipix is not relevant
;; here in this simulation, it's just internal to NIKA data and offsets conventions

dec = dec_source + ddec/3600.d0
ra  =  ra_source + dra/3600.d0/cos(dec_source*!dtor)
extast, header, astr
ad2xy, ra, dec, astr, x, y
ix = floor(x)
iy = floor(y)
ipix_all = double( ix + iy*grid.nx)
w = where( x lt 0 or x gt (grid.nx-1) or $
           y lt 0 or y gt (grid.ny-1), nw)
if nw ne 0 then ipix_all[w] = -1

;; Produce fake timelines and project maps
if keyword_set(nomaps) then begin
endif else begin
   w1 = where( kidpar.type eq 1, nw1)
   kidpar1 = kidpar[w1]
   data = {toi:dblarr(nw1) + 1.d0, $
           ipix:dblarr(nw1), $
           w8:dblarr(nw1) + 1.d0, $
           flag:dblarr(nw1), $
          subscan:0}
   data = replicate( data, n_elements(ofs_x))
   data.ipix = ipix_all[w1,*]
   data.subscan = subscan

   ;; scan_params.project_white_noise_nefd has been set to 1
   scan_params.do_plot = 0
   nk_projection_4, scan_params, info, data, kidpar1, grid
endelse

end
