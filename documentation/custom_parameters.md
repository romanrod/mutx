How to pass parameters to a test task execution?
==============

You can send parameters to a test or task execution and your tests can take that data to run in a certain way you need or want.

There are basically three types of fields you use on task or test creation and or edition: text, select list or JSON

This fields can be setted as required values and or with a default value.

All custom parameters must be defined on Custom Parameters section:

When you associate a custom parameter to a task or test, the user of the task will be able to pass values to the execution

As an example, you can think about using custom parameters to provide the environmnet to the execution so your tests can point to a given environment


How to get custom parameters
==============

Well, custom parameters are passed to the execution in the same way you can pass to ENV constant.
From the execution, you can catch the custom parameter from ENV constant. In Ruby ENV is a Hash

For example, if you passed env=beta you will be able to catch the value like:

      ENV['env']


You can also use Mutx from you Ruby code in order to get the value from the custom parameter like:
      
      require 'mutx'
      $CUSTOM = Mutx::Custom::Params.get

      $CUSTOM.env
      # => will return the value passed to env custom param

