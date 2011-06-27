class Solr
  attr_reader :name
  attr_reader :db_set

  # @param name [String] A label for this Solr connection
  # @param location [String] The location of the Solr server
  def initialize(name, location)
    @name = name
    @db_name_set = MongoSolr::SynchronizedHash.new
    @db_set = MongoSolr::SynchronizedHash.new

    @solr = RSolr.connect(:url => location)
    mongo = MongoConnection.instance
    @conn = mongo.conn
    @synchronizer = MongoSolr::SolrSynchronizer(@solr, @conn, mongo.mode, @db_name_set)
    @sync_thread = nil
  end

  # Synchronize database to Solr
  #
  # @raise [RuntimeError] when sync is already running
  def sync
    if @sync_thread.nil? then
      @sync_thread = Thread.new { @synchronizer.sync() }
    else
      raise "sync_thread for #{@name} already running!"
    end
  end

  # Stop synchronization
  def stop_sync
    @synchronizer.stop!
    @sync_thread.join unless @sync_thread.nil?
    @sync_thread = nil
  end

  # @param database_name [String] Name of the database instance to monitor.
  def add(database_name)
    db = MongoConnection.instance.conn.db(database_name)
    @db_set[database_name] = Database.new(db, @db_name_set)
  end

  # @param database_name [String] 
  def remove(database_name)
    @db_set.remove(database_name)
  end
end

