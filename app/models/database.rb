# A simple thread-safe model that holds a list of collection names.
class Database
  attr_reader :name # String
  attr_accessor :collections # [MongoSolr::SynchronizedSet]

  # @param database [Mongo::DB] The database instance
  # @param db_set [MongoSolr::SynchronizedHash]
  def initialize(database, db_set)
    @db = database
    @name = @db.name
    @collections = MongoSolr::SynchronizedSet.new

    db_set[@name] = @collections
  end

  # Add a collection name to this set.
  #
  # @param collection_name [String] The name of the collection
  # 
  # @raise [MongoDBError] if the collection does not exist, or if cannot connect to collection
  #   due to authentication failure
  def add(collection_name)
    @db.validate_collection(collection_name)
    @collections.add(collection_name)
  end

  # Remove a collection from this set.
  #
  # @param collection_name [String] The name of the collection.
  def remove(collection_name)
    @collections.delete(collections)
  end
end

