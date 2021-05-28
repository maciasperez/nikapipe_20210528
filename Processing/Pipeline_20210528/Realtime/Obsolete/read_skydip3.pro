
;; added keyword param to be able to force the input geometry. Nico.

pro read_skydip3,scan_num, day, f_tone1,f_tone2,df_tone1,df_tone2, el, flag,w_on1,w_on2, param=param
;PARTE FROM FOCUS

;; Init param to be used in pipeline modules

;day='20121122'
;scan_num=22
if not keyword_set(param) then nika_pipe_default_param, scan_num, day, param

;; Get data
;noskydip = 1
;param.kid_file.a = ''
;param.kid_file.b = ''
nika_pipe_getdata, param, data, kidpar, /nocut, tau_force=tau_force;, noskydip=noskydip
;
;GOOD PIXELS FOR 1MM

f_tone=data.f_tone
df_tone=data.df_tone
w_on1=where(kidpar.type eq 1 and long(kidpar.array) eq 1)
w_on2=where(kidpar.type eq 1 and long(kidpar.array) eq 2)
f_tone1=f_tone[w_on1,*]
df_tone1=df_tone[w_on1,*]
f_tone2=f_tone[w_on2,*]
df_tone2=df_tone[w_on2,*]

el=data.el
flag=data.scan_st

end
