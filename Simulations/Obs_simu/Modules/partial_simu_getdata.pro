;+
;PURPOSE: This procedure get the pointing to be used in the simulation
;INPUT: The parameter structure.
;OUTPUT: The data structure.
;LAST EDITION: 17/01/2012
;LAST EDITOR: Remi ADAM (adam@lpsc.in2p3.fr)
;-

pro partial_simu_getdata, param, data, kidpar

  ;;Get real data
  nika_pipe_getdata, param, data, kidpar

  ;;Empty the TOI
  data.RF_dIdQ = data.RF_dIdQ * 0

  ;;Set the tau that you want unless tau=-1 (case you keep real tau)
  if param.atmo.tau0_a ne -1 then kidpar[where(kidpar.array eq 1)].tau0 = param.atmo.tau0_a
  if param.atmo.tau0_b ne -1 then kidpar[where(kidpar.array eq 2)].tau0 = param.atmo.tau0_b

  return
end
