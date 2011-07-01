class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :get_db_list

  private
  def get_db_list
    MongoConnection.instance.get_db_list
  end
end
