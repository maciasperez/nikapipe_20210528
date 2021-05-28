;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_aperture_photometry_3
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_aperture_photometry
; 
; PURPOSE: 
;        Derives aperture photometry at the map center
; 
; INPUT: 
;        - param, grid, info
; 
; OUTPUT: 
;        - info: updated with the status, error message and photometry results
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - August, 20th, 2015: Adapted from nika_anapipe_difphoto, R. Adam and
;          N. Ponthieu

pro nk_aperture_photometry_3, param, info, grid, source=source, $
                              xcenter=xcenter, ycenter=ycenter, $
                              nickname = nickname, bg_mask=bg_mask
;-  
if n_params() lt 1 then begin
   message, /info, "Calling sequence: "
   dl_unix, 'nk_aperture_photometry_3'
   return
endif

if info.status eq 1 then return

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

if not keyword_set(xcenter) then xcenter = 0.d0
if not keyword_set(ycenter) then ycenter = 0.d0
if not keyword_set(source)  then source = ''

rmap = sqrt( (grid.xmap-xcenter)^2 + (grid.ymap-ycenter)^2)  
loc0 = where(rmap ge param.aperture_photometry_zl_rmin and rmap le param.aperture_photometry_zl_rmax, nloc0)
if nloc0 eq 0 then begin
   nk_error, info, "no pixel lies between param.aperture_photometry_zl_rmin="+strtrim(param.aperture_photometry_zl_rmin,2)+$
             " and param.aperture_photometry_zl_rmax="+strtrim(param.aperture_photometry_zl_rmax,2)
   return
endif

if info.polar eq 0 then nstokes=1 else nstokes=3

;; Quick scan on grid tags to initialize display parameters
grid_tags = tag_names(grid)
narrays = 3 ; 0
nstokes = 1                     ; I at least
for iarray=1, 3 do begin
   w = where( strupcase(grid_tags) eq "MAP_VAR_Q"+strtrim(iarray,2), nw)
   if nw ne 0 then begin
      ww = where( finite(grid.(w)) and grid.(w) ne 0, nww)
      if nww ne 0 then nstokes=3
   endif
endfor

stokes_par   = ["I", "Q", "U"]
;field_list   = ["_1MM", "_2MM", '1', '2', '3']
;field_list_1 = ['1MM', '2MM', '1', '2', '3']
;iarray_list  = [1, 2, 1, 2, 3]
;field_list   = ['1', '3', '2', "_1MM", "_2MM"]
;field_list_1 = ['1', '3', '2', '1MM', '2MM']
;iarray_list  = [1, 3, 2, 1, 2]
field_list   = ['1', '3', "_1MM", '2', "_2MM"]  ; have all 1mm channels together FXD
field_list_1 = ['1', '3',  '1MM', '2',  '2MM']
iarray_list  = [ 1,   3,    1,     2,    2]
nfields      = n_elements(field_list)

print, !outplot.old_device, !p.background, !p.color

if nstokes gt 1 then begin
   my_multiplot, nstokes*2, nfields-1, pp, pp1, /rev
endif else begin
   my_multiplot, 2, nfields-1, pp, pp1, /rev, gap_x=0.05, ymargin=0.05
endelse
if param.do_plot ne 0 and param.plot_ps eq 0 then begin
   set_plot, !outplot.old_device
   !p.color = 0
   !p.background = 255
   wind, 1, 1, /free, /large, iconic = param.iconic
endif

grid_tags  = tag_names( grid)
info_tags  = tag_names(info)

if keyword_set( nickname) then begin
   filout = param.plot_dir+'/aperture_photometry_'+$
            nickname
endif else begin
   filout = param.plot_dir+'/aperture_photometry_'+$
            strtrim(param.scan,2)
endelse
; ps does not work so we have to find a workaround
;outplot, file=filout, png=param.plot_png, ps=param.plot_ps
outplot, file=filout, png=param.plot_png + param.plot_ps, zbuffer=param.plot_z;, /reverse_video
;  FXD try to correct a color bug with reverse video

for ifield=0, nfields-1 do begin
   iarray = iarray_list[ifield]

   noplot = param.do_plot eq 0
   ;; Do not display 2mm, redundant with A2
   if ifield eq nfields-1 then noplot=1
   
   for istokes=0, nstokes-1 do begin

      ;; Check if the map exists (in particular, are we in polarized mode ?)
      wmap = where( strupcase(grid_tags) eq "MAP_"+stokes_par[istokes]+field_list[ifield], nwmap)
      if nwmap ne 0 then begin
         
         ;; Check if the map is not empty (e.g. "one mm only"...)
         whits = where( strupcase(grid_tags) eq "NHITS_"+field_list_1[ifield], nwhits)
         if max( grid.(whits)) gt 0 then begin
            wvar = where( strupcase(grid_tags) eq "MAP_VAR_"+stokes_par[istokes]+field_list[ifield], nwvar)

            if noplot eq 0 then begin
               mypp1 = dblarr(2,4)
               mypp1[0,*] = reform(pp[2*istokes,  ifield,*])
               mypp1[1,*] = reform(pp[2*istokes+1,ifield,*])
            endif
            wflctag = where( strupcase(info_tags) eq "RESULT_FLUX_"+$
                          strupcase(stokes_par[istokes])+field_list[ifield], nwflctag)
            if nwflctag ge 1 then flps = info.(wflctag) else stop
            weflctag = where( strupcase(info_tags) eq "RESULT_ERR_FLUX_"+$
                          strupcase(stokes_par[istokes])+field_list[ifield], nweflctag)
            if nweflctag ge 1 then eflps = info.(weflctag)
            
            aphot, grid.(wmap), grid.(wvar), grid.xmap, grid.ymap, grid.map_reso, xcenter, ycenter, $
                   param.aperture_photometry_rmeas, param.aperture_photometry_zl_rmin, param.aperture_photometry_zl_rmax, $
                   param.aperture_photometry_binwidth, !nika.fwhm_array[iarray-1], flux, err_flux, int_rad, phi, err, $
                   noplot=noplot, bg_mask=bg_mask, pp1=mypp1, title=stokes_par[istokes]+field_list[ifield]+" "+source, $
                   omega_90=!nika.omega_90[iarray-1], flps = flps, eflps = eflps
            
            ;; Store result in info.
            wtag = where( strupcase(info_tags) eq "RESULT_APERTURE_PHOTOMETRY_"+$
                          strupcase(stokes_par[istokes])+field_list[ifield], nwtag)

            if nwtag ne 0 then info.(wtag) = flux
            wtag = where( strupcase(info_tags) eq "RESULT_ERR_APERTURE_PHOTOMETRY_"+$
                          strupcase(stokes_par[istokes])+field_list[ifield], nwtag)
            if nwtag ne 0 then info.(wtag) = err_flux
         endif
      endif
      ;; end loop on stokes parameters
   endfor
   ;; end loop on fields
endfor

if param.do_plot ne 0 then outplot, /close
if param.plot_ps then begin
   command = 'convert '+ filout+'.png '+ filout+ '.pdf'
   spawn, command, res
   command = 'rm -f '+ filout+'.png '
   spawn, command, res
endif

!p.multi = 0

if param.cpu_time then nk_show_cpu_time, param

end
