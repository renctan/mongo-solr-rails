require "mongo-solr/src/synchronized_set"

class SolrsController < ApplicationController
  expose(:solrs) { SolrList.instance }
  expose(:err_msg) { [] }
  expose(:solr) do
    name = params["id"]
    SolrList.instance[name] unless name.nil?
  end

  def create
    conn_details = params["conn"]
    name = conn_details["name"]
    location = conn_details["location"]

    mongo = MongoConnection.instance
    db_set = MongoSolr::SynchronizedSet.new

    err_msg.concat(solrs.add(name, location, mongo.conn, mongo.mode, db_set))

    if err_msg.empty? then
      redirect_to edit_solr_path(name)
    else
      render :action => "new"
    end
  end

  def destroy
    name = params["id"]

    solrs.delete(name)
    render :action => "index"
  end

  def update
    solr.update_attributes(params)
    render :action => "edit"
  end

  # ajax only
  def auth_db
    auth = params["auth"]
    database = auth["database"]
    username = auth["username"]
    pwd = auth["password"]

    connection = MongoConnection.instance
    err_msg.concat(connection.authenticate(database, username, pwd))

    unless err_msg.empty? then
      render "auth_err.js.erb"
    end
  end
end

