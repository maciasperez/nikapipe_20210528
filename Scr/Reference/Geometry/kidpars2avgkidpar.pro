; NAME: 
;        kidpars2avgkidpar
;
; CALLING SEQUENCE:
;        kidpars2avgkidpar, file_list=file_list, all_kidpar=all_kidpar, avg_kidpar=avg_kidpar
; 
; PURPOSE: 
;        Create an average kidpar from a list of kidpars
; 
; INPUT:
;        - file_list
;       
; OUTPUT: 
;        - all_kidpar = structure containing all the kidpars provided
;          as file_list (to be used to recover the information per KID
;          as, for example, all_kidpar[where(all_kidpar.numdet eq avg_kidpar[0].numdet)].nas_x
;        - avg_kidpar = average kidpar (the field n_of_geom contains the number of times
;          that a KID has been flagged as TYPE=1)
;
; OPTIONAL KEYWORDS:
;        -/remove_jumps_twins - if set, pixels moving across the focal
;                               plane and sharing the same position
;                               are flagged (n_of_geom = -3 and -2,
;                               respectively)
;        -n_geom - the minimum number of beam maps in which a KIDs must
;                  be valid to be TYPE = 1 in the avg kidpar (if not
;                  set, the default value is 2)
;
; 
; EXAMPLE:
;        - an example of how the procedure can be
;          used can be found in the script Labtools/BC/nika2/make_geom/plot_avg_kidpar2.pro
; 
; MODIFICATION HISTORY: 
;        - 28/06/2017

pro kidpars2avgkidpar, file_list=file_list, all_kidpar=all_kidpar, avg_kidpar=avg_kidpar, remove_jumps_twins=remove_jumps_twins, n_geom = n_geom

;look for all the fields (and relative types)
  for i = 0, n_elements(file_list)-1 do begin
     k = mrdfits(file_list[i], 1, h, /silent)
     fields = TAG_NAMES(k)
     for j = 0, n_elements(fields)-1 do begin
        if j eq 0 then type = typename(k.(j)) else type = [type, typename(k.(j))]
     endfor
     if i eq 0 then all_fields = fields else all_fields = [all_fields, fields]
     if i eq 0 then all_types = type else all_types = [all_types, type]
     if i eq 0 then numdet_list = k.numdet else numdet_list = [numdet_list, k.numdet]
  endfor
  
  numdet_list = numdet_list[UNIQ(numdet_list, SORT(numdet_list))]
  all_types = all_types[[UNIQ(all_fields, SORT(all_fields))]]  
  all_fields = all_fields[[UNIQ(all_fields, SORT(all_fields))]]
  all_fields = [all_fields, 'n_of_geom']
  all_types = [all_types, 'INT']

;prepare the structure for the average kidpar
  for i = 0, n_elements(all_fields)-1 do begin
     if all_types[i] eq 'STRING' then var = "'s'"
     if all_types[i] eq 'LONG' then var = '0L'
     if all_types[i] eq 'DOUBLE' then var = '0.d0'
     if all_types[i] eq 'INT' then var = '0'
     if i eq 0 then strexc = "avg_kidpar = create_struct('"+all_fields[i]+"', "+var else strexc = strexc+", '"+all_fields[i]+"', "+var
  endfor
  strexc = strexc+")"
  dummy = execute( strexc)

  avg_kidpar = replicate(avg_kidpar, n_elements(numdet_list))
  avg_kidpar.numdet = numdet_list

 ;create the array of kidpars
  k_new = avg_kidpar
  for i = 0, n_elements(file_list)-1 do begin
     k = mrdfits(file_list[i], 1, h, /silent)
     tnames = TAG_NAMES(k)
     for j = 0, n_elements(all_fields)-1 do begin
        tindex = where(STRCMP(tnames,all_fields[j]) EQ 1, count)
        if all_fields[j] ne 'NUMDET' then begin
        if count gt 0 then begin
           for d = 0, n_elements(numdet_list)-1 do begin
              ind = where(k.numdet eq k_new[d].numdet, cnt)
              if cnt gt 0 then k_new[d].(j) = k[ind[0]].(tindex) else k_new[d].(j)=!values.f_nan 
           endfor
        endif else k_new.(j) = fltarr(n_elements(numdet_list)) + !values.f_nan
        endif
     endfor
     if i eq 0 then all_kidpar = k_new else all_kidpar = [all_kidpar, k_new]
  endfor

  ;fill the average kidpar
  tnames = TAG_NAMES(avg_kidpar)
  t_names=TAG_NAMES(all_kidpar[where(all_kidpar.numdet eq numdet_list)])
  for i = 0, n_elements(numdet_list)-1 do begin
     kn = all_kidpar[where(all_kidpar.numdet eq numdet_list[i])]
     for j = 0, n_elements(tnames)-1 do begin
        tindex = where(STRCMP(t_names,tnames[j]) EQ 1)
        if typename(kn.(tindex)) eq 'DOUBLE' then avg_kidpar[i].(tindex) = mean(kn[where(kn.type eq 1)].(tindex)) ;mean of the position, FWHM, noise etc
        if typename(kn.(tindex)) eq 'LONG' then avg_kidpar[i].(tindex) = max(kn.(tindex))
        if typename(kn.(tindex)) eq 'INT' then avg_kidpar[i].(tindex) = max(kn.(tindex))
        avg_kidpar[i].n_of_geom = n_elements(where(kn.type eq 1))
        if typename(kn.(tindex)) eq 'STRING' then avg_kidpar[i].(tindex) = kn[0].(tindex)
     endfor
  endfor

  if keyword_set(remove_jumps_twins) then begin
     numdet_list = avg_kidpar.numdet
     avg_nas_x = dblarr(n_elements(numdet_list))
     avg_nas_y = dblarr(n_elements(numdet_list))
     for i = 0, n_elements(numdet_list)-1 do begin
        kn = all_kidpar[where(all_kidpar.numdet eq numdet_list[i])]
        if avg_kidpar[where(avg_kidpar.numdet eq numdet_list[i])].n_of_geom ge 2 then begin
           avg_nas_x[i] = median(kn[where(kn.type eq 1)].nas_x)
           avg_nas_y[i] = median(kn[where(kn.type eq 1)].nas_y)
        endif
     endfor
     
     for i = 0, 2 do begin
        ind = where(avg_kidpar.array eq i+1 and avg_kidpar.n_of_geom ge 2)
        dist = (sqrt((avg_kidpar[ind].nas_x-avg_nas_x[ind])^2. + (avg_kidpar[ind].nas_y-avg_nas_y[ind])^2.))
        var = stddev(dist)
        dist = (sqrt((avg_kidpar.nas_x-avg_nas_x)^2. + (avg_kidpar.nas_y-avg_nas_y)^2.))
        ind = where(avg_kidpar.array eq i+1 and avg_kidpar.n_of_geom ge 2 and dist le var)
        jump = where(avg_kidpar.array eq i+1 and avg_kidpar.n_of_geom ge 2 and dist gt var)
        avg_kidpar[jump].n_of_geom = -3
        
        double1 = 0
        for k = 0, n_elements(ind)-1 do begin
           dist_d = (sqrt((avg_kidpar[ind[k]].nas_x-avg_kidpar[ind].nas_x)^2. + (avg_kidpar[ind[k]].nas_y-avg_kidpar[ind].nas_y)^2.))
           dist_d[where(dist_d le 1.e-5)] = 50.
           if min(dist_d) le 5 then begin
              avg_kidpar[where(avg_kidpar.numdet eq avg_kidpar[ind[k]].numdet)].n_of_geom = -2 
              double1 = [double1, avg_kidpar[ind[k]].numdet]
           endif
        endfor
        double1 = double1[where(double1 ne 0)]
        if i eq 0 then double = double1 else double = [double, double1]
     endfor
     print, '===================================================================================================='
     print, 'n_of_geom = -2 for kids that share the same position on the focal plane'
     print, 'n_of_geom = -3 for kids that move across the focal plane'
     print, '===================================================================================================='
  endif

  if not keyword_set(n_geom) then n_geom = 2
  avg_kidpar[where(avg_kidpar.n_of_geom ge n_geom)].type = 1
  avg_kidpar[where(avg_kidpar.n_of_geom lt n_geom)].type = 0

  print, '===================================================================================================='
  print, 'avg_kidpar[where(avg_kidpar.n_of_geom ge '+strtrim(n_geom,2)+')].type = 1 and 0 elsewhere'
  print, 'KIDs type is set to 1 if the KID has been found to be valid at least ' + strtrim(n_geom,2) + ' times'
  print, '===================================================================================================='


end
