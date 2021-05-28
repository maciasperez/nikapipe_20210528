
;; With goods_scan_sim, we can see the approximate contours
;; Here, I play with the various parameters to optimize a bit better
;;-----------------------------------------------------------------

scan_model = 4
png        = 0 ;1
keep_results_file = 0 ;1
output_fits_file = 'W43_nika2cov.fits'

delvarx, scan_speed
y_speed = 100. ; 800. ; based on gaston speed between
mail = 0
force = 1 ;0 ; set to 1 to accept scans longer than 25min

scan_speed = 40.d0

case scan_model of


   1: begin
      nickname       = "W43_"+strtrim(scan_model,2)
      x_width        = 12*60.d0 ;40*60.d0 ; arcsec
      y_width        = 10*60.d0 ;25*60.d0 ; 60*60.d0 ; 6*60.d0  ;arcsec
      y_step         = 20.d0    ;30.d0    ;80.d0     ; arcsec
      n_subscans = round( y_width/y_step)
      angle_deg      = 90.d0
      ra_offset      = 0.5*60.d0   ;10.d0*60.d0  ;10.d0*60.d0 ; arcsec
      dec_offset     = -2.5*60.d0  ;1.d0*60.d0 ; arcsec
;;      scan_speed = 40.
   end

   2: begin
      nickname       = "W43_"+strtrim(scan_model,2)
      x_width        = 10*60.d0 ;10*60.d0 ;40*60.d0 ; arcsec
      y_width        = 12*60.d0 ;25*60.d0  ;arcsec
      y_step         = 20.d0    ;80.d0    ;30.d0     ; arcsec
      n_subscans = round( y_width/y_step)
      angle_deg      = 0.d0
      ra_offset      = 0.5*60.d0   ;10.d0*60.d0  ;10.d0*60.d0 ; arcsec
      dec_offset     = -2.5*60.d0  ;1.d0*60.d0 ; arcsec
;;      scan_speed = 40.
   end

   3: begin
      nickname       = "W43_"+strtrim(scan_model,2)
      x_width        = 10*60.d0 ;11*60.d0 ;40*60.d0 ; arcsec
      y_width        = 12*60.d0 ;25*60.d0 ; 60*60.d0 ; 6*60.d0  ;arcsec
      y_step         = 20.d0    ;80.d0 ;30.d0 ;60.d0    ; arcsec
      n_subscans = round( y_width/y_step)
      angle_deg      = 50.d0
      ra_offset      = 0.5*60.d0   ;10.d0*60.d0  ;10.d0*60.d0 ; arcsec
      dec_offset     = -2*60.d0  ;1.d0*60.d0 ; arcsec
;;      scan_speed = 40.
   end

   4: begin
      nickname       = "W43_"+strtrim(scan_model,2)
      x_width        = 12*60.d0 ;40*60.d0 ; arcsec
      y_width        = 11*60.d0 ;25*60.d0 ; 60*60.d0 ; 6*60.d0  ;arcsec
      y_step         = 20.d0    ;80.d0 ;30.d0 ;60.d0    ; arcsec
      n_subscans = round( y_width/y_step)
      angle_deg      = 140.d0
      ra_offset      = 1.d0*60.d0 ;0.5*60.d0   ;10.d0*60.d0  ;10.d0*60.d0 ; arcsec
      dec_offset     = -2.5*60.d0  ;1.d0*60.d0 ; arcsec
;;      scan_speed = 40.
   end


endcase

if not keyword_set(map_xsize) then map_xsize      = 1500         ; arcsec
coord_sys      = "RADEC"
if keyword_set(mail) then mail=1 else mail=0
if keyword_set(png) then png=1 else png=0
if keyword_set(ps) then ps=1 else ps=0
if (mail eq 1) and ( (ps eq 0) and (png eq 0)) then png=1

if not keyword_set(nickname) then nickname = 'test'

;; GOODSN goes up to 60 deg elevation and is 45 deg. from the az axis at transit
;; The speed limit of the telescope in azimuth is 60 arcsec/s at this elevation
;; Hence the maximum RA speed that we can consider is 60/cos(elev):
x_speed_max = 60./abs(cos(angle_deg*!dtor)) ; from the telescope contraint on azimuth speed

;;===========================================
nk_default_param, scan_params

;; scan_simulator assumes that the scans are in azel, so we need to
;; assume an elevation to rotate the Nasmyth offsets to azel.
;; This angle is arbitrary if the simulated scan is meant to be in RaDec
elevation_deg = 0.d0 ; 45.d0

n_subscans += 1                 ; tuning subscan that is not entirely thrown away ?

t_min_subscan = 10.             ; 10s projectable, i'll take margin later

if keyword_set(scan_speed) then begin
   x_speed = scan_speed < x_speed_max
endif else begin
   x_speed   = (x_width/t_min_subscan) < x_speed_max
endelse
t_subscan = x_width/x_speed

;; Quick estimate of overall parameters
t_tot = n_subscans*t_subscan + (n_subscans-1)*y_step/y_speed
if force eq 0 and t_tot ge (20*60.) then begin
   message, /info, "The estimated duration of this scan is "+strtrim(t_tot/60.,2)+" min"
   message, /info, "You should avoid scans larger than 20-25 min, both for tuning and scan processing"
   message, /info, "set force=1 to ignore this warning and relaunch"
   stop
endif

;; Sequence and output ascii files
fmt = "(F6.1)"
xsize_arcmin = x_width/60.
ysize_arcmin = n_subscans*y_step/60.
sequence = strtrim(string(xsize_arcmin,form=fmt),2)+" "+$
           strtrim(string(ysize_arcmin,form=fmt),2)+" "+strtrim( string(angle_deg[0],format=fmt),2)+" 0 "+$
           strtrim(string(y_step,form=fmt),2)+" "+strtrim(string(x_speed,form=fmt),2)+" radec"
   
;; Display parameters
scan_params.map_xsize = map_xsize
scan_params.map_ysize = scan_params.map_xsize
scan_params.map_reso = 2.d0 ; place holder, is overwritten by header later on
scan_params.map_proj = 'radec'
scan_params.project_white_noise_nefd = 1
scan_params = create_struct( scan_params, $
                             "coord_sys", coord_sys, $
                             "f_sampling", !nika.f_sampling, $
                             "n_subscans", n_subscans, $
                             "x_width", x_width, $
                             "x_speed", x_speed, $
                             "y_step", y_step, $
                             "y_speed", y_speed, $
                             "angle_deg", angle_deg[0], $
                             "x_offset",  ra_offset, $
                             "y_offset", dec_offset, $
                             "elevation_deg", elevation_deg)


;;=========================================
elev    = 40.*!dtor ; assumed in the proposal
tau_1mm = 0.158950
tau_2mm = 0.0894867

;; monr2 = mrdfits( !home+"/Projects/NIKA/NIKA2/MonR2/monr2_scuba2_850_261012.fits", 0, header)
junk = mrdfits( !nika.pipeline_dir+"/Scr/Reference/ScanSimulator/Data/w43_mambo.fits", 0, header_in)
junk *= 5/100. ;assume 5% polarization

;; Need to change the projection conventions
header = header_in
sxaddpar, header, 'ctype1', 'RA---TAN'
sxaddpar, header, 'ctype2', 'DEC--TAN'
w43 = mproj( junk, header_in, header)

wind, 1, 1, /free, /large
himview, w43, header, imr=[-0.1,40]

;; enlarge
header2 = header
reso = abs(sxpar( header, "cdelt1"))
nx = round(map_xsize/(reso*3600.))
sxaddpar, header2, "naxis1", nx
sxaddpar, header2, "naxis2", nx
sxaddpar, header2, "crpix1", nx/2
sxaddpar, header2, "crpix2", nx/2

w43 = mproj( w43, header, header2)
header = header2

;; wind, 2, 2, /free
;; himview, w43, header, imr=[-0.1, 40], chars=0.6
;stop

ra_center  = sxpar(header, "CRVAL1")
dec_center = sxpar(header, "CRVAL2")

;; Place holder, waiting for an actual list of sources
flux_1mm = dblarr(1)
name = ['dummy']
t_geom    = flux_1mm*0.d0
t_int_1mm = flux_1mm*0.d0
t_int_2mm = flux_1mm*0.d0
nsources = n_elements(name)
ra_deg   = dblarr(nsources)
dec_deg  = dblarr(nsources)

ra_deg[0]  = ra_center
dec_deg[0] = dec_center

;; Approx 3 sigma on a filament as a spec and approx 4-5 sigma as goal
sigma_spec_1mm = 1.   ;5/3. ;30./3 ; mJy
sigma_spec_2mm = 1.   ;5/3. ;30./3 ; mJy
sigma_goal_1mm = 3/5. ;1.d0 ;6.d0 ; mJy
sigma_goal_2mm = 3/5. ;1.d0 ;6.d0 ; mJy

;; Array NEFDs as of Sept. 28th, 2017
;; array_nefd = [63., 9., 46.]

;; NEFD polar
array_nefd = [30*sqrt(2),9.,30*sqrt(2)]

;; Sequence and output ascii files
;; Scan patterns
fmt = "(F6.1)"
outplot_file      = "plot_scan_estimator_"+nickname+"_"+strjoin( strsplit( sequence, " ", /reg, /extr), "_")
scan_results_file = "stat_scan_estimator_"+nickname+"_"+strjoin( strsplit( sequence, " ", /reg, /extr), "_")+".dat"
   
;; ;; Build the projection header
;; header = header_in
;; scale = 1.5
;; naxis1 = sxpar( header_in, "naxis1")
;; naxis2 = sxpar( header_in, "naxis2")
;; crpix1 = sxpar( header_in, "crpix1")
;; crpix2 = sxpar( header_in, "crpix2")
;; sxaddpar, header, "naxis1", long( naxis1*scale)
;; sxaddpar, header, "naxis2", long( naxis2*scale)
;; sxaddpar, header, "crpix1", crpix1 + long(naxis1*(scale-1)/2.)
;; sxaddpar, header, "crpix2", crpix2 + long(naxis2*(scale-1)/2.)

nk_default_info, info
info.longobj =  ra_center
info.latobj  = dec_center
nk_init_grid, scan_params, info, junk, astr=astr, header=header

ad2xy, ra_deg, dec_deg, astr, xsource, ysource

;; Loop on scans
nsn_tot = 0.d0
total_scan_time = 0.d0
nk_default_info, info
plot_ext = "scan_model_"+strtrim(scan_model,2)
delvarx, grid
scan_simulator, scan_params, array_nefd, scan_time, $
                ofs_x, ofs_y, dra, ddec, grid, kidpar, $
                info=info, data=data, $
                ofs_x_min=ofs_x_min, ofs_x_max=ofs_x_max, $
                ofs_y_min=ofs_y_min, ofs_y_max=ofs_y_max, nomaps=nomaps, $
                header=header

nsn = n_elements(data)
nsn_tot         += nsn
total_scan_time += scan_time

w = where( grid.nhits_1mm ne 0, nw)
area_cov_1mm = nw*(grid.map_reso/60.)^2
w = where( grid.nhits_2 ne 0, nw)
area_cov_2mm = nw*(grid.map_reso/60.)^2
ofs_ra  = ra_center+ofs_x/3600.d0/cos(dec_center*!dtor)
ofs_dec = dec_center+ofs_y/3600.d0
ad2xy, ofs_ra, ofs_dec, astr, x_fov, y_fov

;; Time spent on sources
for isource=0, nsources-1 do begin
   ix = round(xsource[isource])
   iy = round(ysource[isource])
   if ix ge 0 and ix lt grid.nx and $
      iy ge 0 and iy lt grid.ny then begin
      n1 = grid.nhits_1mm[ix,iy]
      n2 = grid.nhits_2[ix,iy]
      ;; factor 0.5 for the 1mm
      t1 = 0.5*n1/!nika.f_sampling*(!nika.grid_step[0]/grid.map_reso)^2
      t2 =     n2/!nika.f_sampling*(!nika.grid_step[1]/grid.map_reso)^2
      
      gcirc, 2., ra_deg[isource], dec_deg[isource], ofs_ra, ofs_dec, dist
      w = where( dist le 6.5*60./2.d0, nwgeom)
      t_geom[    isource] += nwgeom/!nika.f_sampling
      t_int_1mm[ isource] += t1
      t_int_2mm[ isource] += t2
   endif
endfor

;; Effective center of the covered area (not the same as the map
;; center)
ra_center_eff  =  ra_center + scan_params.x_offset/3600./cos(dec_center*!dtor)
dec_center_eff = dec_center + scan_params.y_offset/3600.
ad2xy, ra_center_eff, dec_center_eff, astr, x_center_eff, y_center_eff

;; Take a theoretical value not to be affected by the random realization of
;; scan_simulator at this stage
nefd_1mm = sqrt( 1./(1./array_nefd[0]^2 + 1./array_nefd[2]^2))/1000 ; Jy
time_map = grid.nhits_1mm/!nika.f_sampling*(!nika.grid_step[0]/grid.map_reso)^2
time_map /= 2. ; divide by two at 1mm !
;; smooth time_map for a nicer display
input_sigma_beam = !nika.fwhm_nom[0]*!fwhm2sigma
nextend          = 4                ; found necessary to define the background properly
nx_beam_w8       = 2*long(nextend*input_sigma_beam/grid.map_reso/2)+1
ny_beam_w8       = 2*long(nextend*input_sigma_beam/grid.map_reso/2)+1
xx               = dblarr(nx_beam_w8, ny_beam_w8)
yy               = dblarr(nx_beam_w8, ny_beam_w8)
for ii=0, nx_beam_w8-1 do xx[ii,*] = (ii-nx_beam_w8/2)*grid.map_reso
for ii=0, ny_beam_w8-1 do yy[*,ii] = (ii-ny_beam_w8/2)*grid.map_reso
beam_w8 = exp(-(xx^2+yy^2)/(2.*input_sigma_beam^2))
beam_w8 /= total(beam_w8)
time_map = convol( time_map, beam_w8)

map_sigma_1mm = time_map*0d0
w = where( time_map ne 0.)
map_sigma_1mm[w] = nefd_1mm/sqrt(time_map[w])
sigma_flux_center_1mm  = map_sigma_1mm[round(x_center_eff),round(y_center_eff)]
time_matrix_center_1mm = time_map[     round(x_center_eff),round(y_center_eff)]

w = where( grid.nhits_1mm eq 0, nw)
if nw ne 0 then map_sigma_1mm[w] = !values.d_nan

;; Take a theoretical value not to be affected by the random realization of
;; scan_simulator at this stage
nefd_2mm = array_nefd[1]/1000. ; Jy
time_map = grid.nhits_2/!nika.f_sampling*(!nika.grid_step[1]/grid.map_reso)^2
;; smooth time_map for a nicer display
input_sigma_beam = !nika.fwhm_nom[1]*!fwhm2sigma
nextend          = 5                ; found necessary to define the background properly
nx_beam_w8       = 2*long(nextend*input_sigma_beam/grid.map_reso/2)+1
ny_beam_w8       = 2*long(nextend*input_sigma_beam/grid.map_reso/2)+1
xx               = dblarr(nx_beam_w8, ny_beam_w8)
yy               = dblarr(nx_beam_w8, ny_beam_w8)
for ii=0, nx_beam_w8-1 do xx[ii,*] = (ii-nx_beam_w8/2)*grid.map_reso
for ii=0, ny_beam_w8-1 do yy[*,ii] = (ii-ny_beam_w8/2)*grid.map_reso
beam_w8 = exp(-(xx^2+yy^2)/(2.*input_sigma_beam^2))
beam_w8 /= total(beam_w8)
time_map = convol( time_map, beam_w8)

map_sigma_2mm = time_map*0d0
w = where( time_map ne 0.)
map_sigma_2mm[w] = nefd_2mm/sqrt(time_map[w])
sigma_flux_center_2mm  = map_sigma_2mm[round(x_center_eff),round(y_center_eff)]
time_matrix_center_2mm = time_map[     round(x_center_eff),round(y_center_eff)]

w = where( grid.nhits_2 eq 0, nw)
if nw ne 0 then map_sigma_2mm[w] = !values.d_nan

nscans_1mm_spec = (sigma_flux_center_1mm*1000./sigma_spec_1mm)^2
nscans_1mm_goal = (sigma_flux_center_1mm*1000./sigma_goal_1mm)^2
nscans_2mm_spec = (sigma_flux_center_2mm*1000./sigma_spec_2mm)^2
nscans_2mm_goal = (sigma_flux_center_2mm*1000./sigma_goal_2mm)^2

fmt = "(F5.2)"
openw, lu, scan_results_file, /get_lun
printf, lu, "# Name, SigmaFlux1 (mJy), SigmaFlux2 (mJy), t_int_1mm (s), t_int_2mm (s), t_geom_frac_1mm"
for isource=0, nsources-1 do begin
   ix = round(xsource[isource])
   iy = round(ysource[isource])
   if ix ge 0 and ix lt grid.nx and $
      iy ge 0 and iy lt grid.ny then begin
      n1 = grid.nhits_1mm[ix,iy]
      n2 = grid.nhits_2[ix,iy]
      ;; factor 0.5 for the 1mm
      t1 = 0.5*n1/!nika.f_sampling*(!nika.grid_step[0]/grid.map_reso)^2
      t2 =     n2/!nika.f_sampling*(!nika.grid_step[1]/grid.map_reso)^2
      
      gcirc, 2., ra_deg[isource], dec_deg[isource], ofs_ra, ofs_dec, dist
      w = where( dist le 6.5*60./2.d0, nwgeom)
      s1 = map_sigma_1mm[ix,iy]*1000.
      s2 = map_sigma_2mm[ix,iy]*1000.
   endif else begin
      s1 = "NaN"
      s2 = "NaN"
   endelse
   printf, lu, name[isource]+", "+$
           string( s1, form=fmt)+", "+$
           string( s2, form=fmt)+", "+$
           string( t_int_1mm[isource], form='(F7.2)')+", "+$
           string( t_int_2mm[isource], form='(F7.2)')+", "+$
           string( float(t_geom[isource])/(nsn_tot/!nika.f_sampling), form='(F4.2)')
endfor

printf, lu, ""
printf, lu, "x_speed: "+string(scan_params.x_speed,format=fmt)+" arcsec/s"
printf, lu, "x subscan duration (sec): "+string(t_subscan,format=fmt)
printf, lu, "N subscans: ", n_subscans
printf, lu, "Covered area (arcmin^2): "+string( area_cov_1mm, form='(F6.2)')+', '+string( area_cov_2mm,form='(F6.2)')
printf, lu, "Total scan duration (min): ", string(total_scan_time/60.,form=fmt)
printf, lu, "Sensitivity at the center 1mm and 2mm (mJy): "+$
        string( sigma_flux_center_1mm*1000., form=fmt)+", "+$
        string( sigma_flux_center_2mm*1000., form=fmt)
printf, lu, "Recov zenith nefd at the center 1mm and 2mm (mJy): "+$
        string( sigma_flux_center_1mm*1000.*sqrt(time_matrix_center_1mm), form=fmt)+", "+$
        string( sigma_flux_center_2mm*1000.*sqrt(time_matrix_center_2mm), form=fmt)

printf, lu, ""

nscans_1mm_spec_tau_elev = nscans_1mm_spec*exp(2*tau_1mm/sin(elev))
nscans_1mm_goal_tau_elev = nscans_1mm_goal*exp(2*tau_1mm/sin(elev))
nscans_2mm_spec_tau_elev = nscans_2mm_spec*exp(2*tau_2mm/sin(elev))
nscans_2mm_goal_tau_elev = nscans_2mm_goal*exp(2*tau_2mm/sin(elev))

time_1mm_spec          = nscans_1mm_spec*total_scan_time/3600.d0
time_2mm_spec          = nscans_2mm_spec*total_scan_time/3600.d0
time_1mm_spec_tau_elev = nscans_1mm_spec_tau_elev*total_scan_time/3600.d0
time_2mm_spec_tau_elev = nscans_2mm_spec_tau_elev*total_scan_time/3600.d0

time_1mm_goal          = nscans_1mm_goal*total_scan_time/3600.d0
time_2mm_goal          = nscans_2mm_goal*total_scan_time/3600.d0
time_1mm_goal_tau_elev = nscans_1mm_goal_tau_elev*total_scan_time/3600.d0
time_2mm_goal_tau_elev = nscans_2mm_goal_tau_elev*total_scan_time/3600.d0

printf, lu, "Nscans to reach target 1mm: "
printf, lu, "No Tau spec 3sigma, No Tau goal 5sigma: "+$
        string( nscans_1mm_spec, form="(F6.1)")+", "+$
        string( nscans_1mm_goal, form="(F6.1)")+", "
printf, lu, "TauElev spec 3sigma, TauElev goal 5 sigma: "+$
        string( nscans_1mm_spec_tau_elev, form="(F6.1)")+", "+$
        string( nscans_1mm_goal_tau_elev, form="(F6.1)")
        
printf, lu, "Nscans to reach target 2mm:"
printf, lu, "No Tau spec 3sigma, No Tau goal 5sigma: "+$
        string( nscans_2mm_spec, form="(F6.1)")+", "+$
        string( nscans_2mm_goal, form="(F6.1)")
printf, lu, "TauElev spec 3sigma, TauElev goal 5 sigma: "+$
        string( nscans_2mm_spec_tau_elev, form="(F6.1)")+", "+$
        string( nscans_2mm_goal_tau_elev, form="(F6.1)")

printf, lu, ""
printf, lu, "Total obs. time required 1mm [hours]: "
printf, lu, "No Tau spec 3sigma, No Tau goal 5sigma: "+$
        string( time_1mm_spec, form="(F6.1)")+", "+$
        string(     time_1mm_goal, form="(F6.1)")

printf, lu, "TauElev spec 3sigma, TauElev goal 5 sigma: "+$
        string( time_1mm_spec_tau_elev, form="(F6.1)")+", "+$
        string( time_1mm_goal_tau_elev, form="(F6.1)")

printf, lu, "Total obs. time required 2mm [hours]:"
printf, lu, " No Tau spec 3sigma, No Tau goal 5sigma: "+$
        string( time_2mm_spec, form="(F6.1)")+", "+$                                                                                       
        string( time_2mm_spec_tau_elev, form="(F6.1)")
printf, lu, "TauElev spec 3sigma, TauElev goal 5 sigma: "+$
        string( time_2mm_goal, form="(F6.1)")+", "+$
        string( time_2mm_goal_tau_elev, form="(F6.1)")

close, lu
free_lun, lu

;; Display maps
colt    = 39
col_fov = 100
r_fov = 6.5/2.*60 ; arcsec
phi = dindgen(360)/360.*2*!dpi

imrange_1mm = [0,1]*0.1
imrange_2mm = [0,1]*0.03
c_col   = 40 ; 200
c_thick = 1 ; 2
speed = sqrt( deriv(dra[0,*])^2 + deriv(ddec[0,*])^2)
ws = where( abs(speed-median(speed)) lt 0.05*median(speed), compl=wflag)
speedok = intarr(nsn_tot)
speedok[ws]=1

;; Scale the current sensitivity map by its required nscans to reach
;; the spec. Then we can compare different scanning strategies to the
;; final absolute sensitivities
map_sigma_1mm = map_sigma_1mm/sqrt(nscans_1mm_spec)*1000 ; mJy

imrange_1mm = [0, 6*sigma_spec_1mm]
charsize=0.7
if ps eq 0 then wind, 1, 1, /free, /large
outplot, file=outplot_file, png=png, ps=ps
my_multiplot, 2, 1, pp, pp1, /rev, ymax=0.5, xmax=0.7
himview, map_sigma_1mm, header, $
;delvarx, imrange_1mm
;himview, cosmos, header, $
         title='Sigma Beam 1mm', $
         units='mJy', colt=colt, $
         imrange=imrange_1mm, position=pp[0,0,*], charsize=charsize, /black, $
         outposition=outposition
for i=min(data.subscan), max(data.subscan) do begin
   w = where( data.subscan eq i and speedok eq 1, nw)
   oplot, x_fov[w[0]]    + r_fov*cos(phi)/grid.map_reso, y_fov[w[0]]    + r_fov*sin(phi)/grid.map_reso, col=col_fov
   oplot, x_fov[w[nw-1]] + r_fov*cos(phi)/grid.map_reso, y_fov[w[nw-1]] + r_fov*sin(phi)/grid.map_reso, col=col_fov
endfor
oplot, [x_center_eff], [y_center_eff], psym=7, col=100
xy2ad, ofs_x, ofs_y, astr, a, d
oplot, a, d, col=100

;; Sensitivity maps with sensitivity contours normalized to the sensitivity at
;; the center
;himview, map_sigma_1mm, header, $
imrange_1mm = [-0.1,40]
himview, w43, header, $
         title='Sigma Beam 1mm', outposition=outposition, /noerase, $
         position=pp[1,0,*], units='mJy', colt=colt, charsize=charsize, $
         imrange=imrange_1mm
my_imcontour, map_sigma_1mm/sigma_spec_1mm, $
              header, /type, /noerase, charsize=charsize, $
              levels=[1.1, 2, 3], position=outposition, col=250
;; ;; Scan pattern
;; w = where( kidpar.type eq 1 and sqrt(kidpar.nas_x^2+kidpar.nas_y^2) le 10., nw)
;; kref = w[0]
;; ad2xy, ra_center + dra[kref,*]/3600.d0, dec_center + ddec[kref,*]/3600.d0, astr, x, y
;; oplot, x, y, col=100

dy = 0.025
xx = 0.02
yy = 0.90
chars=0.8
xyouts, xx, yy+2*dy, /norm, chars=chars, 'Scan model '+strtrim(scan_model,2)
xyouts, xx, yy+dy,   /norm, chars=chars, "speed: "+string(   scan_params.x_speed,form='(F5.2)')+" arcsec/s"
xyouts, xx, yy,      /norm, chars=chars, "x width: "+string( scan_params.x_width/60.,form='(F4.1)')+" arcmin"
xyouts, xx, yy-dy,   /norm, chars=chars, "y width: "+string( y_width/60.,form='(F4.1)')+" arcmin"
xyouts, xx, yy-2*dy, /norm, chars=chars, "angle: "+string(   scan_params.angle_deg[0],form='(F6.1)')+" deg"
xyouts, xx, yy-3*dy, /norm, chars=chars, "Ystep: "+string( y_step, form='(F6.2)')+" arcsec"
xyouts, xx, yy-4*dy, /norm, chars=chars, "Nsubscans: "+string( n_subscans, form='(F5.1)')
xyouts, xx, yy-5*dy, /norm, chars=chars, "Total obs area (arcmin^2 at 1mm): "+$
        string( area_cov_1mm,form='(F7.1)')+" arcmin^2"
xyouts, xx, yy-6*dy, /norm, chars=chars, "Total obs area (deg^2 at 1mm): "+$
        string( area_cov_1mm/3600.,form='(F5.3)')+" deg^2"
xyouts, xx, yy-7*dy, /norm, chars=chars, "t_subscan: "+string( t_subscan, form='(F5.1)')+" s"
xyouts, xx, yy-8*dy, /norm, chars=chars, "Scan duration: "+string(total_scan_time/60.,form='(F5.2)')+" mn"
xyouts, xx, yy-9*dy, /norm, chars=chars, "NEFD (1 and 2mm): "+$
        string( sqrt(1.d0/(1.d0/array_nefd[0]^2+1.d0/array_nefd[2]^2)),form='(F4.1)')+", "+$
        string(array_nefd[1],form='(I2.2)')
xyouts, xx, yy-10*dy, /norm, chars=chars, "Tau (1 and 2mm): "+$
        string(tau_1mm,form='(F4.2)')+", "+string(tau_2mm,form='(F4.2)')
xyouts, xx, yy-11*dy, /norm, chars=chars, "Assumed elevation: "+string(elev*!radeg,form='(I2.2)')+" deg"
xyouts, xx, yy-12*dy, /norm, chars=chars, "Assumed inter subscan speed: "+string(y_speed,form='(F6.2)')+" arcsec/s"
xyouts, xx, yy-13*dy, /norm, chars=chars, "Req. 1mm [hours] (spec/goal): "+$
        string( time_1mm_spec_tau_elev, form="(F7.2)")+", "+$
        string( time_1mm_goal_tau_elev, form="(F7.2)")
xyouts, xx, yy-14*dy, /norm, chars=chars, "Req. 2mm [hours] (spec/goal): "+$
        string( time_2mm_spec_tau_elev, form="(F7.2)")+", "+$
        string( time_2mm_goal_tau_elev, form="(F7.2)")

;; Surface vs sensitivity
position = [0.4, 0.7, 0.62, 0.95]
w = where( finite(map_sigma_1mm) eq 1, nw)
w_in_3 = where( map_sigma_1mm ne 0 and $
                map_sigma_1mm le 3*sigma_spec_1mm, nw_in_3)
w_in_1 = where( map_sigma_1mm ne 0 and $
                map_sigma_1mm le 1*sigma_spec_1mm, nw_in_1)
np_histo, map_sigma_1mm[w], xhist, yhist, $
          bin=sigma_spec_1mm/2., /noplot
plot, xhist, yhist*(grid.map_reso/60.)^2, position=position, /noerase, $
      xtitle='Flux error mJy (1mm)', ytitle='Surf (arcmin!u2!n)', psym=10, $
      xra=[0, 10*sigma_spec_1mm], /xs
oplot, [1,1]*sigma_spec_1mm, [-1,1]*1e10, col=70
oplot, [1,1]*sigma_goal_1mm, [-1,1]*1e10, col=250
legendastro, ['Spec', 'Goal'], textcol=[70,250], /right, chars=0.7

position = [0.7, 0.7, 0.95, 0.95]
plot, xhist, total(yhist, /cumul)*(grid.map_reso/60.)^2, /nodata, $
      position=position, xtitle='Flux error mJy (1mm)', ytitle='Cumul Surf (arcmin!u2!n)', $
      psym=10, xra=[0, 10*sigma_spec_1mm], /xs, /noerase
oplot, xhist, total(yhist, /cumul)*(grid.map_reso/60.)^2, col=250, psym=10
oplot, [1,1]*sigma_spec_1mm, [-1,1]*1e10, col=70
oplot, [1,1]*sigma_goal_1mm, [-1,1]*1e10, col=150
legendastro, ['Spec', 'Goal'], textcol=[70,150], /right, chars=0.7

position = [0.7, 0.4, 0.95, 0.65]
w = where( finite(map_sigma_2mm) eq 1, nw)
w_in_3 = where( map_sigma_2mm ne 0 and $
                map_sigma_2mm le 3*sigma_spec_2mm, nw_in_3)
w_in_1 = where( map_sigma_2mm ne 0 and $
                map_sigma_2mm le 1*sigma_spec_2mm, nw_in_1)
np_histo, map_sigma_2mm[w], xhist, yhist, $
          bin=stddev(map_sigma_2mm[w])/3., /noplot
plot, xhist, total(yhist, /cumul)*(grid.map_reso/60.)^2, /nodata, $
      position=position, xtitle='Flux error mJy (2mm)', ytitle='Cumul Surf (arcmin!u2!n)', $
      psym=10, xra=[0, 5*sigma_spec_2mm], /xs, /noerase
oplot, xhist, total(yhist, /cumul)*(grid.map_reso/60.)^2, col=250, psym=10
oplot, [1,1]*sigma_spec_2mm, [-1,1]*1e10, col=70
oplot, [1,1]*sigma_goal_2mm, [-1,1]*1e10, col=150
legendastro, ['Spec', 'Goal'], textcol=[70,150], /right, chars=0.7

;xyouts, 0.4, 0.95, plot_title, /norm
outplot, /close
;; spawn, "mv "+outplot_file+".png scan_estim_"+nickname+".png"
if png eq 1 then spawn, "\cp "+outplot_file+".png scan_estim_"+nickname+".png"

print, ""
print, ""
spawn, "cat "+scan_results_file
if mail eq 1 then begin
   if png eq 1 then attach_file = "scan_estim_"+nickname+".png"
   if ps eq 1 then attach_file = "scan_estim_"+nickname+".eps"
   exitmail, message=nickname, attach=attach_file
endif

if keep_results_file lt 1 then spawn, "rm -f "+scan_results_file

if keyword_set(output_fits_file) then begin
   grid.map_i_1mm = map_sigma_1mm
   grid.map_i2 = map_sigma_2mm
   nk_map2fits_3, scan_params, info, grid, output_fits_file=output_fits_file, header=header
endif

six_ra_center  = sixty( (ra_center+ra_offset/3600.d0)/15.d0)
six_dec_center = sixty( dec_center+dec_offset/3600.d0)

print, "ra_offset : ", ra_offset
print, "dec_offset: ", dec_offset
print, "*********************************************************************"
print, "********** Effective target source should therefore be: *************"
print, "RA: "+$
       strtrim( long(six_ra_center[0]),2)+":"+$
       strtrim( long(six_ra_center[1]),2)+":"+$
       string( six_ra_center[2],form='(F6.3)')
print, "Dec: "+$
       strtrim( long(six_dec_center[0]),2)+":"+$
       strtrim( long(six_dec_center[1]),2)+":"+$
       string( six_dec_center[2],form='(F6.3)')

;; tried @nkotf 11.0 6.3 45.0 0 20.0 55.0 radec in pako (dosubmit no)
;; estimated scan time : 4.9 min
print, ""
print, "pako sequence: @nkotf "+sequence



exit:
end
