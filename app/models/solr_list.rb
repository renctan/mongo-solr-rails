require "singleton"
require "forwardable"
require "mongo-solr/src/synchronized_hash"

# A simple thread-safe container for holding Solr connection instances.
class SolrList
  include Singleton
  extend Forwardable

  def_delegators :@list, :[], :empty?, :each, :delete

  def initialize
    @list = MongoSolr::SynchronizedHash.new
  end

  # Add a new Solr connection.
  #
  # @param name [String] The name for the new Solr connection
  # @param location [String] The location of the the Solr Server
  # @param mongo [Mongo::Connection] The connection to the mongo database
  # @param mode [Symbol] @see MongoSolr::SolrSynchronizer
  #
  # @return [Array<String>] an array of error messages. Empty if no error occured.
  def add(name, location, mongo, mode)
    err_msg = []

    if @list.has_key? name then
      err_msg << "Solr connection with name the #{name} already exists." +
        " Please choose another name."
    else
      begin
        solr = Solr.new(name, location, mongo, mode)
        @list[name] = solr
      rescue
        err_msg << "Error encountered while trying to setup connection to #{location}"
      end
    end

    return err_msg
  end
end

