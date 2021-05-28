pro read_nika_fits, file, pars, regpar, regpar_a, regpar_b,kidpar, data,  units,  $
                    header_pars = hpar1,  header_reg = hpar2,  k_pf = k_pf, a_only=a_only

; k_pf=[ ndeg, freqnorm]
;; Number of common parameters
 ncommon = 37
 nkidvar =  8
;; bin2Hz = 498.074D6/2D0^18  ; Hz/bin  ; According to Alessandro (2011 OK)
;; bin2Hz = 490D6/2D0^18  ; Hz/bin  ; According to Alain (2012 OK)

 par1 = mrdfits(file,1, hpar1,  /silent)
 get_nika_par,  hpar1, pars

 regpar = mrdfits(file,2,hpar2,  /silent)
 convert_nika_reg_par, pars.div_kid, regpar,  regpar_a,  regpar_b, a_only=a_only

; ----------

 nkidorg = n_elements(par1)
 ecartpar = mrdfits(file,9,hecart,  /silent, status = status)
 nelecartpar = n_elements(ecartpar) 
 print, "WARNING :  ", nelecartpar, nkidorg 
 if (size(ecartpar, /type) eq 8 and nelecartpar ge nkidorg ) then begin
    necartpar =  n_tags(ecartpar)
    kidpar = {name:"", type:0, x_pix:0, y_pix:0, frequ:0, amplitu:0, ic:0, qc:0, ir:0, qr:0, numdet:0, sample_cfreq:lindgen(necartpar), delta_freq:dblarr(necartpar)}
    kidpar = replicate(kidpar, nkidorg)
    for ikid = 0,  nkidorg-1 do begin
     for iecart = 0, necartpar-1 do begin
      kidpar[ikid].sample_cfreq[iecart] =  reform(ecartpar[0].(iecart)) 
      kidpar[ikid].delta_freq[iecart] =  reform(ecartpar[ikid + 1].(iecart)) 
     endfor
   endfor
 endif else begin
    kidpar = {name:"", type:0, x_pix:0, y_pix:0, frequ:0, amplitu:0, ic:0, qc:0, ir:0, qr:0, numdet:0}
    kidpar = replicate(kidpar, nkidorg)
 endelse

;stop
; kidpar ={name:"",type:0,x_pix:0,y_pix:0,frequ:0,amplitu:0,ic:0,qc:0,ir:0,qr:0, numdet:0, sample_cfreq:lindgen(), delta_freq:dblarr()}
 kidpar.name =  strtrim(par1.nom, 2)
 kidpar.type =  par1.nom2
 kidpar.numdet =  indgen(nkidorg)
 for i=3,10 do kidpar.(i-1) = par1.(i)
 filename = FILE_BASENAME(file)
 
if keyword_set(a_only) then begin 
    matrice='A'
endif else begin
 if strmid(filename, 0, 1) eq "A" then begin
    kidpar =  kidpar[0:nkidorg/2-1]
    matrice =  'A'
 endif else begin    
    kidpar =  kidpar[nkidorg/2: * ]
    matrice =  'B'
 endelse
endelse

 
 
;; WE KEEP ALL PIXELS
 nkid = n_elements(kidpar)
;; listokkid = lindgen(nkid) 
;; listokkid =  where(kidpar.type gt 0, nkid)
;; if nkid gt 0 then begin 
 ;;   kidpar =  kidpar[listokkid]
 ;;   regpar =  regpar[listokkid]
 ;;  endif else begin
 ;;   print,  "Wrong file, no KID available"
 ;;   return
 ;; endelse
 
; Read DATA RF_DIDQ
 datstr = mrdfits(file,7,hrfdidq, /silent)
 Ndata = n_elements(datstr) 
 Tagname = tag_names(datstr)
;; if (nkid ne n_elements(tagname)-ncommon) then begin
;;    print,  'Inconsistent FITS file'
;;    stop
;;  endif 

;stop

units =  {SAMPLE:'sample',T_KIDA:'sec',T_KIDB:'sec', freq_A:'Hz', freq_B:'Hz', msq_A:'bit', msq_B:'bit', $
        nv_dacA:'' , nv_dacB:'' , nv_adcA:'', nv_adcB:'', SYNCHRO:'', $
          SCAN_ST:'scan', ARA_MPI:'mm', OFS_X:'mm', OFS_Y:'mm', $
        scan:'scan', subscan:'scan', obs_st:'', size_x:'arc_sec', size_y:'arc_sec', nb_sbsc:'', $
        step_y:'', speed:'', Bra_mpi:'', ofs_Az:'', ofs_El:'', $
        ofs_Ra:'', ofs_Dec:'', Az:'', El:'', Ra:'', Dec:'', Paral:'',  LST:'', MJD:'', rotazel:'',  $
         I:'ADU',Q:'ADU',dI:'ADU',dQ:'ADU',RF_DIDQ:'Hz', PF:'Hz', Ftone:'Hz',dF_tone:'Hz'}


Data = {SAMPLE:0LL,T_KIDA:0.0d0, T_KIDB:0.0d0,freq_A:0.0d0, freq_B:0.0d0, msq_A:0, msq_B:0,$
        nv_dacA:0.0d0, nv_dacB:0d0, nv_adcA:0d0, nv_adcB:0d0, SYNCHRO:0, $
        SCAN_ST:0.0, ARA_MPI:0.0, OFS_X:0.0, OFS_Y:0.0, $
        scan:0, subscan:0, obs_st:0d0, size_x:0d0, size_y:0d0, nb_sbsc:0, $
        step_y:0d0, speed:0d0, Bra_mpi:0d0, ofs_Az:0d0, ofs_El:0d0, $
        ofs_Ra:0d0, ofs_Dec:0d0, Az:0d0, El:0d0, Ra:0d0, Dec:0d0, Paral:0d0,  LST:0d0, MJD:0d0, rotazel:0d0,  $
        I:dblarr(nkid), Q:dblarr(nkid), dI:dblarr(nkid), $
        dQ:dblarr(nkid), RF_DIDQ:dblarr(nkid), PF:dblarr(nkid), Ftone:dblarr(nkid),dF_tone:dblarr(nkid)}
Data = replicate(data,ndata)
tagdata =  tag_names(data)

; Setting common data
nrealcommon =  0
for itag = 0, n_tags(data)-nkidvar do begin
 pos = where(tagdata[itag] eq tagname, npos)
 if npos gt 0 then begin
     units.(itag) = sxpar(hrfdidq, 'TUNIT' + strtrim(pos[0] + 1, 2))
 ;    print, tagdata[itag] + ":   " + units.(itag)
     if (tagdata[itag]  eq 'SAMPLE') then begin 
         data.(itag) = long(datstr.(pos[0]))
     endif else if (tagdata[itag] eq 'msq_A' or tagdata[itag] eq 'msq_B' or  $
               tagdata[itag] eq 'scan'   or  tagdata[itag] eq 'subscan' or  tagdata[itag] eq 'nb_sbsc')   then begin
        data.(itag) = int(datstr.(pos[0]))
     endif else begin 
        data.(itag) = datstr.(pos[0])
    endelse
    nrealcommon += 1
 endif
endfor


; setting KID data
For i=0,nkid-1 do data[*].rf_didq[i] = datstr.(i+nrealcommon)
datstr = mrdfits(file,3,hi,  /silent)
For i=0,nkid-1 do data[*].i[i] = datstr.(i+nrealcommon)
datstr = mrdfits(file,4,hq,  /silent)
For i=0,nkid-1 do data[*].q[i] = datstr.(i+nrealcommon)
datstr = mrdfits(file,5,hdi, /silent)
For i=0,nkid-1 do data[*].di[i] = datstr.(i+nrealcommon)
datstr = mrdfits(file,6,hdq,  /silent)
For i=0,nkid-1 do data[*].dq[i] = datstr.(i+nrealcommon)
datstr = mrdfits(file,8,hftone,  /silent)
For i=0,nkid-1 do data[*].ftone[i] = datstr.(i+nrealcommon) * 1D3  ; convert to Hz
datstr = mrdfits(file,9,hdftone,  /silent)
For i=0,nkid-1 do data[*].df_tone[i] = datstr.(i+nrealcommon) * 1D3  ; convert to Hz

if keyword_set( k_pf)then begin
  conviq2pf, data, dpf, k_pf[0],  k_pf[1]
  data.pf = dpf
endif else begin
  data.pf =  data.rf_didq
endelse

;stop
return
end


;; pro get_units, str, myunit
 
;;  strl =  strlen(str)
;;  pos1 =  strpos(str, "'")
;;  pos2 =  strpos(strmid(str, pos1 + 1, strl-pos1-1), "'")
;;  myunit =  strmid(str, pos1 + 1, pos2)
;;  return
;; end


;; REGLAGE PARAMETER CONVERSION


