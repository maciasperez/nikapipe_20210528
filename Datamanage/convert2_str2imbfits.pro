PRO convert2_str2imbfits, dirin, filein, param_c, kidpar, strdat, $
                          dirout, fileout, ndeg,  $
                          noexe = noexe,  verb = verb, updp = updp, $
                          cfits = cfits
; Imported from FXD convert_nika2imbfits
; Valid for Run6 onwards

if not defined( ndeg) then ndeg = 3
; Run6 and preRun7
;;; facqmeas = 250D6/40D0/2L^18  ; = 23.841858 correct according to Martino
; Run7
facqmeas = !nika.f_sampling ; should be up to date (if read_nika_brute just before).

outfileB= dirout + fileout
outfileA= dirout + 'NIKA1'+ strmid( fileout, 5)

if keyword_set( updp) then begin
   outfileA= dirout + 'iram30m-NIKA1'+ strmid( fileout, 13)
   outfileB= dirout + fileout
   outfileAupdp= dirout + updp+ '/'+ 'iram30m-NIKA1'+ strmid( fileout, 13)
   outfileBupdp= dirout + updp+ '/'+ fileout
endif

if keyword_set( cfits) then begin
   outfileA= dirout + 'iram30m-NIKA1'+ strmid( fileout, 13)
   outfileB= dirout + fileout
   outfileAcfits= cfits[0]+'/'+ cfits[1]
   outfileBcfits= cfits[0]+'/'+ cfits[2]
endif

; process the data to get pf and clean the timing
; run6, preRun7 strdat.rf_didq = -strdat.rf_didq ; change sign

; Run7, no need to change sign anymore

; Shift I, Q, dI, dQ by 50 (trial and error)
;nshift = 49  ; 49 no shift in rf_didq, 50 shift by 1 (retained option to be compatible with rf people)
; For runCryo and run7, no shift anymore
nshift = 0
;stop
;; strdat.I  = shift(  strdat.I, 0, nshift)
;; strdat.Q  = shift(  strdat.Q, 0, nshift)
;; strdat.dI = shift( strdat.dI, 0, nshift)
;; strdat.dQ = shift( strdat.dQ, 0, nshift)
;print, 'nshift = ', nshift

if not keyword_set( cfits) then begin
; Don't do anything to the data if cfits keywords is used
strdat.f_tone = strdat.f_tone + strdat.df_tone  ; Hz now OK (double)
; Run6 and before
;;; strdat.f_tone = (strdat.f_tone + strdat.df_tone)*1D3  ; Hz total (not tone)
for idet = 0,  n_elements( strdat[0].f_tone)-1 do begin
   bad = where( strdat.f_tone[ idet] lt 5., nbad) 
; bad samples at the beginning
   if nbad ne 0 then strdat[bad].f_tone[ idet] = $
      median( strdat.f_tone[ idet])    ; quick fix
endfor
strdat.df_tone = strdat.rf_didq  ; default for pf


; Improved method
     if tag_exist( param_c, "AF_MOD")  then afmod = double( param_c.AF_MOD)*1000.d0
     if tag_exist( param_c, "A_F_MOD") then afmod = double( param_c.A_F_MOD)
     if tag_exist( param_c, "BF_MOD")  then bfmod = double( param_c.BF_MOD)*1000.d0
     if tag_exist( param_c, "B_F_MOD") then bfmod = double( param_c.B_F_MOD)

     freqnormA = afmod /1.    ; 2500. Hz most of the time DO NOT DIVIDE BY 2
     freqnormB = bfmod /1.    ; 1000. Hz most of the time


;print,  ndeg,  freqnormA,  freqnormB,  n_elements(strdat.i[0])
if ndeg gt 0 and freqnormA gt 0. and n_elements(strdat.i[0]) gt 1 then begin
   ;print, 'convert to Pf with ndeg = ', ndeg
   nika_conviq2pf, strdat, kidpar, dapf, ndeg, [freqnormA,  freqnormB]
   ; If the IQ to PF conversion works keep it
   strdat.df_tone = dapf
endif else print, 'conversion to Pf could not be done'
endif
; OK for Run7
;;;print,'clean timing'
; v1 only (included in writefits16 for v2)
; nika_pipe_clean_timing, strdat, verb = verb

; Backup solution
;;;;@nika_pipe_Clean_timingA.scr
;print, 'bypassing mjd correction'

; From now on Late June 13th
; Run6
; kidpar.numdet = kidpar.raw_num
; Run7, do nothing

if keyword_set( updp) then begin
  @nika_pipe_writefitsiram16updp.scr
endif else begin
if keyword_set( cfits) then begin
  @nika_pipe_writefitsiram17cfits.scr
; v1
;  @nika_pipe_writefitsiram16cfits.scr
endif else begin
; Run9 v1
  @nika_pipe_writefitsiram17.scr
endelse
endelse
; Run7 v1
; @nika_pipe_writefitsiram15.scr

; Prepare 2013 run 6
;@nika_pipe_writefitsiram14.scr

return

END
