PRO convert_str2imbfits, dirin, filein, param_c, kidpar, strdat, $
                         dirout, fileout, ndeg,  noexe = noexe,  verb = verb, cfmethod = cfmethod
; Imported from FXD convert_nika2imbfits
; Valid for Run6 onwards

if not defined( ndeg) then ndeg = 3
facqmeas = 250D6/40D0/2L^18  ; = 23.841858 correct according to Martino

outfileB= dirout + fileout
outfileA= dirout + 'NIKA1'+ strmid( fileout, 5)

; process the data to get pf and clean the timing
strdat.rf_didq = -strdat.rf_didq ; change sign

; Shift I, Q, dI, dQ by 50 (trial and error)
nshift = 49  ; 49 no shift in rf_didq, 50 shift by 1 (retained option to be compatible with rf people)
strdat.I  = shift(  strdat.I, 0, nshift)
strdat.Q  = shift(  strdat.Q, 0, nshift)
strdat.dI = shift( strdat.dI, 0, nshift)
strdat.dQ = shift( strdat.dQ, 0, nshift)

strdat.f_tone = (strdat.f_tone + strdat.df_tone)*1D3  ; Hz total (not tone)
for idet = 0,  n_elements( strdat[0].f_tone)-1 do begin
   bad = where( strdat.f_tone[ idet] lt 5., nbad) 
; bad samples at the beginning
   if nbad ne 0 then strdat[bad].f_tone[ idet] = $
      median( strdat.f_tone[ idet])    ; quick fix
endfor
strdat.df_tone = strdat.rf_didq  ; default for pf

; checked (no factor 2 please) June 13th
freqnormA = param_c.a_f_mod /1. ; 8kHz most of the time
freqnormB = param_c.b_f_mod /1. ; 4kHz most of the time
;print,  ndeg,  freqnormA,  freqnormB,  n_elements(strdat.i[0])
if ndeg gt 0 and freqnormA gt 0. and n_elements(strdat.i[0]) gt 10 then begin
   ;print, 'convert to Pf with ndeg = ', ndeg
   nika_conviq2pf, strdat, kidpar, dapf, ndeg, [freqnormA,  freqnormB]
   ; If the IQ to PF conversion works keep it
   strdat.df_tone = dapf
endif else print, 'conversion to Pf could not be done'

; OK now
@nika_pipe_Clean_timingA.scr
;print, 'bypassing mjd correction'

; From now on Late June 13th
kidpar.numdet = kidpar.raw_num

; Prepare 2013 run 6
@nika_pipe_writefitsiram13.scr

return

END
