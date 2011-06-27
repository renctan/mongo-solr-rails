require "singleton"

# Singleton class for holding a connection to MongoDB Server
class MongoConnection
  include Singleton

  attr_reader :conn
  attr_reader :mode

  # Setup the MongoDB connection.
  #
  # @param location [String] The location of the MongoDB server.
  # @param port [Integer] The port number of the MongoDB server.
  # @param mode [Symbol] (:auto) @see MongoSolr::SolrSynchronizer#new
  #
  # @raise [Mongo::ConnectionFailure]
  def setup(location, port, mode = :auto)
    @conn = Mongo::Connection.new(location, port)
    @mode = mode
  end
end

