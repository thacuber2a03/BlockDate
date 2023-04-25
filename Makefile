# assuming PLAYDATE_SDK_PATH is already set

PDC="$(PLAYDATE_SDK_PATH)/bin/pdc"
SIM="$(PLAYDATE_SDK_PATH)/bin/PlaydateSimulator"
PDCFLAGS=-k

main:
	$(PDC) $(PDCFLAGS) ./src ./Playtris.pdx

run:
	$(PDC) $(PDCFLAGS) ./src ./Playtris.pdx
	$(SIM) ./Playtris.pdx
