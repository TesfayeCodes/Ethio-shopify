module Api
  module V1
    class SellersController < BaseController
      def show
        render json: { seller: current_seller.seller_payload }
      end
    end
  end
end
