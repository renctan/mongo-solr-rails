class MongoConnectionsController < ActionController::Base
  expose(:connection) { MongoConnection.instance }
  expose(:err_msg) { [] }

  def new
    redirect_to solrs_path unless connection.conn.nil?
  end

  def create
    conn_details = params["conn"]
    loc = conn_details["location"]
    port = conn_details["port"].to_i

    err_msg.concat(connection.setup(loc, port))

    if err_msg.empty? then
      redirect_to solrs_path
    else
      render :action => "new"
    end
  end
end

