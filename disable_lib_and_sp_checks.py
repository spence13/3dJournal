#!/usr/bin/env python

#############################################
# name: disable_lib_and_sp_checks.py
#############################################

import string
import fractal
import setupAPI as setup
import sys
import os
import re
import subprocess



##############################################
def Main():
##############################################
  (WARD, IPQA_ROOT, BLOCK) = getVars()
  PHYS_ONLY = checkXML(WARD, IPQA_ROOT, BLOCK)
  if (PHYS_ONLY == "no"):
    return 0
  checkDisable(PHYS_ONLY)
  editCfgFile()
  return 0

######################################
# get environment variables
######################################
def getVars():
  WARD = os.environ["WARD"]
  IPQA_ROOT = os.environ["IPQA_ROOT"]
  BLOCK = sys.argv[1]
  return (WARD, IPQA_ROOT, BLOCK)

######################################
# run script that checks for lib|sp
######################################
def checkXML(WARD, IPQA_ROOT, BLOCK):
  cmd = "%s/bin/get_phys_only.pl" % IPQA_ROOT
  arg1 = BLOCK
  arg2 = "%s/doc/%s.attribute.xml" % (WARD, BLOCK)
    
  PHYS_ONLY = "no";
  try:
    PHYS_ONLY = subprocess.check_output([cmd, arg1, arg2])
  except:
    pass
    
  return PHYS_ONLY

######################################
# Disable check if necessary
######################################
def checkDisable(PHYS_ONLY):
  thisCfg = 'setup/checks.cfg'
  setup.registerCustomCheck("setup/intel_checks.cfg")
  setup.initCfg(thisCfg)
    
  if ( PHYS_ONLY == "no_lib" or PHYS_ONLY == "no_sp" ):
    setup.enableCheck(16113,'false')#skip lib check
    setup.enableCheck(16107,'false')#skip lib check
    setup.enableCheck(16002,'false')#skip lib check
    setup.enableCheck(16018,'false')#skip lib check
  if ( PHYS_ONLY == "no_sp" ):
    pass
      
  setup.finishCfg()
  return True

######################################
# Edit checks.cfg -> 15106
######################################
def editCfgFile():
  thisCfg = 'setup/checks.cfg'
  fractal.cfgLoad(thisCfg)
  path = "library_check misc_checks categories \"Special Interface Checks\" checks 15106:Check-for-the-presence-of-a-file checks filePresent parameters \"File Name\""
  

  allFiles = fractal.cfgGetValue(path)
  path = path + " \"" + allFiles + "\""
  allFilesArray = allFiles.split()

  newValue = ""
  for r in allFilesArray:
    if (re.match('.*\.upf', r) or re.match('.*\.v', r) or re.match('.*\.lib', r) or re.match('.*\.sp', r)):
      continue
    else:
      newValue = newValue + r + " "

  newValue = newValue[:-1]
  fractal.cfgModifyValue(path, newValue)
  fractal.cfgSave(thisCfg)
  return True



if __name__ == '__main__':
  sys.exit(Main())


