
;; Produces a structure data and a kidpar ready to be processed by the pipeline

;; param, data, kidpar : traiditionnal pipeline parameters
;; ps : structure specific to the polarization simulation
;; test_toi : structure with some relevant timelines for the pipeline development
;;================================================================================

pro nika_sim_polar_data, param, data, kidpar, ps, test_toi, $
                         maps_S0, maps_S1, maps_S2, $
                         xmap, ymap

init_polar_simu_struct, ps

;;=======================================================================
;;========================== General and type of simu ===================
;;=======================================================================
ps.gen.simu_name = "Simu"
ps.gen.version   = 1

ps.sky.t_ampl           = 1            ; set to 0 if no Temperature in input (S0=0)
ps.sky.p_ampl           = 1            ; set to 0 if no Polarization in input (S1=S2=0)

;; Which band ?
two_mm_only = 0
one_mm_only = 1

;; Output directory for plots and logbook
ps.gen.output_dir = !nika.plot_dir+"/Polar/"+ps.gen.simu_name
spawn, "mkdir -p "+ps.gen.output_dir

;; Add 1/f or not
ps.gen.add_one_over_f = 1

;; Add sky noise or not
ps.gen.add_sky_noise = 0

;; Add template or not
ps.gen.add_template = 1

;;=======================================================================
;;========================== Type of scan ===============================
;;=======================================================================

;; OTF_geometry
ps.gen.scan_num = 146
ps.gen.day      = '20130612'

ps.gen.real_scan  = 0               ; set to 1 to use the actual scan, to 0 to simulate a scan

;; If the scan is simulated, here are the parameters:
ps.scan.az_speed   = 37.d0           ; nominal is 37 arcsec/s
ps.scan.n_subscans = 57              ; nominal is 57
ps.scan.el_step    = 3.88            ; nominal is 3.88 arcsec

;; Init param structure
nika_pipe_default_param, ps.gen.scan_num, ps.gen.day, param        ;Take the analysis param
param.output_dir     = ps.gen.output_dir
param.map.reso       = 3.d0     ; arcsec
param.map.size_ra    = 300.d0   ; arcsec
param.map.size_dec   = 300.d0   ; arcsec

;;=======================================================================
;;=========================== Input sky =================================
;;=======================================================================

;; Power law, constant polarization
ps.sky.source        = "dust"
ps.sky.diffuse_index = -3
ps.sky.pol_deg       = 0.1
ps.sky.alpha_pol     = 20.*!dtor
ps.sky.random_pol    = 0
ps.sky.reso_map      = 3.d0 ; 1.d0
ps.sky.n_unpol_ps    = 5
ps.sky.ps_flux = 10.d0

ps.sky.n_pol_ps   = 3
ps.sky.pol_deg_ps = 0.1

;; CMB

;; Crab

;; Planet

;;=======================================================================
;;============ Instrument parameters to overwrite kidpar etc... =========
;;=======================================================================
ps.instr.fwhm_2mm = 17.d0                ; arcsec
ps.instr.fwhm_1mm = 12.d0                ; arcsec

ps.hwp.nu_rot      = 2.d0                   ; hwp rotation frequency [Hz]
ps.gen.nu_sampling = round( 8.*4.*ps.hwp.nu_rot) ; timelines sampling [Hz]

;; HWP
ps.hwp.jones[0,0] =  1.0d0         ; perfect for now
ps.hwp.jones[1,1] = -1.0d0         ; perfect for now

;; Splitting grid
ps.grid.jones[0,0] = 1.d0 ; perfect for now

;;================================================================================
;;============================= Atmosphere parameters ============================
;;================================================================================
ps.sky_noise.h_cloud        = 3000.          ; meters above the Telescope
ps.sky_noise.atm_alpha      = 11./3./2       ; See Xavier's value in Diabolo/Simu...
ps.sky_noise.cloud_vx       = 1.             ; m.s^-1
ps.sky_noise.cloud_vy       = 1.             ; m.s^-1
ps.sky_noise.cloud_map_reso = 1.             ; m
ps.sky_noise.disk_convolve  = 1              ; convolve by the primary diameter
ps.sky_noise.atm_amplitude  = 1e-3           ; relative to the simulated signal

;;================================================================================
;;============================= Electronic noise =================================
;;================================================================================
;; partial_simu_elec
;; param.atmo.F_0 et param.atmo.F_el

;;========================================================================================================================
;;========================================================================================================================
;;                                             START
;;========================================================================================================================
;;========================================================================================================================

;; Get data to retrieve realistic pointing and kid configuration
nika_pipe_getdata, param, data0, kidpar, /nocut, one_mm_only=one_mm_only, two_mm_only=two_mm_only

;; discard beginning and end of scans
data0 = data0[where(data0.subscan ge 1)]

;; Init useful arrays and quantities
nsn0   = n_elements(data0)
time0  = dindgen( nsn0)/!nika.f_sampling ; original sampling                                                                                    
tmax   = max(time0)
tmin   = min(time0)
nkids  = n_elements( kidpar)
w1     = where( kidpar.type eq 1, nw1)
az_min = min( data0.ofs_az)
az_max = max( data0.ofs_az)
el_min = min( data0.ofs_el)

;; Force all kids to the same beam for now
wa = where( kidpar.array eq 1, nwa)
wb = where( kidpar.array eq 2, nwb)
if nwa ne 0 then begin
   kidpar[wa].fwhm_x = ps.instr.fwhm_1mm
   kidpar[wa].fwhm_y = ps.instr.fwhm_1mm
   kidpar[wa].fwhm   = ps.instr.fwhm_1mm
endif
if nwb ne 0 then begin
   kidpar[wb].fwhm_x = ps.instr.fwhm_2mm
   kidpar[wb].fwhm_y = ps.instr.fwhm_2mm
   kidpar[wb].fwhm   = ps.instr.fwhm_2mm
endif

;; Create input maps (signal and coordinates) at upgraded resolution
param1 = param
param1.map.reso = ps.sky.reso_map
nika_pipe_xymaps, param1, data0, kidpar, xmap, ymap, nx, ny, xmin, ymin
ps.sky.nx   = nx
ps.sky.ny   = ny
ps.sky.xmin = xmin
ps.sky.ymin = ymin
nika_pipe_simu_polar_maps, ps, maps_S0, maps_S1, maps_S2

;; ;;*****************
;; ;;*****************
;; ; To test point sources
;; maps_s0 = maps_s0*0.d0
;; maps_s1 = maps_s0*0.d0
;; maps_s2 = maps_s0*0.d0
;; print, ""
;; print, "Cancelling diffuse emission..."
;; stop
;; ;;*****************
;; ;;*****************

;; Point sources
n_sources = ps.sky.n_unpol_ps+ps.sky.n_pol_ps ; for convenience
if n_sources ne 0 then begin
   ps_ra        = randomu( seed, n_sources)*(max(xmap)-min(xmap)) + xmin
   ps_dec       = randomu( seed, n_sources)*(max(ymap)-min(ymap)) + ymin

   ;; Default, all unpolarized sources
   ps_pol_deg   = dblarr( n_sources)
   ps_alpha_rad = dblarr( n_sources)

   ;; Init the polarized ones
   if ps.sky.n_pol_ps ne 0 then begin
      ps_pol_deg[   0:ps.sky.n_pol_ps-1] = ps.sky.pol_deg_ps
      ps_alpha_rad[ 0:ps.sky.n_pol_ps-1] = randomu( seed, ps.sky.n_pol_ps)*!dpi
   endif
endif

;; Generate scan
if ps.gen.real_scan eq 0 then begin
   fake_otf_scan, ps.gen.nu_sampling, az_min, az_max, $
                  ps.scan.az_speed, ps.scan.n_subscans, $
                  el_min, ps.scan.el_step, ofs_az, ofs_el, subscan

   wind, 1, 1, /free
   plot, data0.ofs_az, data0.ofs_el, /iso, xtitle='ofs_az [arcsec]', ytitle='ofs_el [arcsec]'
   oplot, ofs_az, ofs_el, col=70
   leg_col = [!p.color, 70]
   legendastro, ["Real scan", "Simulated scan"], $
                col=leg_col, textcol=leg_col, box=0, line=0
endif

;; Add the hwp angle to data here until it is in the real data
junk = data0[0]
upgrade_struct, junk, {c_position:0.d0}, junk

;; Produce the structure "data" to be used from now on
nsn  = n_elements( ofs_az)
data = replicate( junk, nsn)
time = dindgen(nsn)/ps.gen.nu_sampling
data.c_position   = (2.d0*!dpi*ps.hwp.nu_rot*time) mod (2.d0*!dpi) ; HWP rotation angle
data.ofs_az  = temporary(ofs_az)
data.ofs_el  = temporary(ofs_el)
data.subscan = temporary(subscan)
fields = ['scan', 'el', 'paral', 'scan_st']
for i=0, n_elements(fields)-1 do begin
   cmd = "data."+fields[i]+" = interpol( data0."+fields[i]+", time0, time)"
   junk = execute( cmd)
endfor
;; save memory
delvarx, data0, time0

;;===================================================================================================
;; Generate TOIs

;; Convert matrices into Mueller form once for all and define an ideal reference case
jones2mueller, ps.hwp.jones, hwp_mueller
jones2mueller, ps.grid.jones, split_grid_mueller

hwp_jones_perf             = dblarr(2,2)
hwp_jones_perf[0,0]        =  1.0d0
hwp_jones_perf[1,1]        = -1.0d0
split_grid_jones_perf      = dblarr(2,2)
split_grid_jones_perf[0,0] = 1.d0
jones2mueller, hwp_jones_perf, hwp_mueller_perf
jones2mueller, split_grid_jones_perf, split_grid_mueller_perf

;; Template
if ps.gen.add_template ne 0 then $
   make_template, ps.template.n_harmonics, data.c_position*!radeg, time, $
                  ps.template.ampl, ps.template.drift, hwp_template

;; Sky noise
if ps.gen.add_sky_noise ne 0 then begin

   ;; Init to the same size as kidpar for convenience and leave to 0 unused
   ;; pixels (type /=1 )
   delta_x = dblarr( nkids)
   delta_y = dblarr( nkids)

   delta_x[w1] = kidpar[w1].nas_x*!arcsec2rad * ps.sky_noise.h_cloud
   delta_y[w1] = kidpar[w1].nas_y*!arcsec2rad * ps.sky_noise.h_cloud

   nika_sky_noise_2, time, delta_x, delta_y, ps.sky_noise.cloud_vx, $
                     ps.sky_noise.cloud_vy, ps.sky_noise.atm_alpha, $
                     ps.sky_noise.cloud_map_reso, sky_noise, disk_convolve=ps.sky_noise.disk_convolve
endif

;; Main loop
stokes = dblarr(nsn,3)
test_toi = {input_s0:     dblarr(nsn, 2)+!values.d_nan, $
            input_s1:     dblarr(nsn, 2)+!values.d_nan, $
            input_s2:     dblarr(nsn, 2)+!values.d_nan, $
            sky_signal:   dblarr(nsn, 2), $
            tl_signal:    dblarr(nsn, 2), $
            noise:        dblarr(nsn), $
            sky_noise:    dblarr(nsn), $
            template:     dblarr(nsn), $
            template_fit: dblarr(nsn)}
for lambda=1, 2 do begin

   wlambda = where( kidpar.array eq lambda and kidpar.type eq 1, nwlambda)
   if nwlambda ne 0 then begin
      for i=0, nwlambda-1 do begin
         ikid = wlambda[i]

         ;; Scan coordinates or each kid
         nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                               kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                               0., 0., dra, ddec, nas_x_ref=kidpar[ikid].nas_center_X, $
                               nas_y_ref=kidpar[ikid].nas_center_Y
         
         ix   = long( (dra  - xmin)/ps.sky.reso_map)   ; Coord of the pixel along x
         iy   = long( (ddec - ymin)/ps.sky.reso_map)   ; Coord of the pixel along y
         ipix = ix + iy*ps.sky.nx                      ; Pixel index

         ;;--------------------------------------------------------------
         ;; Before HWP modulation:
         ;;--------------------------------------------------------------

         ;; Get sky signal
         stokes = stokes*0. + !values.d_nan
         w = where( ix ge 0 and ix le (ps.sky.nx-1) and $
                    iy ge 0 and iy le (ps.sky.ny-1), nw)
         if nw eq 0 then begin
            message, /info, "No valid pixel coordinates ?!"
         endif else begin
            stokes[w,0] = maps_S0[ ipix[w], lambda-1]
            stokes[w,1] = maps_S1[ ipix[w], lambda-1]
            stokes[w,2] = maps_S2[ ipix[w], lambda-1]
         endelse

         ;; Add point sources  directly to the timeline and not to the
         ;; input map to avoid artificial pixelization of the sources
         if n_sources ne 0 then begin
            for is=0, n_sources-1 do begin
               d     = sqrt( (dra-ps_ra[is])^2+(ddec-ps_dec[is])^2)
               sigma = kidpar[ikid].fwhm*!fwhm2sigma

               Intensity = ps.sky.ps_flux*exp(-( (d<100)^2/(2.d0*sigma^2)))
               stokes[*,0] += Intensity
               stokes[*,1] += Intensity*ps_pol_deg[is]*cos(2.d0*ps_alpha_rad[is])
               stokes[*,2] += Intensity*ps_pol_deg[is]*sin(2.d0*ps_alpha_rad[is])
            endfor
         endif

         ;; keep or cancel T or P for simulation purpose
         stokes[*,0] = stokes[*,0]*ps.sky.t_ampl
         stokes[*,1] = stokes[*,1]*ps.sky.p_ampl
         stokes[*,2] = stokes[*,2]*ps.sky.p_ampl

         ;; Signal only timeline for reference
         if i eq 0 then begin
            apply_mueller, stokes, data.c_position, hwp_mueller, junk
            apply_mueller, junk, 0.d0, split_grid_mueller, junk
            test_toi.sky_signal[*,lambda-1] = junk[*,0]
         endif

         ;; Add unpolarized sky noise if requested
         if ps.gen.add_sky_noise ne 0 then stokes[*,0] += sky_noise[ikid,*]

         ;;--------------------------------------------------------------
         ;; HWP modulation
         apply_mueller, stokes, data.c_position, hwp_mueller, stokes
         ;;--------------------------------------------------------------

         ;;--------------------------------------------------------------
         ;; After HWP modulation
         ;;--------------------------------------------------------------

         ;; Splitting grid
         apply_mueller, stokes, 0.d0, split_grid_mueller, stokes

         ;; Total power measurement of the kid
         data.rf_didq[ikid] = stokes[*,0]

         ;; Add template (same of all kids for now)
         if ps.gen.add_template ne 0 then data.rf_didq[ikid] += hwp_template

         ;; 1/f or white noise (each kid independent)
         if ps.gen.add_one_over_f ne 0 then begin
            noise_1d, nsn, ps.gen.nu_sampling, noise, noise_model, net=ps.noise.net, fknee=ps.noise.fknee, alpha=ps.noise.alpha
            data.rf_didq[ikid] += noise
         endif
         
         ;; For plots
         if i eq 0 then begin
            test_toi.input_S0[w,lambda-1] = maps_S0[ ipix[w]]
            test_toi.input_S1[w,lambda-1] = maps_S1[ ipix[w]]
            test_toi.input_S2[w,lambda-1] = maps_S2[ ipix[w]]

            ;; overwrite 2mm and 1mm, doesn't matter for now
            if ps.gen.add_one_over_f ne 0 then test_toi.noise     = noise
            if ps.gen.add_template   ne 0 then test_toi.template  = hwp_template
            if ps.gen.add_sky_noise  ne 0 then test_toi.sky_noise = sky_noise[i,*]
         endif

      endfor                    ; kids at lambda
   endif                        ; if lambda was simulated
endfor                          ; loop over lambda

;; Add point sources to maps_S0, S1, S2 now that the timelines have been
;; produced correctly, to allow for direct comparison between input simulated
;; sky and output sky.
if n_sources ne 0 then begin
   for is=0, n_sources-1 do begin
      d     = sqrt( (xmap-ps_ra[is])^2+(ymap-ps_dec[is])^2)

      ;; 1mm
      sigma = ps.instr.fwhm_1mm*!fwhm2sigma
      I = ps.sky.ps_flux*exp(-( (d<100)^2/(2.d0*sigma^2)))
      maps_S0[*,0] += I
      maps_S1[*,0] += I*ps_pol_deg[is]*cos(2.d0*ps_alpha_rad[is])
      maps_S2[*,0] += I*ps_pol_deg[is]*sin(2.d0*ps_alpha_rad[is])

      ;; 2mm
      sigma = ps.instr.fwhm_2mm*!fwhm2sigma
      I = ps.sky.ps_flux*exp(-( (d<100)^2/(2.d0*sigma^2)))
      maps_S0[*,1] += I
      maps_S1[*,1] += I*ps_pol_deg[is]*cos(2.d0*ps_alpha_rad[is])
      maps_S2[*,1] += I*ps_pol_deg[is]*sin(2.d0*ps_alpha_rad[is])
   endfor
endif


message, "", /info
message, "Done.", /info

end

