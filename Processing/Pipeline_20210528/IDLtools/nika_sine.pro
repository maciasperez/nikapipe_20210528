
function nika_sine, x, p

f = p[1]*sin( p[0]*x) + p[2]*cos( p[0]*x)

return, f

end
