How do i use the api?
==============


Well, we want to do things as simple as possible, so we are using only GET requests. Everyone has a browser, so everyone has the possiblility to use Mutx.

Returns the list of tasks or tests

    api/tasks
    api/tests

Returns the list of running tasks or tests

    api/tasks/running
    api/tests/running

Returns the status of the given task id

    api/tasks/<task_id>/status

Returns the task structure for the given task id

    api/tasks/<task_id>

Returns all existing results

    api/results

Returns the result for a given result id

    api/results/<result_id>

Starts an execution

  Perform get to:

    api/tasks/<task_name>/run

    # pass custom parameters as query string like 
    api/tasks/:task/run?environment=RC&foo=bar

    # and if you want identify the execution, you can pass as query string too.
    api/tasks/:task/run?environment=RC&foo=bar&execution_name=your_execution_identification' 

  If execution starts succesfully, it will return a result id


Returns the execution data for a given result id

    api/results/<result_id>/data

