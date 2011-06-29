require "singleton"

# Singleton class for holding a connection to MongoDB Server
class MongoConnection
  include Singleton

  attr_reader :conn
  attr_reader :mode

  def initialize
    @conn = nil
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

  private
  LOCAL_PREFIX = "models.mongo_connection"
end

