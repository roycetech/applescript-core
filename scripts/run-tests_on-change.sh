# -n 1 - is the number of parameters passed.
fswatch -o -e ".*" -i "Test .*\\.applescript$" -i "Makefile" . | xargs -n 1 make test-unit
# fswatch -o -e ".*" -i "Test .*\\.applescript$" . | xargs -n 1 make test-all
