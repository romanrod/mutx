How do i use the api?
==============


Well, we want to do things as simple as possible, so we are using only GET requests. Everyone has a browser, so everyone has the possiblility to use Mutx.

Returns the list of tasks

    mutx/api/tasks

Returns the list of tasks that are running

    mutx/api/tasks/running

Returns the status of the given task id

    mutx/api/tasks/<task_id>/status

Returns the task structure for the given task id

    mutx/api/tasks/<task_id>

Returns all existing results

    mutx/api/results

Returns the result for a given result id

    mutx/api/results/<result_id>

Starts an execution

  Perform get to:

    mutx/api/tasks/<task_me>/run

    # pass custom parameters as query string like vmutx/api/tasks/:task/run?environment=RC&foo=bar

    # and if you want identify the execution, you can pass execution_name=your_execution_identification' as query string too.

  If execution starts succesfully, it will return a result id


Returns the execution data for a given result id

    mutx/api/results/<result_id>/data

