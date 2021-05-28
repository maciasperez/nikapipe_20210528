
;; Perform simple interpolation of toi_in

pro qd_interpol, toi_in, flags, toi_out


on_error, 2

toi_out = toi_in                                     ; init
w = where( flags eq 1, nw, compl=wgood, ncompl=nwgood) ; bad data

if nw ne 0 and nwgood gt 3 then toi_out[w] = interpol( toi_in[wgood], wgood, w)

end
