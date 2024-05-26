fswatch -o -e ".*" -i "Test .*\\.applescript$" -i "Makefile" . | xargs -n 1 make test-integration
