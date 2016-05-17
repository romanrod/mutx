How to configure Mutx?
==============

Mutx retrieve information from profiles file called cucumber.yml allocated on project root folder.
You have to have this file into your project to work with Mutx.

Mutx will show only those tasks marked as runnable as test tasks. To do this you only have to add a flag to each cucumber profile you want to expose as follows:
Supose you have a profile called regression on cucumber.yml file

	#cucumber.yml
	regression: -t @regression runnable=true

The flag `runnable=true` indicates to Mutx to expose the profile to be executed as a test task.