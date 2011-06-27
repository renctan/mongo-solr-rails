class DatabasesController < ApplicationController
  expose(:databases) { DatabaseList.instance }

  expose(:database) do
    db_name = params[:name]
    DatabaseList.instance[db_name]
  end

  def create
    params[:name]
    databases
  end

  def edit
  end

  def add
    name = params[:name]
  end

  def remove
  end
end

