pro otf_pointing_xy2azel, x, y, angle, signe, ofs_az, ofs_el 

;+
; AIM   
;   rotate back the x,y pointing timelines to ofs_az and ofs_el ones
;   (inverse rotation than of otf_poiting_azel2xy)    
;
; INPUTS
;       x : fastest coordinate ("triangularish signal")
;       y : slowest coordinate ("steps")
;   angle : rotation angle to "straighten" the pointing (that may be
;           provided to PAKO by the observer) 
;   signe : if +1: rotating clockwise 
;           if -1: rotating counterclockwise     
;  INPUTS
;       ofs_az : data.ofs_az
;       ofs_el : data.ofs_el
;
;-



  ;;
  ;;  Rotating 
  ;;___________________________________________________________________________________________
  
  ofs_az = cos(angle)*x + signe*sin(angle)*y
  ofs_el = -1d0*signe*sin(angle)*x + cos(angle)*y






end
