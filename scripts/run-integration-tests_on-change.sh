fswatch -o -e ".*" -i "Test .*\\.applescript$" -i "Makefile" . | xargs -n1 -I{} make test-integration
