# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ActionController::API
      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

      private

      def record_not_found(exception)
        render json: {
          error: "ResourceNotFound",
          message: exception.message
        }, status: :not_found
      end
    end
  end
end
