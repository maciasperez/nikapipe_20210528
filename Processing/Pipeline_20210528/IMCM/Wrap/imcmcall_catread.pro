pro imcmcall_catread, catfile, psou

  nfl = n_elements( catfile)
  for ifl = 0, nfl-1 do begin
     readcol, catfile[ifl], id, ra, dec, ras, decs, fl1, efl1, snr1, $
              fl2, efl2, snr2, format='A,D,D,A,A,D,D,D,D,D,D', comment='#', /silent, delim=','
     nid = n_elements( id)
     if ifl eq 0 then begin
        nsou = nid
; Create a structure filled in by fluxes
        psou = replicate({id:-1, ra:0D0, dec:0D0, ras:'', decs:'', $
                          fl1:0D0, efl1:0D0, snr1:0D0, $
                          fl2:0D0, efl2:0D0, snr2:0D0}, nsou, nfl) ; nsou sources, nfl files
     endif
     
     if nid ne nsou then begin
        message, /info, 'Catalog '+catfile[ifl]+ $
                 'does not match the template '+ catfile[0]
     endif else begin
        nid1 = nid-1
        psou[0:nid1, ifl].id = id
        psou[0:nid1, ifl].ra = ra
        psou[0:nid1, ifl].dec = dec
        psou[0:nid1, ifl].ras = ras
        psou[0:nid1, ifl].decs = decs
        psou[0:nid1, ifl].fl1 = fl1
        psou[0:nid1, ifl].efl1 = efl1
        psou[0:nid1, ifl].snr1 = snr1
        psou[0:nid1, ifl].fl2 = fl2
        psou[0:nid1, ifl].efl2= efl2
        psou[0:nid1, ifl].snr2 = snr2
     endelse 
  endfor 
  
  
  
  return
end
