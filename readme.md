**Note:** this read-me was originally made back when Mac OS X 10.1 was released. A lot of things have changed with macOS and development environment have changed. Some changes to the read-me have been made, but some sections have not been poked. For instance, not a lot of people use CVS nowadays, and ProjectBuilder has been replaced by Xcode.

# RCEnvironment

RCEnvironment is a Mac OS X 10.1 or higher preference pane that allows a user to edit their `~/.MacOSX/environment.plist` file. This file is simply a property list of keys and values that the login system will read and load into the process environment of all applications that are launched when the user logs in. These variables are the same as environment variables that can be created in a command line shell (eg: sh or csh), but they also can be seen by GUI applications. In this, these environment variables are somewhat similar to Windows' Environment User Variables.

While the Xcode application that Apple provides can be used to edit this file, that tool allows more flexibility than should be specified in the environment file, plus you have to install the developer tools to get that tool, while this is a simple editor that ensures the file is setup correctly and does not require the developer tools.


# Installation and Usage

To install RCEnvironment.prefPane just copy it to `~/Library/PreferencePanes` or `/Library/PreferencePanes` and launch System Preferences or System Settings (depending on the OS release).  You may have to create the directory first.

Using RCEnvironment is very simple.  Use the '+' and '-' buttons to add or remove variables from the list.  Once you have set up the list of variables the way you want, just press the 'Apply' button.  Duplicate and blank names are not allowed.  At any time, you can 'Revert' back to the current state of variables.

Once you have saved changes to your environment, you must logout and log back in for any changes to take effect.


# Example Uses

Example uses of this are somewhat contrived, but still can be useful.  None of the examples below are particularly advocated, they are just examples of what can be done.

## Shell Environment Variables

Setting up your shell environment variables differs fairly strongly between sh and csh. If you worked a lot with both shell environments, you could setup your environment for the shells using RCEnvironment, and then not need to do that in the various shell configuration files. The problem of having to re-login to get these changes to take effect does put a damper on this kind of usage, but for many environment variables, they probably wouldn’t change often enough to be an issue.

## Affecting CVS in ProjectBuilder

ProjectBuilder is one application that can benefit from RCEnvironment. In particular, ProjectBuilder now has builtin CVS support for working with a source repository. However, many people desire CVS to be able to use a different command to access a repository, usually to deal with security issues. Unfortunately, ProjectBuilder does not provide a way to deal with that.  By using RCEnvironment, you can setup a `CVS_RSH` variable which will be passed through ProjectBuilder and to the CVS core to do the proper thing.

Many standard UNIX CLI tools have one or more environment variables that can be setup to modify their behavior similarly to `CVS_RSH`.  If you use or create an application that uses a UNIX CLI tool to perform its work, you may be able to change the way the command works by using the environment to modify some variable it uses. Of course, any changes you make to how the command works using this may cause the calling application to fail if the CLI tool does not work the way it needs to anymore.

## Additional Library Paths

In some situations (probably mostly for developers), it might be useful to set the `DYLD_FRAMEWORK_PATH` and/or `DYLD_LIBRARY_PATH` (which adds additional directories searched for frameworks and shared libraries respectively) so that these paths are searched for applications or tools launched from the UI.


# Caveats

There are two things that you should be aware of when creating an environment file.

1. Changes only take effect on the next login.

2. '$value' values do not expand like in a shell environment. So if you specify a environment variable `HISTFILE` with a value of '$HOME/.history', you will not get '/somepath/to/user/.history', you’ll get '$HOME/.history'.

3. Changing the `PATH` variable is only advised if you know what you are doing. This variable can affect a variety of programs, including the developer tools, and shell environments.  For example, a user tried to set his path to '$PATH:/usr/local/bin', not knowing about condition #2 above and found all of a sudden they could not compile anything or use Terminal.  So be careful.

The application will notify you of these two latter issues (you can disable the warnings).  If you do find that applications are behaving strangely, remove the environment file or move it to a different name, and log out and back in again.


# Feedback

We are very interested in any comments, suggestions, bug reports, or any other feedback on RCEnvironment; please send them to `tools@rubicode.com`.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(Or, the short version:  If it breaks, or breaks your system, you get to keep the pieces. :-) )


# History

1.3	Compiled as universal binary for usage on Intel Macs.
	Fixed memory leak.

1.2.2	Fixed issue with using functionality that was only available in Panther.

1.2.1	Fixed an issue with version number and about text not showing up on the About panel. Fixed a problem with the value inspector panel not being able to edit the value properly always.

1.2	Fixed a problem where changing a variable's name would not result in that variable's name being properly changed.  Thanks to Oliver Busch for finding this bug.  Added ability to edit the variable in a scrolling text view so that you can easily edit very large strings.  Updated the project so that it can be localized.  Added Italian localization thanks to Marcello Teodori.  Added Chinese localization thanks to Shoekai Yeh.

1.1.1	Added warnings to notify the user if it looks like they are trying to do a variable expansion or they are trying to edit the PATH variable.

1.1	Cleaned up code to insure that the user has finished editing a field before saving a file, or aborting editing if they are reverting. Added key sorting, but only when the user is not editing any fields. Added a backup file and ability to revert to it. Added version number information to the info panel and fixed some issues with how the module was named when loaded into System preferences.

1.0	Initial release.


Copyright © 2002 Doug McClure
