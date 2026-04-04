require "base64"
require "json"
require "openssl"

class JsonWebToken
  class DecodeError < StandardError; end

  ALGORITHM = "HS256"
  DEFAULT_LIFESPAN = 24.hours

  class << self
    def encode(payload, expires_at: DEFAULT_LIFESPAN.from_now)
      jwt_payload = payload.stringify_keys.merge("exp" => expires_at.to_i)
      header = { typ: "JWT", alg: ALGORITHM }

      encoded_header = base64url_encode(header.to_json)
      encoded_payload = base64url_encode(jwt_payload.to_json)
      signature = sign([encoded_header, encoded_payload].join("."))

      [encoded_header, encoded_payload, signature].join(".")
    end

    def decode(token)
      encoded_header, encoded_payload, signature = token.to_s.split(".")
      raise DecodeError, "Malformed token" unless encoded_header && encoded_payload && signature

      expected_signature = sign([encoded_header, encoded_payload].join("."))
      raise DecodeError, "Invalid signature" unless secure_compare(signature, expected_signature)

      payload = JSON.parse(base64url_decode(encoded_payload))
      raise DecodeError, "Token expired" if payload.fetch("exp", 0).to_i <= Time.current.to_i

      payload
    rescue JSON::ParserError, ArgumentError
      raise DecodeError, "Malformed token"
    end

    private

    def sign(data)
      digest = OpenSSL::HMAC.digest("SHA256", secret_key, data)
      base64url_encode(digest)
    end

    def secret_key
      Rails.application.secret_key_base
    end

    def base64url_encode(value)
      Base64.urlsafe_encode64(value).delete("=")
    end

    def base64url_decode(value)
      padded = value + ("=" * ((4 - value.length % 4) % 4))
      Base64.urlsafe_decode64(padded)
    end

    def secure_compare(left, right)
      ActiveSupport::SecurityUtils.secure_compare(left, right)
    rescue ArgumentError
      false
    end
  end
end
