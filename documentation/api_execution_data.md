Execution
============================


With Mutx you can add data to the execution. Then you can find that data through the API by using

    /mutx/api/results/<result id>/data

This will give you the JSON (a part of the result) with the data you setted while your execution was running.

---------------------------------------

How to add execution data
============================

Basically you have to add mutx gem to your project

    require 'mutx'

Before, you have to add it to your Gemfile

    # Gemfile
    gem 'mutx'


After adding the gem to your project, you can do:

    Mutx::Custom::Execution.add_data("my_data_key", "some value for data key")


Once the execution it is finished, you can see the values through:

    http::/host:port/mutx/api/results/<result_id>/data

And you'll see something like:

    {
      type: "result",
      _id: 1427901370053,
      status: "stopped (Inactivity Timeout reached)",
      execution_data: {
        my_data_key: "some value for data key"
      }
    }


Think about this for integration tests.

---------------------------------------

Path to output dir
============================

If you want to save files you should use Mutx output dir path by using

    "#{Mutx::Custom::Execution.output_path}/<your_file_name.extension>"