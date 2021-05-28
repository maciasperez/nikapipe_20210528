import numpy as np
import os
import pdb
import read_nika_data as rnd


scanst_flag = {'scannothing':np.int(0),'scanloadded':np.int(1),'scanStarted':np.int(2),'scandone':np.int(3),'subscanStarted':np.int(4),
           'subscanDone':np.int(5),'scanbackontrack':np.int(6),'subscantuning':np.int(7),'scantuning':np.int(8),'scannewfile':np.int(9)}
scanst_val = ['scannothing','scanloadded','scanStarted','scandone','subscanStarted','subscanDone',
              'scanbackontrack','subscantuning','scantuning','scannewfile']
"""
This is taken directly from the IDL pipeline version nk_, which in turn is taken from
nika_
"""

def nika_flags(data):

  """
  Call different nika flags codes

  Parameters
  ----------
  data: nika_data object

  """
  # update acquisition flags
  acqflag2pipeflag(data)

  return


def acqflag2pipeflag(data):

  '''
        
                 transform acquisition flags into pipeline flags
        Parameters:
        
        Input:
                 data: nika_data class
        Output:
                 Modify flags
        Modification:
                 Created from nk_acqflag2pipeflag
  '''

  # get nika k_flag data 
  kflag = (rnd.get_nikavar_data(data,'k_flag')).astype(long)

  flag_list = [2,5]
  data.pipeflag = kflag * 0
  for flag in flag_list:
      # verify if flagged: (kflag & (1 << flag)) 
      # move flagvales + 12:  << 12
      data.pipeflag = data.pipeflag | ((kflag & (1 << flag)) << 12)
  return

def nan_and_zero_flag(data):
  """
  
  """
  # check where RF_didq is finite
  pos = np.where(data.name_data_d == 'RF_didq')
  if len(pos) > 0:
    wpos = np.where(np.isfinite(data.RF_didq) == False)
    if len(wpos) > 0:
      data.pipeflag[wpos[0]] += 2**7
  # check if I is set strictly to zero
  pos = np.where(data.name_data_d == 'I')
  if len(pos) > 0:
    wpos = np.where(data.I == 0)
    if len(wpos) > 0:
      data.pipeflag[wpos[0]] += 2**7
  # check if Q is set strictly to zero
  pos = np.where(data.name_data_d == 'Q')
  if len(pos) > 0:
    wpos = np.where(data.I == 0)
    if len(wpos) > 0:
      data.pipeflag[wpos[0]] += 2**7

  return


def flag_scanst(data):
    return


def tuning_flag_skydip(data):
    return


def tuning_flag(data):
    return



def tdil_flag(data):
    return

def speed_flag(data):
    return

def cut_scans(data):
    return
