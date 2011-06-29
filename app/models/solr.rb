require "mongo-solr/src/synchronized_hash"
require "mongo-solr/src/solr_synchronizer"

# A model for representing a Solr connection.
class Solr
  extend ActiveModel::Naming

  attr_reader :name

  # [SynchronizedHash] Contains the names of collections to index. Should only be used
  # for reading.
  attr_reader :db_name_set

  # [SynchronizedHash] Contains Database model instances. Should only be used for reading.
  attr_reader :db_set

  # @param name [String] A label for this Solr connection
  # @param location [String] The location of the Solr server
  # @param mongo [Mongo::Connection] The connection to the mongo database
  # @param mode [Symbol] @see MongoSolr::SolrSynchronizer#new
  # @param db_name_set [SynchronizedHash] @see MongoSolr::SolrSynchronizer#new
  #
  # @raise [RuntimeError] whenever the connection to Solr fails
  def initialize(name, location, mongo, mode, db_name_set)
    @name = name
    @solr = RSolr.connect(:url => location)
    # Try to check if we can connect to the Solr Server
    @solr.get "select", :params =>{ :q => PING_TEST_STRING }

    @db_name_set = db_name_set || MongoSolr::SynchronizedHash.new
    @db_set = MongoSolr::SynchronizedHash.new

    @conn = mongo
    @synchronizer = MongoSolr::SolrSynchronizer.new(@solr, @conn, mode, @db_name_set)
    @sync_thread = nil
  end

  # Synchronizes database to Solr.
  #
  # @raise [RuntimeError] when sync is already running
  def sync
    if @sync_thread.nil? then
      @sync_thread = Thread.new { @synchronizer.sync() }
    else
      raise "sync_thread for #{@name} already running!"
    end
  end

  # Stops the synchronization
  def stop_sync
    @synchronizer.stop!
    @sync_thread.join unless @sync_thread.nil?
    @sync_thread = nil
  end

  # Add a database to index to Solr.
  #
  # @param database [Database] The database model instance to monitor.
  def add(database)
    db_name = database.name
    db = MongoConnection.instance.conn.db(db_name)
    @db_set[db_name] = database
    @db_name_set[db_name] = MongoSolr::SynchronizedSet.new
  end

  # @param database_name [String] 
  def remove(database_name)
    @db_name_set.delete(database_name)
    @db_set.delete(database_name)
  end

  def to_param
    @name
  end

  private
  PING_TEST_STRING = "Checking connection from mongo-solr-rails... hope nothing comes out"
end

