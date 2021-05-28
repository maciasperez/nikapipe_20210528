
pro qu2alpha, q, u, alpha_deg

;; if q eq 0 then begin
;;    alpha_deg = sign(u)*45.d0
;; endif else begin
;;    if q gt 0 and u ge 0 then alpha_deg = 0.5*atan( u/q)*!radeg
;;    if q lt 0 and u ge 0 then alpha_deg = 0.5*(atan(-u/q)*!radeg - 90.d0)
;;    if q lt 0 and u le 0 then alpha_deg = 0.5*atan( u/q)*!radeg
;;    if q gt 0 and u le 0 then alpha_deg = 0.5*atan( u/q)*!radeg
;; endelse

alpha_deg = 0.5*atan(u,q)*!radeg


end
