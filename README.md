# Overview

A Rails app front end for [mongo-solr](https://github.com/renctan/mongo-solr).

# Usage

Simply type the following command on the root directory:

    rails server -e production

# External Gem Dependencies:

Run the following command to install all the gem dependencies used by this project:

    bundle install

# Special Note to Potential Contributors

The class caching has been set to true in development mode to make the Singleton classes behave properly. This means that you need to restart the server everytime you modified the code to have the changes reflected.

