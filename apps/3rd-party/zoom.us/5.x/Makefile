#

help:
	@echo "make install - zoom.us and related libraries."
	@echo "-s option hides the Make invocation command."

OS_LIBS := zoom zoom-actions zoom-participants zoom-window dec-user-zoom

$(OS_LIBS): Makefile
	../../scripts/compile-lib.sh $@

install: $(OS_LIBS)
	./setup-zoom-configurations.applescript

