pro set_raw_data_dir, runname

  ;; wrapper usefull for the machines at LPSC only
  spawn, 'hostname', machine
  if strmatch(strmid(machine, 0, 4), 'lpsc') gt 0 then begin
     data_dir = '/data/'
     runname = strupcase(runname)
     case 1 of
        runname eq 'N2R21': data_dir = '/data/' ;; run35      
        runname eq 'N2R25': data_dir = '/data/' ;; run39
        runname eq 'N2R28': data_dir = '/data/' ;; run42
        runname eq 'N2R29': data_dir = '/data/' ;; run43
        runname eq 'N2R30': data_dir = '/data/' ;; run44
        runname eq 'N2R33': data_dir = '/data/' ;; run47
        runname eq 'N2R34': data_dir = '/data/' ;; run48
        runname eq 'N2R35': data_dir = '/data/' ;; run48b
        runname eq 'N2R36': data_dir = '/data/' ;; run49
        runname eq 'N2R37': data_dir = '/data/' ;; run49b
        runname eq 'N2R38': data_dir = '/data/' ;; run50
        runname eq 'N2R39': data_dir = '/data/' ;; run51
        runname eq 'N2R40': data_dir = '/data/' ;; run52
        runname eq 'N2R41': data_dir = '/data/' ;; run53
        runname eq 'N2R42': data_dir = '/data/' ;; run54
        runname eq 'N2R45': data_dir = '/data/' ;; run57
        runname eq 'N2R46': data_dir = '/data/' ;; run 58
        runname eq 'N2R47': data_dir = '/data/' ;; run 59
        runname eq 'N2R48': data_dir = '/data/' ;; run 60
        runname eq 'N2R49': data_dir = '/data/' ;; run 61
        runname eq 'N2R50': data_dir = '/data/' ;; run 62
        else: print, 'Default raw data dir'
     endcase
     setenv, 'NIKA_RAW_DATA_DIR='+data_dir
  endif
  raw_acq_dir = getenv('NIKA_RAW_DATA_DIR')
  !nika.raw_acq_dir = raw_acq_dir
  !nika.raw_data_dir = raw_acq_dir
  
end
