class AuthenticateBotRequest
  PROTECTED_PATHS = [
    %r{\A/api/v1/shops\z},
    %r{\A/api/v1/seller\z}
  ].freeze

  EXCLUDED_PATHS = [
    %r{\A/api/v1/shops/setup},
    %r{\A/webhooks/shop_bot},
    %r{\Alist-products},
    %r{\A/api/v1/products},
    %r{\A/shop/},
    %r{\A/setup-shop}
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    return @app.call(env) if excluded_path?(request.path)
    return @app.call(env) unless protected_request?(request.path)

    token = bearer_token(request)
    return unauthorized unless token

    payload = JsonWebToken.decode(token)
    user = User.find_by(id: payload["sub"])
    return unauthorized unless user

    Current.user = user
    env["current_user"] = user
    env["jwt.payload"] = payload

    @app.call(env)
  rescue JsonWebToken::DecodeError => e
    Rails.logger.error "JWT DecodeError: #{e.message}"
    unauthorized
  rescue NoMethodError => e
    Rails.logger.error "NoMethodError in middleware: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
    unauthorized
  rescue => e
    Rails.logger.error "AuthenticateBotRequest error: #{e.message}"
    unauthorized
  ensure
    Current.reset
  end

  private

  def protected_request?(path)
    PROTECTED_PATHS.any? { |matcher| matcher.match?(path) }
  end

  def excluded_path?(path)
    EXCLUDED_PATHS.any? { |matcher| matcher.match?(path) }
  end

  def bearer_token(request)
    header = request.get_header("HTTP_AUTHORIZATION").to_s
    scheme, token = header.split(" ", 2)
    return token if scheme == "Bearer" && token.present?

    nil
  end

  def unauthorized
    body = { error: "Unauthorized" }.to_json

    [
      401,
      {
        "Content-Type" => "application/json",
        "Content-Length" => body.bytesize.to_s
      },
      [body]
    ]
  end
end
