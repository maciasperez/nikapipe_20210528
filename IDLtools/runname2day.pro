
pro runname2day, runname, day, comment=comment, cryorun=cryorun

  ;; runname using the convention 'N2R'+number
  ;; return [first_day, last_day]
  ;; LP, April 2018
  
  if n_params() lt 1 then begin
     message, /info, "Calling sequence:"
     print, "runname2day, runname, day"
     return
  endif

  runname = strupcase(runname)
  
  case 1 of
     
     ;; NIKA2

     runname eq 'N2R1' : begin  
        day = ['20150901', '20151106']
        com = 'technical run'
        run = '12'
     end
     runname eq 'N2R2' : begin  ; run14
        day = ['20151124', '20160111']
        com = 'technical run'
        run = '14'
     end
     runname eq 'N2R3' : begin  ; run15
        day = ['20160112', '20160121']
        com = 'technical run'
        run = 15
     end
     runname eq 'N2R4' : begin  ; run16
        day = ['20160121', '20160921']
        com = 'technical run'   
     end
     runname eq 'N2R5' : begin  ; run18
        day = ['20160922', '20161205']
        com = 'technical run'
        run = 18
     end
     runname eq 'N2R6' : begin  ; run19
        day = ['20161010', '20161205']
        com = 'technical run'
        run = 19   
     end
     runname eq 'N2R7' : begin  ; run20
        day = ['20161206', '20161214']
        com = 'technical run'
        run = 20  
     end
     runname eq 'N2R8' : begin  ; run21
        day = ['20170124', '20170126']
        com = 'technical run'
        run = 21  
     end
     runname eq 'N2R9' : begin  ; run22
        day = ['20170221', '20170228']
        com = 'technical run, reference campaign'
        run = 22
     end
     runname eq 'N2R10': begin  ; run23
        day = ['20170414', '20170425']
        com = 'technical run, Science Verification Phase'
        run = 23  
     end
     runname eq 'N2R11': begin  ; run24 ;; test
        day = ['20170606', '20170613']
        com = 'technical run'
        run = 24  
     end
     runname eq 'N2R12': begin  ; run25
        day = ['20171016', '20171031']
        com = 'science pool, reference campaign'
        run = 25  
     end
     runname eq 'N2R13': begin   ; run26 ;; polar run
        day = ['20171117', '20171128']
        com = 'technical run, polarisation'
        run = 26  
     end
     runname eq 'N2R14': begin  ; run27
        day = ['20180112', '20180123']
        com = 'science pool, reference campaign'
        run = 27  
     end
     runname eq 'N2R15': begin  ; run28
        day = ['20180213', '20180220']
        com = 'science pool'
        run = 28  
     end
     runname eq 'N2R16': begin  ; run29
        day = ['20180302', '20180312'] 
        com = 'technical run, polarisation'
        run = 29  
     end
     runname eq 'N2R17': begin  ; run30 ;; bad weather
        day = ['20180313', '20180320'] 
        com = 'science pool, bad weather'
        run = 30  
     end
     runname eq 'N2R18': begin  ; run31 ;; PIMP run
        day = ['20180522', '20180529']
        com = 'technical run, PIMP'
        run = 31  
     end
     runname eq 'N2R19': begin  ; run32 ;; polar run
        day = ['20180608', '20180619']
        com = 'technical run, polarisation'
        run = 32  
     end
     runname eq 'N2R20': begin  ; run33-34 ;; polar run
        day = ['20180904', '20180906']
        com = 'technical run, polarisation'
        run = 33  
     end
     runname eq 'N2R21': begin  ; run35 ;; dichroic run
        day = ['20180918', '20180925']
        com = 'technical run, dichroic'
        run = 35  
     end
     runname eq 'N2R22': begin  ; run36 ;; v2
        day = ['20181001', '20181009'] 
        com = 'science pool, v2 problem'
        run = 36  
     end
     runname eq 'N2R23': begin ; run37
        day = ['20181031', '20181106']
        com = 'science pool'
        run = 37  
     end
     runname eq 'N2R24': begin ; run38
        day = ['20181123', '20181127']
        com = 'science pool'
        run = 38  
     end
     runname eq 'N2R25': begin ; run39 ;; polar run
        day = ['20181203', '20181211']
        com = 'technical run, polarisation'
        run = 39  
     end
     runname eq 'N2R26': begin ; run40
        day = ['20190115', '20190122']
        com = 'science pool'
        run = 40  
     end
     runname eq 'N2R27': begin ; run41 ;; 24h of obs
        day = ['20190128', '20190206']
        com = 'science pool, bad weather'
        run = 41  
     end
     ;; LP: back to the naming convention of baseline_calibration
     ;;runname eq 'RUN48': day = ['20191007', '20191023'] ;; N2R34 + N2R35
     ;;runname eq 'RUN49': day = ['20191028', '20191113'] ;; N2R36 + N2R37
     ;;runname eq 'RUN50': day = ['20191208', '20191218'] ;; N2R38
     ;;runname eq 'RUN51': day = ['20200108', '20200124'] ;; N2R39
     runname eq 'N2R28': begin ; run42
        day = ['20190212', '20190219']
        com = 'science pool'
        run = 42  
     end
     runname eq 'N2R29': begin  ; run43
        day = ['20190305', '20190312']
        com = 'science pool'
        run = 43  
     end
     runname eq 'N2R30': begin  ; run44
        day = ['20190319', '20190326']
        com = 'science pool'
        run = 44  
     end
     runname eq 'N2R31': begin ; run45 ;; tests
        day = ['20190516', '20190517']
        com = 'technical run, v3 tests'
        run = 45  
     end
     runname eq 'N2R32': begin ; run46 ;; IRAM summerschool
        day = ['20190907', '20190910']
        com = 'technical run, summerschool'
        run = 46  
     end
     runname eq 'N2R33': begin  ; run47 ;; test v3 ;; polar 
        day = ['20190911', '20190924']
        com = 'technical run, polarisation'
        run = 47  
     end
     runname eq 'N2R34': begin ; run48
        day = ['20191008', '20191014']
        com = 'science pool'
        run = 48  
     end
     runname eq 'N2R35': begin ; run48 bis
        day = ['20191015', '20191022']
        com = 'science pool'
        run = 48  
     end
     runname eq 'N2R36': begin  ; run49
        day = ['20191029', '20191104']
        com = 'science pool'
        run = 49  
     end
     runname eq 'N2R37': begin  ; run49 bis
        day = ['20191105', '20191112']
        com = 'science pool'
        run = 49  
     end
     runname eq 'N2R38': begin  ; run50
        day = ['20191210', '20191217']
        com = 'science pool'
        run = 50  
     end
     runname eq 'N2R39': begin  ; run51
        day = ['20200114', '20200121']
        com = 'science pool'
        run = 51  
     end
     runname eq 'N2R40': begin  ; run52
        day = ['20200128', '20200204']
        com = 'science pool'
        run = 52  
     end
     runname eq 'N2R41': begin  ; run53
        day = ['20200211', '20200218']
        com = 'science pool'
        run = 53  
     end
     runname eq 'N2R42': begin  ; run54
        day = ['20200225', '20200303']
        com = 'technical run, polarisation'
        run = 54  
     end
     else: message, /info, 'No run with this name or wrong naming convention: '+ strtrim(runname, 2)
  endcase

  if keyword_set(comment) then comment=com
  if keyword_set(cryorun) then cryorun=run
  return
  
end
