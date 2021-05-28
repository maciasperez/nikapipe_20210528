

PRO ktn_matrix_event, ev, action=action
  common ktn_common

  widget_control, ev.id, get_uvalue=uvalue

  w1 = where( kidpar.type eq 1, nw1)

  tags = tag_names( ev)
  w = where( tags eq "TAB", nw)
  if nw ne 0 then begin
     matrix = disp.map_list
     dxmap = max(disp.xmap)-min(disp.xmap)
     dymap = max(disp.ymap)-min(disp.ymap)
     xmin = min(disp.xmap)
     ymin = min(disp.ymap)
     ymax = max(disp.ymap)

     itab = ev.tab
     disp.current_tab = itab
     wset, dispmat[itab]

     kmin = itab*disp.nkids_max_per_tab
     kmax = ((itab+1)*disp.nkids_max_per_tab) < disp.nkids
     
     ;; LP: to define the range of the color table 
     ;;maxtab = dblarr(kmax-kmin)
     ;;for mm=0, kmax-kmin-1 do maxtab[mm] = max(matrix[kmin+mm,*,*])
     ;;mymax = median(maxtab)
     relmax = 0.2
     if keyword_set(relative_max) then relmax = relative_max
     
     ikid = kmin
     phi = dindgen(100)/99.*2*!dpi
     for j=0, n_elements(disp.plot_position[0,*,0])-1 do begin
        for i=0, n_elements(disp.plot_position[*,0,0])-1 do begin
           if ikid lt kmax then begin
              delvarx, imrange
              if keyword_set(relative_max) then imrange = [-1,1]*relative_max*max(matrix[ikid,*,*])

              ;;message, /info, "fix me:"
                                ;imrange = [-1,1]*0.2*max(matrix[ikid,*,*])
              imrange = [-0.08,0.2]*max(matrix[ikid,*,*])
              ;;imrange = [-0.08,0.3]*max(matrix[ikid,*,*])
              ;; LP imrange
              ;;mymax = min([max(matrix[kmin:kmax-1,*,*]),20000.])
              ;;imrange = [-0.08*mymax,0.2*mymax]
              ;;imrange = [-1./2.5,1.]*relmax*max(matrix[ikid,*,*])


              if kidpar[ikid].plot_flag ne 0 then bw=1 else bw=0
              imview, reform(matrix[ikid,*,*]), xmap=disp.xmap, ymap=disp.ymap, $
                      position=reform(disp.plot_position[i,j,*]), $
                      udg=rebin_factor, /nobar, chars=1e-6, /noerase, imrange=imrange, bw=bw
              ;;oplot, kidpar[ikid].x_peak_azel + kidpar[ikid].fwhm*cos(phi)*3., $
              ;;       kidpar[ikid].y_peak_azel + kidpar[ikid].fwhm*sin(phi)*3., col=255
              
              xx = xmin+0.1*dxmap
              yy = ymin+0.1*dymap
              decode_flag, kidpar[ikid].type, flagname
              xyouts, xx, yy, flagname, chars=1.5, col=disp.textcol
              
              yy = ymax-0.2*dymap
              xyouts, xx, yy, strtrim( kidpar[ikid].numdet,2)+" A"+strtrim(kidpar[ikid].array,2), col=disp.textcol

              if kidpar[ikid].plot_flag ne 0 then begin
                 yy = ymin+0.1*dymap
                 xyouts, xx, yy, "Discarded", col=disp.textcol
                 ;oplot, minmax(disp.xmap), minmax(disp.ymap), col=disp.textcol
                 ;oplot, minmax(disp.xmap), reverse(minmax(disp.ymap)), col=disp.textcol
              endif

              ikid += 1
           endif
        endfor
     endfor
  endif

  kmin = disp.current_tab*disp.nkids_max_per_tab
  kmax = ((disp.current_tab+1)*disp.nkids_max_per_tab-1) < disp.nkids

  if defined(uvalue) then begin
     case uvalue of
        "quit": begin
           widget_control, ev.top, /destroy
           goto, exit
        end
     endcase

  endif else begin

     IF (TAG_NAMES(ev, /STRUCTURE_NAME) eq 'WIDGET_DRAW') THEN BEGIN
        x = float(ev.x)/disp.xsize_matrix
        y = float(ev.y)/disp.ysize_matrix
        for j=0, n_elements( disp.plot_position1[*,0])-1 do begin
           if (float(x) ge disp.plot_position1[j,0] and $
               float(x) lt disp.plot_position1[j,2] and $
               float(y) ge disp.plot_position1[j,1] and $
               float(y) lt disp.plot_position1[j,3]) then begin
              if (j+kmin) lt n_elements(kidpar) then begin
                 disp.ikid = j+kmin

                 case strupcase(action) of
                    "DISCARD":begin
                       kidpar[disp.ikid].plot_flag =  1
                       print,  "Discarded Numdet # "+strtrim( kidpar[disp.ikid].numdet, 2)
                    end
                    "DOUBLE":begin
                       kidpar[disp.ikid].plot_flag = 2
                       print,  "Double found: Numdet # "+strtrim( kidpar[disp.ikid].numdet, 2)
                    end
                    "RESTORE":begin
                       kidpar[disp.ikid].plot_flag = 0
                       print, "Restored Numdet # "+strtrim( kidpar[disp.ikid].numdet,  2)
                    end
                    else:begin
                       wshet,  disp.window
                       ktn_ikid_properties
                    end
                 endcase

              endif
           endif
        endfor


     ENDIF

  endelse

exit:
end
