
function alpha_nasmyth, elevation_rad

  ;;return, !dpi/2.d0 - elevation_rad

  if strupcase(!nika.run) eq "CRYO" then begin
     alpha = !dpi/2.d0 - elevation_rad
  endif else begin
     if long(!nika.run) le 6 then begin
        alpha = !dpi/2.d0 - elevation_rad
     endif else begin
        alpha = -elevation_rad
     endelse
  endelse
  
  return, alpha
end

