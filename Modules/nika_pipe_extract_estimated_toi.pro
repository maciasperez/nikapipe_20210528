;+
;PURPOSE: Extract estimated TOI from a previous iteration
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The source TOI
;
;LAST EDITION: - 2015/07/12: creation
;-


function nika_pipe_extract_estimated_toi, param, data, kidpar

  n_kid = n_elements(kidpar)
  w1    = where(kidpar.type eq 1, nw1)   ;Number of detector ON
  w_off = where(kidpar.type eq 2, n_off) ;Number of detector OFF

  ;;========== Extract the flagging maps
  nika_pipe_extract_map_flag, param.decor.common_mode.map_guess1mm, 'flux', param.decor.common_mode.relob.a, $
                              map_guess_1mm, reso_guess1mm
  nika_pipe_extract_map_flag, param.decor.common_mode.map_guess2mm, 'flux', param.decor.common_mode.relob.b, $
                              map_guess_2mm, reso_guess2mm

  ;;========== Determine the source estimated TOI
  toi_est = data.rf_didq*0
  for i=0, nw1-1 do begin
     ikid = w1[i]
     nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                           kidpar[ikid].nas_x,kidpar[ikid].nas_y, 0., 0., $
                           dra,ddec,nas_x_ref=kidpar[ikid].nas_center_X, nas_y_ref=kidpar[ikid].nas_center_Y
     case kidpar[ikid].array of
        1: begin 
           map_guess = map_guess_1mm
           reso_guess = reso_guess1mm
        end
        2: begin 
           map_guess = map_guess_2mm
           reso_guess = reso_guess2mm
        end
     endcase
     toi_est[ikid,*] = simu_map2toi(map_guess, reso_guess, dra, ddec)
     loc_off = where(data.on_source_dec[ikid] eq 0, nloc_off)
     if nloc_off ne 0 then toi_est[ikid, loc_off] = 0 ;No TOI if off source to avoid noise
  endfor
  
  return, toi_est
end
