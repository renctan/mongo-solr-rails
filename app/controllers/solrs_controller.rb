require "mongo-solr/src/synchronized_set"

class SolrsController < ApplicationController
  expose(:solrs) { SolrList.instance }
  expose(:err_msg) { [] }
  expose(:solr) do
    name = params["solr_id"]
    SolrList.instance.list[name] unless name.nil?
  end

  def create
    conn_details = params["conn"]
    name = conn_details["name"]
    location = conn_details["location"]

    mongo = MongoConnection.instance
    db_set = MongoSolr::SynchronizedSet.new

    err_msg.concat(solrs.add(name, location, mongo.conn, mongo.mode, db_set))

    if err_msg.empty? then
      render :action => "edit"
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
  end
end

