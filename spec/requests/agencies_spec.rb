# TODO: Currently the tests are written to test if ApiController works. 
# More specific tests will be added in later user stories
require 'rails_helper'

RSpec.describe "Agencies", type: :request do
  describe "GET /agencies" do
    it "works! (now write some real specs)" do
      get agencies_path
      expect(response).to have_http_status(401)
    end
  end
end
