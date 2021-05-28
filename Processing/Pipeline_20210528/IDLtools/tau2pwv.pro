

function tau2pwv, tau, freq_ghz

;    tau(frq[GHz]) = B(frq[GHz]) * pwv[mm] + C(frq[GHz])
readcol, !nika.soft_dir+"/Pipeline/IDLtools/sky.iram30m.atmJAN07-BC.dat", $
         ghz, B, C, format='D,D,D', comment="!", /silent

pwv_list = (tau - C)/B
pwv      = interpol( pwv_list, ghz, freq_ghz)
return, pwv

end
