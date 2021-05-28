;+
;PURPOSE: add a flag to data.flag unless already flagged with same
;         flag lebel
;
;INPUT: flag array and flag label
;
;OUTPUT: the data structure with new flags added
;
;KEYWORDS: - sample: the sample indexes on which to apply the flag
;          - wkid: the sample indexes on which to apply the flag
;
;LAST EDITION: 05/01/2014: creation (adam@lpsc.in2p3.fr)
;-

pro nika_pipe_addflag, data, flag_num, wsample=wsample, wkid=wkid

  ;;------ All KIDs and all samples by default
  if n_elements(wsample) ge 1 then sample = wsample else sample = lindgen(n_elements(data))
  if n_elements(wkid) ge 1 then kid = wkid else kid = lindgen(n_elements(data[0].flag))

  ;;------- Init a new flag array with wanted samples and KIDs
  flag_array = data[sample].flag[kid]
  
  ;;------- Find position where the same flag is already applied
  powerOfTwo = 2L^flag_num
  deja_flag = where((LONG(flag_array) AND powerOfTwo) EQ powerOfTwo, ndeja_flag, comp=pas_flag, ncomp=npas_flag)
  
  ;;------- Apply the flag only where it has never been applied
  if npas_flag ne 0 then flag_array[pas_flag] += 2L^flag_num

  ;;------- Modify the data.flag accordingly
  data[sample].flag[kid] = flag_array
  
  return
end
