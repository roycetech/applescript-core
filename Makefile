help:
	@echo "make install_core - install the core AppleScript libraries in the current user's Library/Script Library folder"
	@echo "make compile_library - compiles a script library.  e.g. make compile_lib SOURCE=src/std"
	@echo "-s option hides the Make invocation command."

install:
	pip install -Ur requirements.txt

compile_lib:
	./compile.sh $(SOURCE)
