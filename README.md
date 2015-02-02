# StepLib Step template

Step template repository.
Contains everything what's required for a
valid [StepLib](http://www.steplib.com/) Step.

To create your own Step:

1. Create a new repository on GitHub
2. Copy the files from this repository into your repository
3. Commit and push it

Hurray, you just created your first Step repository!
You can now start coding and when you're ready
you can submit your Step to the [Open Step Library](http://www.steplib.com/).


## Structure

### step.sh

This is the **entry point of the Step**. A StepLib
system will execute this file when it runs the Step.
You can run other scripts and programs from
*step.sh*. For example if you want to write your
Step in ruby then all you have to include in the *step.sh*
file is the code to run your own ruby script,
something like this:

  #!/bin/bash

  THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

  ruby "${THIS_SCRIPT_DIR}/my_ruby_script.rb"
  exit $?


**inputs**: a Step should get it's inputs through
*environment variables*. These inputs can be (and should be)
specified in the *step.yml* description of the Step.

**exit code**: the exit code generated by step.sh
is interpreted as the success/failure code of the whole Step.
If it returns 0 the Step will be considered as successful.
If it returns with a greater than 0 exit code then
the Step is considered to be failed.


### step.yml

Description of the step in YAML format.

Specifies information for StepLib users like what platforms
the Step supports, what's the official website of the
Step, where can a user find the Step's code and
where can a user fork the Step.

Also defines an input list for the Step which then
can be presented as User Interface for the Step
and a StepLib compatible system can interpret these
inputs and map the user input values to
environment variables which will be available for the Step.

For a full description of the *step.yml* description
file see the documentation on GitHub: [https://github.com/steplib/steplib/blob/master/docs/step_format.md](https://github.com/steplib/steplib/blob/master/docs/step_format.md)


### LICENSE

We don't accept steps into the StepLib without a license included in it!
Read more about why it's important to have a license file
in your open source repository on GitHub: [https://github.com/steplib/steplib/blob/master/templates/step/LICENSE](https://github.com/steplib/steplib/blob/master/templates/step/LICENSE).


### README.md

Technically README is not required but we strongly suggest
against not using one.

It can be a very simple description of what your Step does,
in just a couple of sentences.

Best practice is to include information about how
someone else can contribute to the development of the Step.

You can also include a link to the StepLib website, including your
own Step's page on StepLib (once it's submitted
into the Open StepLib collection), something like this:

This Step is part of the [Open StepLib](http://www.steplib.com/),
you can find its page on StepLib [here](http://www.steplib.com/step/your-step-id).


## How to submit your Step into the Open Step Library

To submit a Step to the [Open Step Library](http://www.steplib.com/)
you have to create a pull-request in the StepLib's spec repository
and include your step's `step.yml` description file
in the **steps/** folder.
