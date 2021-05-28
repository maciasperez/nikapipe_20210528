

;; Order the parameter vector in the same way as for gauss2dfit and mpfit2dpeak

function nika_gauss2_2beams, x, y, p, _EXTRA=extra

;; 1st beam  
xx =  cos(p[6])*(x-p[4]) + sin(p[6])*(y-p[5])
yy = -sin(p[6])*(x-p[4]) + cos(p[6])*(y-p[5])

u = (xx/p[2])^2 + (yy/p[3])^2
u_mask = u LT 100

;; 2nd beam
xx1 =  cos(p[6+7])*(x-p[4+7]) + sin(p[6+7])*(y-p[5+7])
yy1 = -sin(p[6+7])*(x-p[4+7]) + cos(p[6+7])*(y-p[5+7])

v = (xx/p[2+7])^2 + (yy/p[3+7])^2
v_mask = v LT 100

f = p[0] + p[1] * u_mask * exp(-0.5D * temporary(u) * u_mask) + $
    p[7] + p[8] * v_mask * exp(-0.5D * temporary(v) * v_mask)
u_mask = 0
v_mask = 0

return, f

end
