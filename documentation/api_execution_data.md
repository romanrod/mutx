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

Once the execution is finished, you can see the values through:

    api/results/<result_id>/data

And you'll see something like:

    {
      "type": "result",
      "_id": 1427901370053,
      "status": "finished",
      "execution_data": {
        "my_data_key": "some value for data key"
      }
    }

And you can navigate through the path of the JSON to get a value. Supose you have a result like this:

    {
      "type": "result",
      "_id": 1427901370053,
      "status": "finished",
      "execution_data": {
        "key": [
          {
            "sub_key1":"value_1"
          },
          {
            "sub_key2":"value_2"
          }
        ]
      }
    }

    api/results/<result_id>/data?key.1.sub_key2

And you'll see

    {
      "type": "result",
      "_id": 1427901370053,
      "status": "finished",
      "execution_data": {
        "sub_key2":"value_2"
      }
    }