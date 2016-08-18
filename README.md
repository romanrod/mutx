![alt tag](https://github.com/romanrod/mutx/tree/master/imgmutx_logo.svg)
Mutx (WIP)
==============


#### *This project was created in order to expose tasks (tests) easily so anybody is allowed to execute them.*

(NOT READY YET)

  ONLY FOR UBUNTU (By Now)

  Before installing Mutx you should have installed:

  - MongoDb (version >= 2.6) See http://www.mongodb.org/downloads

    $ sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10

    $ sudo apt-get update

    $ sudo apt-get install mongodb

    $ sudo service mongodb start

  - Redis (http://tosbourn.com/install-latest-version-redis-ubuntu/)

    $ sudo apt-get install -y python-software-properties

    $ sudo add-apt-repository -y ppa:rwky/redis

    $ sudo apt-get update

    $ sudo apt-get install -y redis-server

  - If you want to run GUI tests using WebDriver in headless mode you should install xvfb package

    $sudo apt-get intall xvfb

  - While running in headless mode you may face an error like:
    LIBDBUSMENU-GLIB-WARNING **: Unable to get session bus: Error spawning command line `dbus-launch --autolaunch
  This coulb be solved by installing dbus-x11 package

    $apt-get install dbus-x11



## Mutx Installation

    $ gem install mutx

## Usage

Go to your project folder and run install command to use mutx over your project

    $ mutx install

Then bundle it

    $ bundle install

Configure a JSON file called mutx.conf with the values you need

    mutx/conf/mutx.conf

Start Mutx and follow instructions

    $ mutx start


  Important: Do not forget to include mutx folder to .gitignore if you will use git


How it works
---------------------

When you run `mutx install` command, mutx will do:

- Update your Gemfile if it exist, else will create it. Also will define gem 'mutx' on it, of course.

- Creates a folder on your root project folder with some files on it. Those files are used by mutx to work.

The file called mutx.conf in conf/ folder has some configuration that you can/must modify ( or see at least). You should only use conf/mutx.conf and some logs files (logs/mutx.log & logs/sidekiq.log)

The file config.ru has the needed code to start the service (DO NOT MODIFY IT)

After configuring mutx.conf file you are able to run `mutx start`

After starting Mutx you can go to Help section and see all what you need to know to work with mutx regarding to set up test tasks, custom parameters and so.




=== Can be changed ===
Reference about configuration

mutx/conf/mutx.conf file reference:

    {
    "use_git" : true,
    "app_name" : "your-app-name",
    "app_port" : 8080,
    "database" : {
    "type" : "mongodb",
    "host" :"localhost",
    "port" : 27017,
    "username" : null,
    "password" : null},
    "project_name" : "Mutx",
    "project_url" : "http://your.project.url",
    "inactivity_timeout" : 60,
    "kill_inactive_executions_after" : 300,
    "datetime_format" : "%d/%m/%Y %H:%M:%S",
    "refresh_time" : 10,
    "notification" : {
    "use_gmail" : false,
    "username" : null,
    "password" : null,
    "recipients" : "your@email.com",
    "attach_report" : false
    },
    "footer_text" : "Tests by a great and funny team",
    "execution_tag_placeholder" : {
    "datetime" : true,
    "format" : "%d%^b%y-%H%M",
    "default" : null
    },
    "headless" : {
    "active" : false,
    "resolution" : "1024x768",
    "size":"24"}
    }

This file is where you can configure:

  "use_git": (Boolean) set as true if you are using git

  "MONGO_host" : (String) The host where mongodb is running

  "app_port" : (Fixnum/Int) The http port that Mutx will be listening

	"project_name" : (String) The name of your Cucumber project

  "project_url" : (String) The url of your project (basically the url of the repository)

  "inactivity_timeout" : (Fixnum/Int) The time in seconds to consider an execution as inactive. This will show you the option to reset an inactive execution

  "kill_inactive_executions_after" : (Fixnum/Int) The time in seconds to wait for killing automatically those inactive executions

  "datetime_format" : "%d/%m/%Y %H:%M:%S"

  "refresh_time" : (Fixnum/Int) The time in seconds to refresh result window in console view

  "notification" : (Boolean) This is a flag to use notifications through gmail service. You should have a gmail account to use it.

	"footer_text" : (String) A text you want to see at the footer like "Tests by a great team (team_name@domain.com"

  "execution_tag_placeholder" : (JSON) If you want to use a simple execution id given by the actual time you can set the value of "datetime" to true (Boolean), with this option you can use a strftime format and it will put the execution id automatically.
  If you set "datetime" to false (Boolean) you can use "default" value. Setting "datetime" as false and "default" as null you will have to (if you need it) set the execution id manually each time you run a task.

  "headless" (JSON) : Set active as true to use headless mode


Available Commands
---------------------

- To adapt your project to use mutx

    $ mutx install

- To start mutx service

    $ mutx start

- To clear all tasks and results collection. To erase all data from database

    $ mutx reset

- To clear all tasks collection only. To erase all tasks data from database

    $ mutx reset_tasks

- to shut down mutx

    $ mutx stop

- to restart mutx

    $ mutx restart


Get (what you need!)
---------------------

- /mutx/tasks

- /mutx/tasks/`<task_name>`/run

- /mutx/results

- /mutx/results/`<task_name>`

- /mutx/results/`<result_id>`/log

- /mutx/results/`<result_id>`

- /mutx/help


Tip
---------------------

If you shutdown mutx and then you want to get it up and the port you are using is already in use you could use the following commands (Ubunutu OS):

    $sudo netstat -tapen | grep ":8080 "

In this example we use the port 8080. This command will give you the app that is using the port. Then you could kill it getting its PID previously.


API
=======

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

Returns the data you've added to result from execution

    mutx/api/results/<result_id>/data



Contributing
---------------------

1. Fork it (http://github.com/romgrod/mutx/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
=======

TEST