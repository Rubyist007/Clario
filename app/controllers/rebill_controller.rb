class RebillController < ApplicationController
  rescue_from RebillOperation::InvalidParams, with: :failed_responce

  def create
    result = RebillOperation.call(**rebill_params.to_h)

    result.insufficient_funds? ? insufficient_funds_responce : success_responce
  end

  private

    def rebill
      RebillOperation.call(**rebill_params.to_h)
    end

    def success_responce
      render json: { status: "success" }, status: :ok
    end

    def failed_responce
      render json: { status: "failed" }, status: :bad_request
    end

    def insufficient_funds_responce
      render json: { status: "insufficient_funds" }, status: :unprocessable_entity
    end

    def rebill_params
      params.permit(:amount, :subscription_id)
    end
end
