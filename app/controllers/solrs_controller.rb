require "mongo-solr/src/synchronized_set"

class SolrsController < ApplicationController
  expose(:solrs) { SolrList.instance }
  expose(:err_msg) { [] }
  expose(:solr) do
    name = params["solr_id"]
    SolrList.instance[name] unless name.nil?
  end

  helper_method :databases

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

  ##############################################################################
  private
  SPECIAL_PURPOSE_MONGO_DB_NAME_PATTERN = /^(local|admin|config)$/
  SPECIAL_COLLECTION_NAME_PATTERN = /^system\./

  # @return [Hash<String, Array<String> >] a hash containing known databases. The key
  #   contains the database name while the value contains an array of collection names.
  def databases
    mongo = MongoConnection.instance.conn
    
    begin
      db_list = {}
      mongo.database_names.each do |db_name|
        unless db_name =~ SPECIAL_PURPOSE_MONGO_DB_NAME_PATTERN then
          db_list[db_name] = mongo.db(db_name).collection_names.reject do |coll_name|
            coll_name =~ SPECIAL_COLLECTION_NAME_PATTERN
          end
        end
      end
    rescue Mongo::OperationFailure
      # Authentication failure. Show the db manually added so far.
      solr.db_name_set.each do |db_name, coll_set|
        db_list[db_name] = coll_set.to_a
      end
    end

    db_list
  end
end

