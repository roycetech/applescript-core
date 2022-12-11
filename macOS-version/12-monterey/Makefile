help:
	@echo "make install - Install Monterey-specific scripts"
	@echo "-s option hides the Make invocation command."

OS_LIBS := control-center user dock

install: $(OS_LIBS)

$(OS_LIBS): Makefile
	../../scripts/compile-lib.sh $@
