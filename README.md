# applescript-core

AppleScript Core Framework

An framework and collection of libraries for for writing AppleScripts that utilizes re-usability of components.

This README is a work in progress and I'm planning on creating a simpler shorter version in the near future.

## Project Description

AppleScript Core is a collection of valuable and simple custom AppleScripts that allows you to write automation AppleScripts faster and more efficiently than ever. It provides a variety of ready-to-use script libraries, libraries that provide essential functionalities that you can use in your scripts. It provides application wrapper scripts that can be used to interact with the supported applications. 

It provides core functionality like:

* File logging
* String interpolation
* Exception handling
* Session management
* Configuration management
* Common utilities for string, list, and dictionary.
* Unit testing

This project uses a monorepo approach for the project structure.

Demo(Images, Video Links, Live Demo Links)

The quality of a README description often differentiates a good project from a bad project. A good one takes advantage of the opportunity to explain and showcase:

*   [ ] What your application does
* Provides basic unit testing
* Quick spot checking
* Essential 

### Configuration Files

1.  config-system.plist - contains path to CLIs used by some scripts.
2.  config-user.plist - contains user-specific configurations.

### Technologies/Libraries

* Script Editor - The default AppleScript editor that comes with macOS.
* plutil - A command-line utility that comes with macOS for accessing property list files that is a more performant than the Finder application.
* PlistBuddy - For accessing dictionary contents in a plist.
* JSON Helper - Freely available JSON-AppleScript library.  https://apps.apple.com/us/app/json-helper-for-applescript/id453114608?mt=12.


## Special Gotchas of your projects (Problems you faced, unique elements of your project)

* The built-in property list file handling may cause blocking so an alternative approach to use the plutil command line is used.

### Limitations

* I have not worked out automating apps across desktop spaces. While some may work coincidentally, deliberate testing is required to improve their reliability.

## Table of Contents (Optional)

If your README is very long, you might want to add a table of contents to make it easy for users to navigate to different sections easily. It will make it easier for readers to move around the project with ease.


## How to Install and Run the Project

1. Run `make install`. It will install the essential libraries under `~/Library/Script Libraries`. It will also install basic sounds and property files under `~/applescript-core/`.  See the [Makefile](./Makefile) for more information.
2. To test that it works, open the files inside examples using Script Editor and run them.
3. You will see the output.


## How to Use the Project (Developing)

Provide instructions and examples so users/contributors can use the project. This will make it easy for them in case they encounter a problem – they will always have a place to reference what is expected.
You can also make use of visual aids by including materials like screenshots to show examples of the running project and also the structure and design principles used in your project.

You'll need to populate the config-system.plist with some default values:
*   Project Path - Used to locate the test files for testing.

### Testing (WIP)

Run `make test` to run the tests.

When developing, install fswatch and run `fswatch -o -e ".*" -i "Test\\.applescript$" . | xargs -n1 -I{} make test` to automatically run the tests after each file change.

## Credits

* [eugene-manalo](https://github.com/eugene-manalo) - For the Google Chrome library implementation.
* [josephinesayco](https://github.com/josephinesayco) - For help with design and testing.


## License

MIT License

Copyright (c) [2023] [Royce Remulla]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


### How to Contribute to the Project

We welcome contributions, feedback, and suggestions from the community! If you find a bug, have a feature request, or want to contribute to AppleScript Core, here are a few ways you can get involved:

### Create a Pull Request (PR)

If you have a code improvement, bug fix, or new feature you'd like to contribute, please submit a Pull Request. We appreciate the effort and value your contributions to make AppleScript Core better for everyone. Please ensure that your Pull Request follows our guidelines and coding standards.

### Provide Feedback or Suggestions

Your feedback is crucial for the growth and improvement of AppleScript Core. If you have any suggestions, ideas, or general feedback, please don't hesitate to share them. You can leave comments on specific files or sections in the repository or open an Issue to start a discussion.

### Report Bugs or Issues

If you encounter any bugs or issues while using AppleScript Core, please let us know by creating a GitHub Issue. Be sure to provide detailed steps to reproduce the problem, along with any relevant information. This helps us investigate and address the issue effectively.

### Spread the Word

If you find AppleScript Core useful, consider sharing it with others who might benefit from it. Spread the word on social media, write a blog post, or mention it in relevant communities. Your support helps us reach a wider audience and encourages others to contribute as well.

We value and appreciate all contributions, whether big or small. Together, let's make AppleScript Core even better!

### Include Tests

The libraries where tested mainly on macOS Monterey. I have tried some scripts on Big Sur and I was able to get a successful result. I have also worked on using macOS Ventura as well. Most back-end libraries should work without issues on any recent version of macOS. On the other hand, scripts that interact with the UI like the app wrapper libraries are almost guaranteed to fail each time a vendor releases updates to their apps.

This project includes a system for doing spot checking by utilizing a stay open app menu to manage the case number to be tested.
This project also includes its own unit testing functionality to ensure code quality. I plan to migrate the unit tests into ASUnit which I believe is a great library, having tried it out very recently.

## License

MIT License

Copyright (c) 2023 Royce Remulla

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
