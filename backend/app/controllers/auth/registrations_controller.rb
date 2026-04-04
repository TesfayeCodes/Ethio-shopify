module Auth
  class RegistrationsController < DeviseTokenAuth::RegistrationsController
    private

    def sign_up_params
      seller_params
    end

    def account_update_params
      seller_params
    end

    def render_create_success
      render json: {
        status: "success",
        message: "Seller account registered successfully.",
        seller: @resource.seller_payload
      }, status: :ok
    end

    def render_update_success
      render json: {
        status: "success",
        message: "Seller account updated successfully.",
        seller: @resource.seller_payload
      }, status: :ok
    end

    def seller_params
      params.fetch(:registration, params).permit(:email, :password, :password_confirmation, :name)
    end
  end
end
