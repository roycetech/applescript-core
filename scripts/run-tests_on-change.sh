fswatch -o -e ".*" -i "Test .*\\.applescript$" . | xargs -n1 -I{} make test-unit
