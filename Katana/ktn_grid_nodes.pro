
;; Another look at the FP
;;----------------------------

pro ktn_grid_nodes_display, xra_plot, yra_plot, ikid_in=ikid_in, noerase=noerase, only_ikid=only_ikid

common ktn_common

if not keyword_set(ikid_in)  then ikid_in  = -1
;if not keyword_set(position) then position = fltarr(4)

alpha = disp.alpha*!dtor
kidpar.x_peak = 1./disp.delta * ( cos(alpha)*kidpar.x_peak_nasmyth + sin(alpha)*kidpar.y_peak_nasmyth)
kidpar.y_peak = 1./disp.delta * (-sin(alpha)*kidpar.x_peak_nasmyth + cos(alpha)*kidpar.y_peak_nasmyth)

w1    = where( kidpar.type eq 1, nw1)
w3    = where( kidpar.type eq 3, nw3)
wplot = where( kidpar.plot_flag eq 0, nwplot)

xcenter_plot = avg( kidpar[wplot].x_peak)
ycenter_plot = avg( kidpar[wplot].y_peak)
xra_plot = 1.1*minmax( kidpar[wplot].x_peak)
junk = (max(kidpar[wplot].y_peak)-min(kidpar[wplot].y_peak))
yra_plot = min(kidpar[wplot].y_peak) + [-0.1, 1.5]*junk ; make room for the caption
  
get_x0y0, kidpar[wplot].x_peak, kidpar[wplot].y_peak, xc0, yc0, ww
ibol_ref = wplot[ww]

outplot, file=sys_info.plot_dir+"/"+sys_info.nickname+"_GridNodes", png=sys_info.png, ps=sys_info.ps
plot, [kidpar[wplot].x_peak], [kidpar[wplot].y_peak], psym=1, /iso, xtitle='mm', ytitle='mm', $
      title=title, xra=xra_plot, yra=yra_plot, noerase=noerase, /xs, /ys
oplot, [xc0], [yc0], psym=4, col=150
if not keyword_set(only_ikid) then begin
   legendastro, ['Nvalid='+strtrim(nw1,2), $
                "Alpha opt: "+strtrim( string(disp.alpha,format="(F5.2)"),2), $
                "delta opt: "+strtrim( string(disp.delta,format="(F5.2)"),2)], /right, chars=1.5, box=0
   xyouts, kidpar[wplot].x_peak, kidpar[wplot].y_peak, strtrim(kidpar[wplot].numdet,2), chars=1.2
endif
imin = floor( min(kidpar[wplot].x_peak))-1 
imax = round( max(kidpar[wplot].x_peak))+1
jmin = floor( min(kidpar[wplot].y_peak))-1
jmax = round( max(kidpar[wplot].y_peak))+1
for i=imin, imax do oplot, [1,1]*i, [jmin, jmax], line=1
for j=jmin, jmax do oplot, [imin, imax], [1,1]*j, line=1
oplot, kidpar[  wplot].x_peak, kidpar[wplot].y_peak, psym=1
oplot, round(kidpar[  wplot].x_peak), round(kidpar[wplot].y_peak), psym=8, col=70
arrow, kidpar[  wplot].x_peak, kidpar[wplot].y_peak, $
       round(kidpar[  wplot].x_peak), round(kidpar[wplot].y_peak), /data, hsize=-0.2, col=70

if ikid_in ge 0 and ikid_in le (n_elements(kidpar)-1) then begin
   if kidpar[ikid_in].plot_flag eq 0 then begin
      oplot, [kidpar[ikid_in].x_peak], [kidpar[ikid_in].y_peak], psym=1, col=250, thick=2
      xyouts, kidpar[ikid_in].x_peak, kidpar[ikid_in].y_peak, strtrim(kidpar[ikid_in].numdet,2), chars=1.2, col=250
   endif
endif
outplot, /close


end

;;-------------------------------------------------------------------------------------------------------------
pro ktn_grid_nodes_event, ev
  common ktn_common

  widget_control, ev.id, get_uvalue=uvalue
  tags = tag_names(ev)
  
  w1    = where( kidpar.type eq 1, nw1)
  w3    = where( kidpar.type eq 3, nw3)
  wplot = where( kidpar.plot_flag eq 0, nwplot)

  if defined(uvalue) then begin
     case uvalue of
        "quit": begin
           ;wd, kquick.drawid2
           ;wd, kquick.drawid4
           widget_control, ev.top, /destroy
           goto, exit
        end

        "discard": kidpar[disp.ikid].plot_flag = 1

        "reset": begin
           kidpar.plot_flag = 1
           kidpar[w1].plot_flag = 0
        end

        'grid_pars':begin
           get_grid_nodes, kidpar[wplot].x_peak_nasmyth, kidpar[wplot].y_peak_nasmyth, $
                           xnode, ynode, alpha_opt, delta_opt, name=kidpar[wplot].name, /noplot
           disp.alpha = alpha_opt*!radeg
           disp.delta = delta_opt
        end
        
     endcase
  endif

  wset, kquick.drawID1
  wplot = where( kidpar.plot_flag eq 0, nwplot)
  ktn_grid_nodes_display, xra_plot, yra_plot, ikid_in=disp.ikid

  IF (TAG_NAMES(ev, /STRUCTURE_NAME) eq 'WIDGET_DRAW') THEN BEGIN
     xy = convert_coord( ev.x, ev.y, /device, /to_data)
     xcursor = xy[0]
     ycursor = xy[1]
     if xcursor ge min( xra_plot) and xcursor le max( xra_plot) and $
        ycursor ge min( yra_plot) and ycursor le max( yra_plot) then begin

        d2 = (kidpar[wplot].x_peak-xcursor)^2 + (kidpar[wplot].y_peak-ycursor)^2
        disp.ikid = wplot[ (where( d2 eq min(d2)))[0]]

        ;; discard
        if ev.release eq 4 then kidpar[disp.ikid].plot_flag = 1

     endif
  ENDIF

  wset, kquick.drawID1
  wplot = where( kidpar.plot_flag eq 0, nwplot)
  ktn_grid_nodes_display, ikid_in=disp.ikid

;;  fmt="(F9.2)"
;;  wset, kquick.drawID2
;;  my_multiplot, 2, 1, pp, pp1, /rev
;;  imview, reform( disp.map_list[disp.ikid,*,*]), xmap=xmap, ymap=ymap, $
;;          udg=rebin_factor, $ ;title="iKid "+strtrim(disp.ikid,2), $
;;          legend_text=['Numdet : '+strtrim(kidpar[disp.ikid].numdet,2), $
;;                       'Name : '+kidpar[disp.ikid].name, $
;;                       'Flag = '+strtrim(kidpar[disp.ikid].type,2)], leg_color=255, position=pp1[0,*]
;;  legendastro, "ikid = "+strtrim(disp.ikid,2), /right, box=0, textcol=255
;;      
;;  imview, reform( disp.beam_list[disp.ikid,*,*]), xmap=xmap, ymap=ymap, $
;;          udg=rebin_factor, $;title="iKid "+strtrim(disp.ikid,2), $
;;          legend_text=['Numdet : '+strtrim(kidpar[disp.ikid].numdet,2), $
;;                       'Name : '+kidpar[disp.ikid].name, $
;;                       'Flag = '+strtrim(kidpar[disp.ikid].type,2)], leg_color=255, position=pp1[1,*], /noerase
;;  legendastro, "ikid = "+strtrim(disp.ikid,2), /right, box=0, textcol=255
;;  legendastro, ['Resp.: '+string( kidpar[disp.ikid].response,format=fmt)+" mK/Hz", $
;;                'FWHM: '+string( sqrt( kidpar[disp.ikid].sigma_x*kidpar[disp.ikid].sigma_y)/!fwhm2sigma, format=fmt)], $
;;               box=0, /bottom, textcol=255
;;
;;  wset, kquick.drawID4
;;  ktn_ikid_properties_2

exit:
end

;;------------------------------------------------------------------------------------------------------------------------
pro ktn_grid_nodes, no_block=no_block
  common ktn_common

  xs_commands = !screen_size[0]*0.5
  ys_commands = !screen_size[1]*0.8

  xs_def = 100
  ys_def = 100
  nxpix = long( xs_commands - 1.3*xs_def)
  nypix = long( ys_commands)

  ;; Create widget
  main  = widget_base( title='Quickview', /row, /frame)
  comm0 = widget_base( main, /column, /frame, xsize=xs_commands, ysize=ys_commands)

  ;; Main plot window
  comm1         = widget_base( comm0, /row, /frame, xsize=xs_commands)
  display_draw1 = widget_draw( comm1, xsize=nxpix, ysize=nypix, /button_events)

  comm12 = widget_base( comm1, /column, /frame, xsize=xs_def*1.2)
  b = widget_button( comm12, uvalue='grid_pars', value=np_cbb( 'Grid Params',     bg='ygb7',      fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm12, uvalue='reset',     value=np_cbb( 'Reset Plot kids', bg='sea green', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm12, uvalue='quit',      value=np_cbb( 'Quit',            bg='firebrick', fg='white', xs=xs_def, ys=xs_def), xs=xs_def, ys=ys_def)

  ;; Realize the widget
  xoff = !screen_size[0]-xs_commands*1.2
  widget_control, main, /realize, xoff=xoff, xs=xs_commands, ys=ys_commands
  widget_control, display_draw1, get_value=drawID1

;  wind, 1, 1, /free, xsize=1200
;  drawid2 = !d.window
;  wind, 1, /free, /large, xpos=1e-5, ypos=1e-5
;  drawid4 = !d.window

  ;;kquick = {drawID1:drawID1, drawID2:drawID2, drawID3:drawID3,
  ;;drawID4:drawID4}
;  kquick = {drawID1:drawID1, drawID2:drawID2, drawID4:drawID4}
  kquick = {drawID1:drawID1}
  xmanager, "ktn_grid_nodes", main, no_block=no_block

  ;; Init plot
  wset, kquick.drawID1
  ktn_grid_nodes_display, ikid_in=disp.ikid

end
