require 'rails_helper'
require 'support/api_login_helper'

RSpec.describe AgenciesController, type: :controller do
  let(:token) { double acceptable?: true }
  before(:each, authorized: true) do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe "GET #index", authorized: true do
    it "returns a success response" do
      get :index, params: {}
      expect(response).to be_success
    end
  end

  describe "GET #index", authorized: false do
    it "returns an unauthorized response" do
      @expected = unauthorized_response

      get :index, params: {}
      expect(response.body).to look_like_json
      expect(response).to be_unauthorized
      expect(body_as_json).to match(@expected)
    end
  end
end