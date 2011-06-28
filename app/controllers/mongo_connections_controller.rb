class MongoConnectionsController < ActionController::Base
  expose(:connection) { MongoConnection.instance }
  expose(:err_msg) { [] }

  def create
    conn_details = params["conn"]
    loc = conn_details["location"]
    port = conn_details["port"].to_i

    respond_to do |format|
      begin
        connection.setup(loc, port)

        # TODO: route to Solr
#        format.html { redirect_to :action => "index" }
      rescue Mongo::ConnectionFailure
        err_msg << "Cannot connect to #{loc}:#{port}"
        format.html { render :action => "new" }
      end
    end
  end
end

