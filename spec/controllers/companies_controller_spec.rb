require 'rails_helper'
require 'support/api_login_helper'

RSpec.describe CompaniesController, type: :controller do
  let(:token) { double acceptable?: true }
  before(:each, authorized: true) do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe "GET #index", authorized: true do
    it "returns a success response" do
      get :index
      expect(response).to be_success
    end

    it "returns all company" do
      create_list(:company, 5)
      get :index
      expect(parsed_response.length).to eq(5)
    end

    it "does not return deleted companies" do
      create_list(:company, 5)
      Company.first.discard
      get :index
      expect(parsed_response.length).to eq(4)
    end

    it "returns 25 result (1 page)", authorized: true do
      default_result_per_page = 25
      num_of_object_to_create = 30
      create_list(:company, num_of_object_to_create)

      get :index
      expect(JSON.parse(response.body).count).to match default_result_per_page
    end
  end

  describe "GET #index", authorized: false do
    it "returns an unauthorized response" do
      get :index, params: {}
      expect_unauthorized
    end
  end

  describe "GET #vendor_listings", authorized: true do
    it "returns a success response" do
      get :vendor_listings
      expect(response).to be_success
    end

    it "returns companies with projects" do
      create_list(:company, 1)
      get :vendor_listings
      expect(parsed_response.first.key?("projects")).to eq(true)
    end
  end

  describe "GET #vendor_listings", authorized: false do
    it "returns an unauthorized response" do
      get :vendor_listings, params: {}
      expect_unauthorized
    end
  end

  describe "GET #clients", authorized: true do
    let(:company) { create(:company) }
    it "returns a success response" do
      get :clients, params: { company_id: company.hashid }
      expect(response).to be_success
    end

    it "returns not found if company is not found" do
      get :clients, params: { company_id: 0 }
      expect(response.status).to eq(404)
    end

    it "returns not found if company is deleted" do
      company.discard
      get :clients, params: { company_id: company.id }
      expect(response.status).to eq(404)
    end
  end

  describe "GET #clients", authorized: false do
    let(:company) { create(:company) }
    it "returns an unauthorized response" do
      get :clients, params: { company_id: company.id }
      expect_unauthorized
    end
  end

  describe "GET #show", authorized: true do
    let(:company) { create(:company) }
    it "returns a success response" do
      get :show, params: { id: company.hashid }
      expect(response).to be_success
    end

    it "returns data of an single company" do
      get :show, params: { id: company.id }, format: :json
      expect_show_response
    end

    it "returns not found if the company does not exist" do
      get :show, params: { id: 0 }, format: :json
      expect_not_found
    end
    it "returns 404 if company has already been soft deleted" do
      company.discard
      get :show, params: { id: company.id }
      expect_not_found
    end
  end

  describe "GET #show", authorized: false do
    it "returns an unauthorized response" do
      get :show, params: { id: 0 }, format: :json
      expect_unauthorized
    end
  end

  describe "POST #create", authorized: true do
    let(:company) { build(:company) }
    let(:company_params) { build(:company_as_params) }
    let(:industry) { create(:industry) }
    let(:company_params_without_image) { build(:company_as_params, image: "") }

    it "returns a success response" do
      post :create, params: { company: company_params.as_json.merge(industry_ids: [industry.hashid]) }
      expect(response.status).to eq(201)
    end

    it "returns data of the single created company" do
      post :create, params: { company: company_params.as_json.merge(industry_ids: [industry.id]) }
      expect_show_response
    end

    it "returns Unprocessable Entity if company is not valid" do
      company_params[:name] = ""
      post :create, params: { company: company_params.as_json.merge(industry_ids: [industry.hashid]) }
      expect(response.status).to eq(422)
    end

    it "renders a 422 error for duplicate uen" do
      @dupcompany = build(:company)
      @dupcompany.uen = company_params[:uen]
      @dupcompany.save
      post :create, params: { company: company_params.as_json.merge(industry_ids: [industry.hashid]) }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.content_type).to eq('application/json')
    end

    it "return 404 when industry ID is invalid" do
      post :create, params: { company: company.as_json.merge(industry_ids: [0]) }
      expect_not_found
    end

    it "return 404 when industry ID is deleted" do
      @industry = build(:industry)
      @industry.discard
      post :create, params: { company: company.as_json.merge(industry_ids: [@industry.id]) }
      expect_not_found
    end

    it "creates a letterhead avatar when no image is specified" do
      post :create, params: { company: company_params_without_image.as_json.merge(industry_ids: [industry.hashid]) }
      expect(parsed_response[:image][:url]).to_not eq(nil)
      expect(parsed_response[:image][:thumb][:url]).to_not eq(nil)
    end

    it "creates a image" do
      company_param = company.attributes.as_json.merge(industry_ids: [industry.hashid])
      company_param[:image] = valid_base64_image
      post :create, params: { company: company_param }
      expect(parsed_response[:image][:url]).to_not eq(nil)
      expect(parsed_response[:image][:thumb][:url]).to_not eq(nil)
    end

    it "returns 422 when the image is invalid" do
      company_param = company.attributes.as_json.merge(industry_ids: [industry.hashid])
      company_param[:image] = partial_base64_image
      post :create, params: { company: company_param }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.content_type).to eq('application/json')
    end
  end

  describe "POST #create", authorized: false do
    it "returns an unauthorized response" do
      post :create, params: { company: {} }
      expect_unauthorized
    end
  end

  describe "PATCH #update", authorized: true do
    let(:company) { create(:company) }
    let(:company_params) { build(:company_as_params) }
    let(:industry) { create(:industry) }

    it "returns a success response" do
      patch :update, params: { company: company_params.as_json.merge(industry_ids: [industry.hashid]), id: company.hashid }
      expect(response.status).to eq(200)
    end

    it "returns data of the single updated company" do
      patch :update, params: { company: company_params.as_json.merge(industry_ids: [industry.hashid]), id: company.hashid }
      company.reload
      expect(company.attributes.except('id', 'created_at', 'updated_at', 'aggregate_score', 'image', 'discarded_at', 'reviews_count')).to match(company_params.with_indifferent_access.except('id', 'created_at', 'updated_at', 'aggregate_score', 'image'))
    end

    it "returns Unprocessable Entity if company is not valid" do
      original_company = company
      another_company = create(:company)
      patch :update, params: { company: attributes_for(:company, uen: another_company.uen).as_json.merge(industry_ids: [industry.hashid]), id: company.hashid }
      company.reload
      expect(company).to match(original_company)
      expect(response.status).to eq(422)
    end

    it "returns not found if company id is not valid" do
      original_company = company
      patch :update, params: { company: build(:company).as_json, id: 0 }
      company.reload
      expect(company).to match(original_company)
      expect(response.status).to eq(404)
    end

    it "returns 400 if company is not provided" do
      original_company = company
      patch :update, params: { id: original_company.hashid }
      company.reload
      expect(company).to match(original_company)
      expect(response.status).to eq(400)
    end

    it "returns 404 if company has already been soft deleted" do
      original_company = company
      original_company.discard
      patch :update, params: { company: company.as_json, id: company.id }
      company.reload
      expect(company).to match(original_company)
      expect(response.status).to eq(404)
    end

    it "renders a 422 error for duplicate uen", authorized: true do
      @dupcompany = create(:company)

      patch :update, params: { company: company.as_json.merge(industry_ids: [industry.hashid]), id: @dupcompany.hashid }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.content_type).to eq('application/json')
    end

    it "return 404 when industry ID is invalid" do
      patch :update, params: { company: company.as_json.merge(industry_ids: [0]), id: company.id }
      expect_not_found
    end

    it "return 404 when industry ID is deleted" do
      @industry = build(:industry)
      @industry.discard
      patch :update, params: { company: company.as_json.merge(industry_ids: [0]), id: company.id }
      expect_not_found
    end

    it "updates a image" do
      original_company = create(:company)
      company_param = company.attributes.as_json.merge(industry_ids: [industry.id])
      company_param[:image] = valid_base64_image
      patch :update, params: { company: company_param, id: original_company.id }
      original_company.reload
      expect(parsed_response[:image]).to_not eq(original_company.image.serializable_hash)
    end

    it "returns 422 when the image is invalid" do
      original_company = create(:company)
      company_param = company.attributes.as_json.merge(industry_ids: [industry.hashid])
      company_param[:image] = partial_base64_image
      patch :update, params: { company: company_param, id: original_company.hashid }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.content_type).to eq('application/json')
    end
  end

  describe "PATCH #update", authorized: false do
    it "returns an unauthorized response" do
      patch :update, params: { company: {}, id: 0 }
      expect_unauthorized
    end
  end

  describe "DELETE #destroy", authorized: true do
    it "returns a success response" do
      company = create(:company)
      delete :destroy, params: { id: company.hashid }
      expect(response.status).to eq(204)
    end

    it "sets company's discarded_at column" do
      company = create(:company)
      delete :destroy, params: { id: company.hashid }
      company.reload
      expect(company.discarded?).to be true
    end

    it "returns a not found response if company is not found" do
      delete :destroy, params: { id: 0 }
      expect(response.status).to eq(404)
    end

    it "returns a not found response if company is already deleted" do
      company = create(:company)
      company.discard
      delete :destroy, params: { id: company.id }
      expect(response.status).to eq(404)
    end
  end

  describe "DELETE #destroy", authorized: false do
    it "returns an unauthorized response" do
      delete :destroy, params: { id: 0 }, format: :json
      expect_unauthorized
    end
  end
end
