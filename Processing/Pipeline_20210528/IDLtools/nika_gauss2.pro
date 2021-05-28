

;; Order the parameter vector in the same way as for gauss2dfit and mpfit2dpeak

function nika_gauss2, x, y, p, _EXTRA=extra

xx =  cos(p[6])*(x-p[4]) + sin(p[6])*(y-p[5])
yy = -sin(p[6])*(x-p[4]) + cos(p[6])*(y-p[5])

u = (xx/p[2])^2 + (yy/p[3])^2
mask = u LT 100
f = p[0] + p[1] * mask * exp(-0.5D * temporary(u) * mask)
mask = 0

return, f

end
