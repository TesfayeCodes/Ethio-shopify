require "test_helper"

class SellerAuthFlowTest < ActionDispatch::IntegrationTest
  test "seller can register log in and access protected endpoint with jwt" do
    post "/auth",
         params: {
           email: "seller@example.com",
           password: "password123",
           password_confirmation: "password123",
           name: "Seller One"
         },
         as: :json

    assert_response :success
    assert_equal "Seller One", response.parsed_body.dig("seller", "name")

    post "/auth/sign_in",
         params: {
           email: "seller@example.com",
           password: "password123"
         },
         as: :json

    assert_response :success

    jwt = response.parsed_body["jwt"]
    assert jwt.present?
    assert_equal "Bearer #{jwt}", response.headers["Authorization"]

    get "/api/v1/seller", headers: { "Authorization" => "Bearer #{jwt}" }, as: :json

    assert_response :success
    assert_equal "seller@example.com", response.parsed_body.dig("seller", "email")
  end

  test "protected seller endpoint rejects missing jwt" do
    get "/api/v1/seller", as: :json

    assert_response :unauthorized
    assert_equal "Unauthorized", response.parsed_body["error"]
  end
end
