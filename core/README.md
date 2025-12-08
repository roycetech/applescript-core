# Levels

Determines the dependency level of a given script.

*   Level 1 - sits at the top of the script hierarchy and is considered critical to all other scripts because of it's logging, basic text, and script decoration capabilities.
*   Level 2 - contains scripts that has minimal dependencies, usually to level 1 scripts and the standard (std.applescript).
*   Level 3 - depend only on level 2 and level 1 scripts

1st party Apple apps are considered Level 4 scripts.

## Exceptions
`std.applescript` may be considered a level 1 script but behaves differently depending on the macOS version. It has a special build mechanism that takes the macOS version into account. It must be built right after the Level 1 scripts.