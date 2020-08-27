import FWCore.ParameterSet.Config as cms
import sys
config = sys.argv[-1].replace(".py","")
process = getattr(__import__(config,fromlist=["process"]),"process")
process.FastTimerService.writeJSONSummary = cms.untracked.bool(True)
process.FastTimerService.jsonFileName = cms.untracked.string('%s.resources.json' % config)
