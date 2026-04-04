module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_seller!
    end
  end
end
