
pro azel2nasm, elevation_rad, ofs_az, ofs_el, ofs_x, ofs_y

;; alpha is the angle to go from nasmyth to azel, hence i rotate here by -alpha
alpha = alpha_nasmyth( elevation_rad)

ofs_x   =  cos(alpha)*ofs_az + sin(alpha)*ofs_el
ofs_y   = -sin(alpha)*ofs_az + cos(alpha)*ofs_el


;; message, /info, "fix me: trying new transformation for NIKA2"
;; ;; mirror
;; ofs_y = -ofs_y
;; ;; 90 deg rotation
;; x = -ofs_y
;; ofs_y = ofs_x
;; ofs_x = x
;; stop


end
