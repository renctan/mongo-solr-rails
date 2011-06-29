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
  # @param db_set [SynchronizedHash] @see MongoSolr::SolrSynchronizer#new
  #
  # @return [Array<String>] an array of error messages. Empty if no error occured.
  def add(name, location, mongo, mode, db_set)
    err_msg = []

    begin
      solr = Solr.new(name, location, mongo, mode, db_set)
    rescue
      new_msg = I18n.t("#{LOCAL_PREFIX}.conn_err") % location
      err_msg << new_msg
    end

    @list.use do |list|
      if list.has_key? name then
        new_msg = I18n.t("#{LOCAL_PREFIX}.name_exists_err") % name
        err_msg << new_msg
      else
        list[name] = solr unless solr.nil?
      end
    end

    return err_msg
  end

  private
  LOCAL_PREFIX = "models.solr_list"
end

