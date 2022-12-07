# applescript-core

Add a title image if available.

This is the name of the project. It describes the whole project in one sentence, and helps people understand what the main goal and aim of the project is.


## Project Description

This is a collection of AppleScript libraries that we can reuse within user-specific AppleScripts. It provides core functionality like:

* Import/deployment of another AppleScript library
* File logging
* String interpolation
* Exception handling
* Session management
* Configuration management
* Common utilities for string, list, and dictionary.
* Unit testing

Demo(Images, Video Links, Live Demo Links)

The quality of a README description often differentiates a good project from a bad project. A good one takes advantage of the opportunity to explain and showcase:

*   [ ] What your application does
* Provides basic unit testing
* Quick spot checking
* Essential 


### Technologies/Libraries

[ ] Why you used the technologies you used
Include Links
* Script Editor
* plutil
* PlistBuddy
* JSON Helper - Freely available JSON-AppleScript library.  https://apps.apple.com/us/app/json-helper-for-applescript/id453114608?mt=12.


## Special Gotchas of your projects (Problems you faced, unique elements of your project)

[ ] The built-in property list file handling may cause blocking so an alternative approach to use the plutil command line is used.


## Table of Contents (Optional)

If your README is very long, you might want to add a table of contents to make it easy for users to navigate to different sections easily. It will make it easier for readers to move around the project with ease.


## How to Install and Run the Project

1. Run `make install`. It will install the essential libraries under `~/Library/Script Libraries`. It will also install basic sounds and property files under `~/applescript-core/`.  See the ./Makefile for more information.
2. To test that it works, open the files inside examples using Script Editor and run them.
3. You will see the output

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

Copyright (c) [2022] [Royce Remulla]

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


## Additional README Sections

### Badges

Badges aren't necessary, but using them is a simple way of letting other developers know that you know what you're doing.

Having this section can also be helpful to help link to important tools and also show some simple stats about your project like the number of forks, contributors, open issues etc...

Below is a screenshot from one of my projects that shows how you can make use of badges:

badges

The good thing about this section is that it automatically updates it self.

Don't know where to get them from? Check out the badges hosted by shields.io. They have a ton of badges to help you get started. You may not understand what they all represent now, but you will in time.

### How to Contribute to the Project

This mostly will be useful if you are developing an open-source project that you will need other developers to contribute to. You will want to add guidelines to let them know how they can contribute to your project.

Also it is important to make sure that the licence you choose for an open-source projects is correct to avoid future conflicts. And adding contribution guidelines will play a big role.

Some of the most common guidelines include the Contributor Covenant and the Contributing guide. Thes docs will give you the help you need when setting rules for your project.

### Include Tests

Go the extra mile and write tests for your application. Then provide code examples and how to run them.

This will help show that you are certain and confident that your project will work without any challenges, which will give other people confidence in it, too


## Extra points

Here are a few extra points to note when you're writing your README:

*   Keep it up-to-date - It is a good practise to make sure your file is always up-to-date. In case there are changes make sure to update the file where necessary.
*   Resources
