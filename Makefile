export CPPFLAGS = -U_FORTIFY_SOURCE

COBFLAGS = -m
MAINFLAGS = -x
COBC = cobc
LIBPATH = COB_LIBRARY_PATH=./lib

MODULES = lib/ACCTMGMT lib/VIEWTRANS lib/LEDGERSM lib/AUTHUSER

all: dirs $(MODULES) bin/fintrust

dirs:
	mkdir -p lib bin

lib/ACCTMGMT:
	$(COBC) $(COBFLAGS) -o lib/ACCTMGMT programs/account_management.cbl

lib/VIEWTRANS:
	$(COBC) $(COBFLAGS) -o lib/VIEWTRANS programs/view_transactions.cbl

lib/LEDGERSM:
	$(COBC) $(COBFLAGS) -o lib/LEDGERSM programs/ledger_summary.cbl

lib/AUTHUSER:
	$(COBC) $(COBFLAGS) -o lib/AUTHUSER programs/authenticate_user.cbl

bin/fintrust:
	$(COBC) $(MAINFLAGS) -o bin/fintrust mainmenu.cbl

run:
	$(LIBPATH) ./bin/fintrust

clean:
	rm -f lib/*.so bin/fintrust

.PHONY: all dirs run clean