class RebillController < ApplicationController
  def create
    render json: { message: "success" }, status: :ok
  end
end
