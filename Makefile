# assuming PLAYDATE_SDK_PATH is already set

PDC="$(PLAYDATE_SDK_PATH)/bin/pdc"
SIM="$(PLAYDATE_SDK_PATH)/bin/PlaydateSimulator"
PDCFLAGS=-k

IN="./src"
OUT="./BlockDate.pdx"

main:
	$(PDC) $(PDCFLAGS) $(IN) $(OUT)

run: main
	$(SIM) $(OUT)
