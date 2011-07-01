require "singleton"

# Singleton class for holding a connection to MongoDB Server
class MongoConnection
  include Singleton

  attr_reader :conn, :mode
  # [Array<String>] List of db names currently logged in.
  attr_reader :db_logged_in

  def initialize
    @conn = nil
    @db_logged_in = []
  end

  # Setup the MongoDB connection.
  #
  # @param location [String] The location of the MongoDB server.
  # @param port [Integer] The port number of the MongoDB server.
  # @param mode [Symbol] @see MongoSolr::SolrSynchronizer#new
  #
  # @return [Array<String>] an array of error messages. Empty if no error occured.
  def setup(location, port, mode)
    err_msg = []
    location.strip!

    begin
      @conn = Mongo::Connection.new(location, port)
      @mode = mode
    rescue Mongo::ConnectionFailure
      @conn = nil
      new_msg = I18n.t("#{LOCAL_PREFIX}.conn_err") % [location, port]
      err_msg << new_msg
    end

    return err_msg
  end

  # Authenticates a database on this connection.
  #
  # @param db_name [String] Name of the database to authenticate
  # @param user [String] User name
  # @param pwd [String] password
  #
  # @return [Array<String>] An array of error messages.
  def authenticate(db_name, user, pwd)
    err_msg = []

    begin
      @conn.db(db_name).authenticate(user, pwd)
      @db_logged_in << db_name
    rescue Mongo::AuthenticationError
      new_msg = I18n.t("#{LOCAL_PREFIX}.auth_err") % [db_name, user]
      err_msg << new_msg
    rescue => e
      err_msg << e.message
    end

    return err_msg
  end

  # Get the list of databases and their collections in this connection. The list returned
  # will be incomplete if authentication is required to access some of the databases.
  #
  # @return [Hash<String, Array<String> >] a hash containing known databases. The key
  #   contains the database name while the value contains an array of collection names.
  def get_db_list
    mongo = MongoConnection.instance
    conn = mongo.conn
    
    begin
      db_list = {}
      @conn.database_names.each do |db_name|
        unless db_name =~ SPECIAL_PURPOSE_MONGO_DB_NAME_PATTERN then
          db_list[db_name] = @conn.db(db_name).collection_names.reject do |coll_name|
            coll_name =~ SPECIAL_COLLECTION_NAME_PATTERN
          end
        end
      end
    rescue Mongo::OperationFailure
      # Authentication failure. Show the dbs that we have logged on so far.
      @db_logged_in.each do |db_name|
        db_list[db_name] = conn.db(db_name).collection_names.reject do |coll_name|
          coll_name =~ SPECIAL_COLLECTION_NAME_PATTERN
        end
      end
    end

    db_list
  end

  private
  LOCAL_PREFIX = "models.mongo_connection"
  SPECIAL_PURPOSE_MONGO_DB_NAME_PATTERN = /^(local|admin|config)$/
  SPECIAL_COLLECTION_NAME_PATTERN = /^system\./
end

