require "mongo-solr/src/synchronized_hash"
require "mongo-solr/src/solr_synchronizer"

# A model for representing a Solr connection.
class Solr
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  extend Forwardable

  # [Hash<String, Enumerable<String> >] Contains the names of collections to index.
  #   Should only be used for reading.
  def_delegator :@synchronizer, :db_set

  # Name for this Solr connection given by the user.
  attr_reader :name

  # @param name [String] A label for this Solr connection
  # @param location [String] The location of the Solr server
  # @param mongo [Mongo::Connection] The connection to the mongo database
  # @param mode [Symbol] @see MongoSolr::SolrSynchronizer#new
  # @param db_name_set [Hash<String, Set<String> >] @see MongoSolr::SolrSynchronizer#new
  #
  # @raise [RuntimeError] whenever the connection to Solr fails
  def initialize(name, location, mongo, mode, db_name_set)
    @name = name
    @solr = RSolr.connect(:url => location)
    # Try to check if we can connect to the Solr Server
    @solr.get "select", :params =>{ :q => PING_TEST_STRING }

    @conn = mongo
    @synchronizer = MongoSolr::SolrSynchronizer.new(@solr, @conn,
                                                    mode, db_name_set, { :name => @name })

    @sync_thread_mutex = Mutex.new

    # Protected by @sync_thread_mutex
    @sync_thread = nil
  end

  # Synchronizes database to Solr.
  #
  # @raise [RuntimeError] when sync is already running
  def sync
    @sync_thread_mutex.synchronize do
      if @sync_thread.nil? then
        @sync_thread = Thread.new { @synchronizer.sync() }
      end
    end
  end

  # Stops the synchronization
  def stop_sync
    @sync_thread_mutex.synchronize do
      unless @sync_thread.nil? then
        @synchronizer.stop!
        @sync_thread.join
        @sync_thread = nil
      end
    end
  end

  def to_param
    @name
  end

  def persisted?
    false # Instances exist only in RAM
  end

  def update_attributes(param)
    @synchronizer.update_db_set(extract_db_set(param))
  end

  # @return [Boolean] true if this object is performing a synchronization with Solr.
  def synching?
    @sync_thread_mutex.synchronize { not @sync_thread.nil? }
  end

  ##############################################################################
  private
  PING_TEST_STRING = "Checking connection from mongo-solr-rails... hope nothing comes out"

  # Extract the list of db from the update request parameters.
  #
  # @param params [Hash] The request parameter to read from.
  #
  # @return [Hash<Set<String> >]
  def extract_db_set(params)
    db_set = {}

    params.each do |key, value|
      if key.start_with? "db_" then
        db_name = key.sub(/^db_/, "")
        db_set[db_name] = Set.new(value.reject(){ |k, v| v == "0" }.keys)
      end
    end

    return db_set
  end
end

