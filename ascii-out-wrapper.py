import FWCore.ParameterSet.Config as cms
import sys,os
sys.path.append(os.path.dirname(sys.argv[-1]))
config = os.path.basename(sys.argv[-1]).replace(".py","")
process = getattr(__import__(config,fromlist=["process"]),"process")
outputs = process.outputModules_()
for output in outputs:
	setattr(process,output,cms.OutputModule("AsciiOutputModule", outputCommands = getattr(getattr(process,output),"outputCommands")))
