# applescript-core

Add a title image if available.

A design for writing AppleScripts that utilizes re-usability of components.

This is the name of the project. It describes the whole project in one sentence, and helps people understand what the main goal and aim of the project is.


## Project Description

AppleScript Core is a collection of valuable and simple custom AppleScripts that allows you to write automation AppleScripts faster and more efficiently than ever. It provides a variety of ready-to-use script libraries, libraries that provide essential functionalities that you can use in your scripts. It provides application wrapper scripts that can be used to interact with the supported applications. 

It provides core functionality like:

* Import/deployment of another AppleScript library
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

1.  config-system.plist - 
2.  config-user.plist - contains 

### Technologies/Libraries

[ ] Why you used the technologies you used
Include Links
* Script Editor
* plutil
* PlistBuddy
* JSON Helper - Freely available JSON-AppleScript library.  https://apps.apple.com/us/app/json-helper-for-applescript/id453114608?mt=12.


## Special Gotchas of your projects (Problems you faced, unique elements of your project)

[ ] The built-in property list file handling may cause blocking so an alternative approach to use the plutil command line is used.
[ ] Permission Error. Apps created in some ways are being blocked by Apple regardless if you try to re-create the app. The only solution I found is to rename the script, and recreate in the recommended way found in the script header.


## Table of Contents (Optional)

If your README is very long, you might want to add a table of contents to make it easy for users to navigate to different sections easily. It will make it easier for readers to move around the project with ease.


## How to Install and Run the Project

1. Run `make install`. It will install the essential libraries under `~/Library/Script Libraries`. It will also install basic sounds and property files under `~/applescript-core/`.  See the ./Makefile for more information.
2. To test that it works, open the files inside examples using Script Editor and run them.
3. You will see the output.


If you are working on a project that a user needs to install or run locally in a machine like a "POS", you should include the steps required to install your project and also the required dependencies if any.

Provide a step-by-step description of how to get the development environment set and running.


## How to Use the Project (Developing)

Provide instructions and examples so users/contributors can use the project. This will make it easy for them in case they encounter a problem – they will always have a place to reference what is expected.
You can also make use of visual aids by including materials like screenshots to show examples of the running project and also the structure and design principles used in your project.
Also if your project will require authentication like passwords or usernames, this is a good section to include the credentials.

You'll need to populate the config-system.plist with some default values:
*   Project Path - Used to locate the test files for testing.



## Credits

* []() - For help with design and testing.
* []() - For help with design and testing.

If you worked on the project as a team or an organization, list your collaborators/team members. You should also include links to their GitHub profiles and social media too.

Also, if you followed tutorials or referenced a certain material that might help the user to build that particular project, include links to those here as well.

This is just a way to show your appreciation and also to help others get a first hand copy of the project.


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


## Additional README Sections

### How to Contribute to the Project

This mostly will be useful if you are developing an open-source project that you will need other developers to contribute to. You will want to add guidelines to let them know how they can contribute to your project.

Also it is important to make sure that the license you choose for an open-source projects is correct to avoid future conflicts. And adding contribution guidelines will play a big role.

Some of the most common guidelines include the Contributor Covenant and the Contributing guide. These docs will give you the help you need when setting rules for your project.

### Include Tests

Go the extra mile and write tests for your application. Then provide code examples and how to run them.

This will help show that you are certain and confident that your project will work without any challenges, which will give other people confidence in it, too


## Extra points

Here are a few extra points to note when you're writing your README:

*   Keep it up-to-date - It is a good practice to make sure your file is always up-to-date. In case there are changes make sure to update the file where necessary.
*   Resources
