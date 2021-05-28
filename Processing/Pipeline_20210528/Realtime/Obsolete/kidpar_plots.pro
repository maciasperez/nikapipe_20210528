

png = 1


;scan_num = 196
;day      = '20140120'

day      = '20140122'
scan_num = 91

output_dir = !nika.plot_dir+"/"+day+"_"+strtrim(scan_num,2)
spawn, "mkdir -p "+output_dir

nickname = day+"s"+strtrim(scan_num,2)

nika_pipe_default_param, scan_num, day, param

kidpar = mrdfits( param.kid_file.b, 1)
kidpar2fp, kidpar, nickname=nickname+"_2mm", png=png, output_dir=output_dir

kidpar = mrdfits( param.kid_file.a, 1)
kidpar2fp, kidpar, nickname=nickname+"_1mm", png=png, output_dir=output_dir

end
