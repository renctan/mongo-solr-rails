require "mongo-solr/src/synchronized_set"

class SolrsController < ApplicationController
  expose(:solrs) { SolrList.instance }
  expose(:err_msg) { [] }
  expose(:solr) do
    name = params["solr_id"]
    SolrList.instance[name] unless name.nil?
  end

  helper_method :get_db_list

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

  ##############################################################################
  private
  SPECIAL_PURPOSE_MONGO_DB_NAME_PATTERN = /^(local|admin|config)$/
  SPECIAL_COLLECTION_NAME_PATTERN = /^system\./

  # @return [Hash<String, Array<String> >] a hash containing known databases. The key
  #   contains the database name while the value contains an array of collection names.
  def get_db_list
    mongo = MongoConnection.instance
    conn = mongo.conn
    
    begin
      db_list = {}
      conn.database_names.each do |db_name|
        unless db_name =~ SPECIAL_PURPOSE_MONGO_DB_NAME_PATTERN then
          db_list[db_name] = conn.db(db_name).collection_names.reject do |coll_name|
            coll_name =~ SPECIAL_COLLECTION_NAME_PATTERN
          end
        end
      end
    rescue Mongo::OperationFailure
      # Authentication failure. Show the dbs that we have logged on so far.
      mongo.db_logged_in.each do |db_name|
        db_list[db_name] = conn.db(db_name).collection_names.reject do |coll_name|
          coll_name =~ SPECIAL_COLLECTION_NAME_PATTERN
        end
      end
    end

    db_list
  end
end

