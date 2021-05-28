
;; outlyers ?!
abs_nas_off_x_min = 100
abs_nas_off_y_min = 100
abs_det_az_min = 100
abs_det_el_min = 100

w = where( abs(nas_off_x) gt abs_nas_off_x_min, nw)
if nw ne 0 then kidpar[w].type = 5
w = where( abs(nas_off_y) gt abs_nas_off_y_min, nw)
if nw ne 0 then kidpar[w].type = 5

;; outlyers ?!
w = where( abs(det_az) gt abs_det_az_min, nw)
if nw ne 0 then kidpar[w].type = 5
w = where( abs(det_el) gt abs_det_el_min, nw)
if nw ne 0 then kidpar[w].type = 5

;;end
