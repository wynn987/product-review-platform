require 'rails_helper'
require 'support/api_login_helper'

RSpec.describe ProductsController, type: :controller do
  let(:token) { double acceptable?: true }
  before(:each, authorized: true) do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe "GET #show", authorized: true do
    it "returns a success response" do
      product = create(:product)
      get :show, params: { id: product.id }

      expect(response).to be_success
    end
  end

  describe "GET #show", authorized: false do
    it "returns an unauthorized response" do
      @expected = unauthorized_response
      product = create(:product)
      get :show, params: { id: product.id }

      expect(response.body).to look_like_json
      expect(response).to be_unauthorized
      expect(body_as_json).to match(@expected)
    end
  end
end
