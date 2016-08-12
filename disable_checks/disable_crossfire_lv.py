#!/usr/bin/env python

#############################################
# name: disable_crossfire_lv.py
#############################################

import fractal
import string
import sys
import os
import re
import subprocess

##############################################
def Main():
##############################################
  (WARD, IPQA_ROOT) = getVars()
  waive_exists = checkWaiveAlreadyExists(WARD, IPQA_ROOT)
  addWaive(waive_exists, IPQA_ROOT)
  #editCfgFile()
  return 0


######################################
# get environment variables
######################################
def getVars():
  WARD = os.environ["WARD"]
  IPQA_ROOT = os.environ["IPQA_ROOT"]
  return (WARD, IPQA_ROOT)

  
######################################
# Disable check if necessary
######################################
def checkWaiveAlreadyExists(WARD, IPQA_ROOT):
  
  param_file = open('%s/data/default/prod.param' %IPQA_ROOT , 'r+')

  for line in param_file:
    words = line.split("'")
    if (words[0] == "16007:"):
      for w in words:
        if (w == "waive"):
          waive_exists = True
          break
        else:
          waive_exists = False
  
  param_file.close()
  return waive_exists

######################################
# add waive to prod.param
######################################
#15106:'File Name','$REQUIRED_FILES  $BLOCK.sp $BLOCK.oas $BLOCK*.@NOISE@ @PDN@ @RVFILES@ @ERCCFG@'
#16007:'top_cell','$BLOCK'//'runset','ipqa_prod'//'waive','drcdf_high_fill'//'oas','@OASIS@'

def addWaive(waive_exists, IPQA_ROOT):

  param_file = open('%s/data/default/prod.param' % IPQA_ROOT, 'r+')
  param_file.seek(0,0)
  new_file = ""

  if (waive_exists == True):
    for line in param_file:
      seg = line.split("//")
      if (len(seg) == 1):
        new_file += seg[0]
        continue
      else:
        for s in seg:
          if (s[1] == "w" and s[4] == "v"):
            new_file += "//'waive','check_sp drcdf_high_fill trclvs'"
          elif (s[0] == "1" and s[1] == "6"):
            new_file += s
          else:
            new_file = new_file + "//" + s  
    param_file.seek(0,0)
    param_file.write(new_file)
    param_file.truncate()
    param_file.close()

  else:
    param_file.seek(0,2)
    param_file.write("//'waive','check_sp trclvs'")
    param_file.close()

  return new_file

######################################
# Edit checks.cfg 
######################################
# def editCfgFile():
#   thisCfg = 'setup/checks.cfg'
#   fractal.cfgLoad(thisCfg)
#   path = "library_check misc_checks categories intel_checks checks 16007:Running-LVS-on-Block categories lay_checks checks lvs_check parameters waive"
  

#   existingWaives = fractal.cfgGetValueList(path)
  
#   newWaives = "check_sp trclvs"
#   for i in existingWaives:
#     newWaives = newWaives + " " + i
#     path = path + " " + i
  

#   fractal.cfgModifyValue(path, newWaives)
#   fractal.cfgSave(thisCfg)

#   return 1




if __name__ == '__main__':
  sys.exit(Main())

