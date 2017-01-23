How do i use the repositories feature?
=====================================

    When we have some task or test that consume some information to run, we have the possibility on Mutx to save some info and use the API of repos to check it and use it.

To create an info repository
===========================

    We only need to go to the Admin bar and click on 'Repositories'. By default we can view the list of repos. If we want to create a repo, we need to click on 'New Repo', put a name of the new repo and save it, thats it.

How to save info inside a repo
=============================

    When we create a repo, we have to copy the token that the new repo has (with and invalid token or repo name Mutx will reject the request). To save info we have to make a PUT to an existing repo, for example:

    PATH/api/<repo_token>/<repo_name>/

    The value to save must be a JSON in the body of the request, for example: 

    {
      "id": 3,
      "name": "Visa"
    }

How to get the info of a repo
============================

    Using the API we can make a GET request to view the info of a repository, for example:

    PATH/api/repos/<repo_name>

    The result will be a json with the info of the repo. The values that we previously save will be in the 'values' field.