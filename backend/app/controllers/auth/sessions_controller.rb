module Auth
  class SessionsController < DeviseTokenAuth::SessionsController
    private

    def render_create_success
      token = JsonWebToken.encode(sub: @resource.id, scope: "seller")

      response.set_header("Authorization", "Bearer #{token}")

      render json: {
        status: "success",
        message: "Seller logged in successfully.",
        seller: @resource.seller_payload,
        jwt: token
      }, status: :ok
    end
  end
end
