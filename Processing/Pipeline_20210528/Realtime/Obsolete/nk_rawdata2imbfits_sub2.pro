PRO nk_rawdata2imbfits_sub2, dirin, filein, param_c, kidpar, strdat, $
                             dirout, fileout, info = info, $
                             noexe = noexe,  verb = verb, updp = updp, $
                             cfits = cfits
; Imported from FXD convert_nika2imbfits
; Valid for Run7 onwards

; Run>=7
facqmeas = !nika.f_sampling 
; should be up to date (if read_nika_brute just before).

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
; For runCryo and run7, no shift anymore
nshift = 0

if not keyword_set( cfits) then begin
; Don't do anything to the data if cfits keywords is used
; f_tone is now the total resonance frequency (not f_tone anymore)
   strdat.f_tone = strdat.f_tone + strdat.df_tone ; Hz now OK (double)

; Run6 and before
;;; strdat.f_tone = (strdat.f_tone + strdat.df_tone)*1D3  ; Hz total (not tone)
   for idet = 0,  n_elements( strdat[0].f_tone)-1 do begin
      bad = where( strdat.f_tone[ idet] lt 5., nbad) 
; bad samples at the beginning
      if nbad ne 0 then strdat[bad].f_tone[ idet] = $
         median( strdat.f_tone[ idet]) ; quick fix
   endfor
   strdat.df_tone = strdat.toi ; default for pf (rf is in rf_pipq)
endif


if keyword_set( updp) then begin
  @nika_pipe_writefitsiram16updp.scr
endif else begin
   if keyword_set( cfits) then begin
     @nk_writefitsiram18cfits.scr
  endif else begin
; Run9 v2
     @nk_rawdata2imbfits_w18.scr
  endelse
endelse

return

END
