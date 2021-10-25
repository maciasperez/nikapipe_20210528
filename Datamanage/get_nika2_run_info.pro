
pro get_nika2_run_info, nika2run_info

  if n_params() lt 1 then begin
     message, /info, "Calling sequence:"
     print, "get_nika2_run_info, nika2run_info"
     return
  endif

  nruns = 55 ;; to be kept up do date
  
  nika2run_info = create_struct('nika2run', '', $
                                'firstday', '', $
                                'lastday', '', $
                                'cryorun', 0, $
                                'firstscan', 1, $ ; FXD add to avoid confusion in overlapping runs with a day in common
                                'lastscan', 999, $
                                'polar', 0, $ ; FXD add polar info
                                'kidpar_ref', '', $ ; useful at the start
                                'comment', '') 
  
  nika2run_info = replicate(nika2run_info, nruns)

  ;; fill the structure

  i=0
  nika2run_info[i].nika2run  = 'N2R1'
  nika2run_info[i].firstday  = '20150901'
  nika2run_info[i].lastday = '20151106'
  nika2run_info[i].comment   = 'technical run'
  nika2run_info[i].cryorun   = 12
  nika2run_info[i].polar     = 0

  i=1
  nika2run_info[i].nika2run  = 'N2R2'
  nika2run_info[i].firstday  = '20151124'
  nika2run_info[i].lastday = '20160111'
  nika2run_info[i].comment   = 'technical run'
  nika2run_info[i].cryorun   = 14

  i=2
  nika2run_info[i].nika2run  = 'N2R3'
  nika2run_info[i].firstday  = '20160112'
  nika2run_info[i].lastday = '20160121'
  nika2run_info[i].comment   = 'technical run'
  nika2run_info[i].cryorun   = 15

  i=3
  nika2run_info[i].nika2run  = 'N2R4'
  nika2run_info[i].firstday  = '20160122'
  ; To avoid intersection with N2R3 (FXD, Jan 2021)
;;;  nika2run_info[i].firstday  = '20160121'
  nika2run_info[i].lastday = '20160921'
  nika2run_info[i].comment   = 'technical run'
  nika2run_info[i].cryorun   =  16

  i=4
  nika2run_info[i].nika2run  = 'N2R5'
  nika2run_info[i].firstday  = '20160922'
  nika2run_info[i].lastday = '20161010'
  ;Avoid intersection with N2R6 and correct a mistake
  ; FXD Jan 2021/Mar 2021
;  nika2run_info[i].lastday = '20161205'
  nika2run_info[i].comment   = 'technical run'
  nika2run_info[i].cryorun   = 18

  i=5
  nika2run_info[i].nika2run  = 'N2R6'
  nika2run_info[i].firstday  = '20161011'
  ; 20161025 is the real day where there are available scans
;  nika2run_info[i].firstday  = '20161010'
  nika2run_info[i].firstscan = 124
  nika2run_info[i].lastday = '20161205'
  nika2run_info[i].comment   = 'technical run'
  nika2run_info[i].cryorun   = 19

  i=6
  nika2run_info[i].nika2run  = 'N2R7'
  nika2run_info[i].firstday  = '20161206'
  nika2run_info[i].lastday = '20161214'
  nika2run_info[i].comment   = 'technical run'
  nika2run_info[i].cryorun   = 20

  i=7
  nika2run_info[i].nika2run  = 'N2R8'
  nika2run_info[i].firstday  = '20170124'
  nika2run_info[i].lastday = '20170126'
  nika2run_info[i].comment   = 'technical run'
  nika2run_info[i].cryorun   = 21

  i=8
  nika2run_info[i].nika2run  = 'N2R9'
  nika2run_info[i].firstday  = '20170221'
  nika2run_info[i].lastday   = '20170228'
  nika2run_info[i].comment   = 'technical run, reference campaign'
  nika2run_info[i].cryorun   = 22

  i=9
  nika2run_info[i].nika2run  = 'N2R10'
  nika2run_info[i].firstday  = '20170414'
  nika2run_info[i].lastday   = '20170425'
  nika2run_info[i].comment   = 'technical run, Science Verification Phase'
  nika2run_info[i].cryorun   = 23

  i=10
  nika2run_info[i].nika2run  = 'N2R11'
  nika2run_info[i].firstday  = '20170606'
  nika2run_info[i].lastday   = '20170613'
  nika2run_info[i].comment   = 'technical run'
  nika2run_info[i].cryorun   = 24

  i=11
  nika2run_info[i].nika2run  = 'N2R12'
  nika2run_info[i].firstday  = '20171019'
  ;; this includes also the test observations done a few days before the campaign
  ;;nika2run_info[i].firstday  = '20171024'
  nika2run_info[i].lastday   = '20171031'
  nika2run_info[i].comment   = 'science pool, reference campaign'
  nika2run_info[i].cryorun   = 25

  i=12
  nika2run_info[i].nika2run  = 'N2R13'
  nika2run_info[i].firstday  = '20171117'
  nika2run_info[i].lastday   = '20171128'
  nika2run_info[i].comment   = 'technical run, polarisation'
  nika2run_info[i].cryorun   = 26
  nika2run_info[i].polar     = 1

  i=13
  nika2run_info[i].nika2run  = 'N2R14'
  nika2run_info[i].firstday  = '20180112'
  nika2run_info[i].lastday   = '20180123'
  nika2run_info[i].comment   = 'science pool, reference campaign'
  nika2run_info[i].cryorun   = 27

  i=14
  nika2run_info[i].nika2run  = 'N2R15'
  nika2run_info[i].firstday  = '20180213'
  nika2run_info[i].lastday   = '20180220'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 28

  i=15
  nika2run_info[i].nika2run  = 'N2R16'
  nika2run_info[i].firstday  = '20180302'
  nika2run_info[i].lastday   = '20180312'
  nika2run_info[i].comment   = 'technical run, polarisation'
  nika2run_info[i].cryorun   = 29
  nika2run_info[i].polar     = 1

  i=16
  nika2run_info[i].nika2run  = 'N2R17'
  nika2run_info[i].firstday  = '20180313'
  nika2run_info[i].lastday   = '20180320'
  nika2run_info[i].comment   = 'science pool, bad weather'
  nika2run_info[i].cryorun   = 30

  i=17
  nika2run_info[i].nika2run  = 'N2R18'
  nika2run_info[i].firstday  = '20180522'
  nika2run_info[i].lastday   = '20180529'
  nika2run_info[i].comment   = 'technical run, PIMP'
  nika2run_info[i].cryorun   = 31

  i=18
  nika2run_info[i].nika2run  = 'N2R19'
  nika2run_info[i].firstday  = '20180608'
  nika2run_info[i].lastday   = '20180619'
  nika2run_info[i].comment   = 'technical run, polarisation'
  nika2run_info[i].cryorun   = 32
  nika2run_info[i].polar     = 1

  i=19
  nika2run_info[i].nika2run  = 'N2R20'
  nika2run_info[i].firstday  = '20180904'
  nika2run_info[i].lastday   = '20180906'
  nika2run_info[i].comment   = 'technical run, dichroic'
  nika2run_info[i].cryorun   = 34
  nika2run_info[i].polar     = 1

  i=20
  nika2run_info[i].nika2run  = 'N2R21'
  nika2run_info[i].firstday  = '20180918'
  nika2run_info[i].lastday   = '20180925'
  nika2run_info[i].comment   = 'technical run, polarisation'
  nika2run_info[i].cryorun   = 35


  i=21  
  nika2run_info[i].nika2run  = 'N2R22'
  nika2run_info[i].firstday  = '20181001'
  nika2run_info[i].lastday   = '20181009'
  nika2run_info[i].comment   = 'science pool, v2 problem'
  nika2run_info[i].cryorun   = 36

  i=22
  nika2run_info[i].nika2run  = 'N2R23'
  nika2run_info[i].firstday  = '20181031'
  nika2run_info[i].lastday   = '20181106'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 37

  i=23
  nika2run_info[i].nika2run  = 'N2R24'
  nika2run_info[i].firstday  = '20181123'
  nika2run_info[i].lastday   = '20181127'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 38

  i=24
  nika2run_info[i].nika2run  = 'N2R25'
  nika2run_info[i].firstday  = '20181203'
  nika2run_info[i].lastday   = '20181211'
  nika2run_info[i].comment   = 'technical run, polarisation'
  nika2run_info[i].cryorun   = 39
  nika2run_info[i].polar     = 1
  i=25
  nika2run_info[i].nika2run  = 'N2R26'
  nika2run_info[i].firstday  = '20190115'
  nika2run_info[i].lastday   = '20190122'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 40
  
  i=26
  nika2run_info[i].nika2run  = 'N2R27'
  nika2run_info[i].firstday  = '20190128'
  nika2run_info[i].lastday   = '20190206'
  nika2run_info[i].comment   = 'science pool, bad weather'
  nika2run_info[i].cryorun   = 41

  i=27
  nika2run_info[i].nika2run  = 'N2R28'
  nika2run_info[i].firstday  = '20190212'
  nika2run_info[i].lastday   = '20190219'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 42
     
  i=28
  nika2run_info[i].nika2run  = 'N2R29'
  nika2run_info[i].firstday  = '20190305'
  nika2run_info[i].lastday   = '20190312'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 43
  
  i=29
  nika2run_info[i].nika2run  = 'N2R30'
  nika2run_info[i].firstday  = '20190319'
  nika2run_info[i].lastday   = '20190326'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 44

  i=30
  nika2run_info[i].nika2run  = 'N2R31'
  nika2run_info[i].firstday  = '20190516'
  nika2run_info[i].lastday   = '20190517'
  nika2run_info[i].comment   = 'technical run, v3 tests'
  nika2run_info[i].cryorun   = 45
  
  i=31
  nika2run_info[i].nika2run  = 'N2R32'
  nika2run_info[i].firstday  = '20190907'
  nika2run_info[i].lastday   = '20190910'
  nika2run_info[i].comment   = 'technical run, summerschool'
  nika2run_info[i].cryorun   = 46

  i=32
  nika2run_info[i].nika2run  = 'N2R33'
  nika2run_info[i].firstday  = '20190911'
  nika2run_info[i].lastday   = '20190924'
  nika2run_info[i].comment   = 'technical run, polarisation'
  nika2run_info[i].cryorun   = 47
  nika2run_info[i].polar     = 1
  
  i=33
  nika2run_info[i].nika2run  = 'N2R34'
  nika2run_info[i].firstday  = '20191008'
  nika2run_info[i].lastday   = '20191015' ; Tuesday before maintenance (scan 95)
  nika2run_info[i].lastscan =  95  ; FXD March 2021
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 48

  i=34
  nika2run_info[i].nika2run  = 'N2R35'
  nika2run_info[i].firstday  = '20191015'
  nika2run_info[i].firstscan = 96
  nika2run_info[i].lastday   = '20191022'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 48

  i=35
  nika2run_info[i].nika2run  = 'N2R36'
  nika2run_info[i].firstday  = '20191029'
  nika2run_info[i].lastday   = '20191104' ; Monday but ok
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 49

  i=36
  nika2run_info[i].nika2run  = 'N2R37'
  nika2run_info[i].firstday  = '20191105'
  nika2run_info[i].lastday   = '20191112'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 49

  i=37
  nika2run_info[i].nika2run  = 'N2R38'
  nika2run_info[i].firstday  = '20191210'
  nika2run_info[i].lastday   = '20191217'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 50

  i=38
  nika2run_info[i].nika2run  = 'N2R39'
  nika2run_info[i].firstday  = '20200114'
  nika2run_info[i].lastday   = '20200121'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 51

  i=39
  nika2run_info[i].nika2run  = 'N2R40'
  nika2run_info[i].firstday  = '20200128'
  nika2run_info[i].lastday   = '20200204'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 52

  i=40
  nika2run_info[i].nika2run  = 'N2R41'
  nika2run_info[i].firstday  = '20200211'
  nika2run_info[i].lastday   = '20200218'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 53

  i=41
  nika2run_info[i].nika2run  = 'N2R42'
  nika2run_info[i].firstday  = '20200225'
  nika2run_info[i].lastday   = '20200303'
  nika2run_info[i].comment   = 'technical run, polarisation'
  nika2run_info[i].cryorun   = 54
  nika2run_info[i].polar     = 1
  
  i=42
  nika2run_info[i].nika2run  = 'N2R43'
  nika2run_info[i].firstday  = '20200310'
  nika2run_info[i].lastday   = '20200317'
  nika2run_info[i].comment   = 'science pool'
  nika2run_info[i].cryorun   = 55
  
  i=43
  nika2run_info[i].nika2run  = 'N2R44'
  nika2run_info[i].firstday  = '20200806'
  nika2run_info[i].lastday   = '20201006' 
  nika2run_info[i].comment   = "Bilal's summer run"
  nika2run_info[i].cryorun   = 56

  i=44
  nika2run_info[i].nika2run  = 'N2R45'
  nika2run_info[i].firstday  = '20201020'
  nika2run_info[i].lastday   = '20201103'
  nika2run_info[i].comment   = 'science pool, first and second NIKA2 Summer pool'
  nika2run_info[i].cryorun   = 57
  
  i=45
  nika2run_info[i].nika2run  = 'N2R46'
  nika2run_info[i].firstday  = '20201110'
  nika2run_info[i].lastday   = '20201117'
  nika2run_info[i].lastscan = 121
  nika2run_info[i].comment   = 'Polarisation commissionning'
  nika2run_info[i].cryorun   = 58
  nika2run_info[i].polar     = 1

                                ; FXD: overlap at 20201117, to remove
                                ; the ambiguity, use nk_scan2run (<=
                                ; scan 121)
  i=46
  nika2run_info[i].nika2run  = 'N2R47'
  nika2run_info[i].firstday  = '20201117'
  nika2run_info[i].firstscan = 122
  nika2run_info[i].lastday   = '20201124'
  nika2run_info[i].comment   = 'science pool, third NIKA2 Summer pool'
  nika2run_info[i].cryorun   = 59
  nika2run_info[i].polar     = 0

  i=47
  nika2run_info[i].nika2run  = 'N2R48'
  nika2run_info[i].firstday  = '20201208'
  nika2run_info[i].lastday   = '20201215'
  nika2run_info[i].comment   = 'science pool, first NIKA2 2020 Winter semester pool'
  nika2run_info[i].cryorun   = 60
  nika2run_info[i].polar     = 0

  i=48
  nika2run_info[i].nika2run  = 'N2R49'
  nika2run_info[i].firstday  = '20210112'
  nika2run_info[i].lastday   = '20210126'
  nika2run_info[i].comment   = 'science pool, second and third NIKA2 2020 Winter semester pool'
  nika2run_info[i].cryorun   = 61
  nika2run_info[i].polar     = 0
  
  i=49
  nika2run_info[i].nika2run  = 'N2R50'
  nika2run_info[i].firstday  = '20210209'
  nika2run_info[i].lastday   = '20210223'
  nika2run_info[i].comment   = 'science pool, 4th and 5th NIKA2 2020 Winter semester pool'
  nika2run_info[i].cryorun   = 62
  nika2run_info[i].polar     = 0
  
  i=50
  nika2run_info[i].nika2run  = 'N2R51'
  nika2run_info[i].firstday  = '20210309'
  nika2run_info[i].lastday   = '20210323'
  nika2run_info[i].comment   = 'science pool, 6th and 7th NIKA2 2020 Winter semester pool'
  nika2run_info[i].cryorun   = 63
  nika2run_info[i].polar     = 0
  
  i=51
  nika2run_info[i].nika2run  = 'N2R52'
  nika2run_info[i].firstday  = '20210525'
  nika2run_info[i].lastday   = '20210601'
  nika2run_info[i].comment   = '8th NIKA2 2020 Winter semester pool'
  nika2run_info[i].cryorun   = 64
  nika2run_info[i].polar     = 0

  i=52
  nika2run_info[i].nika2run  = 'N2R53'
  nika2run_info[i].firstday  = '20210708'
  nika2run_info[i].lastday   = '202107010'
  nika2run_info[i].comment   = 'technical run'
  nika2run_info[i].cryorun   = 65
  nika2run_info[i].polar     = 0

  i=53
  nika2run_info[i].nika2run  = 'N2R54'
  nika2run_info[i].firstday  = '20210921'
  nika2run_info[i].lastday   = '20210925'
  nika2run_info[i].comment   = 'technical run'
  nika2run_info[i].cryorun   = 66
  nika2run_info[i].polar     = 1
  
  i=54
  nika2run_info[i].nika2run  = 'N2R55'
  nika2run_info[i].firstday  = '20211017'
  nika2run_info[i].lastday   = '20211109'
  nika2run_info[i].comment   = 'science pool, 1st and 2nd NIKA2 2021 summer semester pool'
  nika2run_info[i].cryorun   = 67
  nika2run_info[i].polar     = 0
  
  
  for irun = 0, nruns-1 do begin
     nk_get_kidpar_ref, '100', nika2run_info[irun].firstday, info, kidpar_file, $
                        /noread  ; Reading kidpar files takes time and is useless here
     nika2run_info[irun].kidpar_ref = kidpar_file
  endfor
  
  return
  
end
