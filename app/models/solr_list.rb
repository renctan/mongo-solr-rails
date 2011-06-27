require "singleton"

# A simple thread-safe container for holding Solr connection instances.
class SolrList < MongoSolr::SynchronizedHash
  include Singleton

  def add(name, location)
    
  end
end

