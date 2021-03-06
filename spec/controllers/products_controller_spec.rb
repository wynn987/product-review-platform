require 'rails_helper'
require 'support/api_login_helper'

RSpec.describe ProductsController, type: :controller do
  let(:valid_attributes) do
    build(:product).attributes
  end

  let(:invalid_attributes) do
    build(:product, name: nil).attributes
  end

  let(:valid_session) {}

  let(:token) { double acceptable?: true }

  before(:each, authorized: true) do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe "Authorised user" do
    describe "GET #index" do
      it "returns a success response", authorized: true do
        product = Product.create! valid_attributes
        get :index, params: { company_id: product.company.hashid }

        expect(response).to be_success
      end

      it "returns 25 result (1 page)", authorized: true do
        default_result_per_page = 25
        num_of_object_to_create = 30
        company = Company.create! build(:company).attributes

        while num_of_object_to_create > 0
          Product.create! build(:product, company: company).attributes
          num_of_object_to_create -= 1
        end

        get :index, params: { company_id: company.hashid }
        expect(JSON.parse(response.body).count).to match default_result_per_page
      end

      it "does not return deleted products", authorized: true do
        product = Product.create! valid_attributes
        product.discard
        get :index, params: { company_id: product.company.hashid }
        expect(parsed_response).to match([])
        expect(response).to be_success
      end

      it "returns not found if the company is deleted", authorized: true do
        product = Product.create! valid_attributes
        product.company.discard
        get :index, params: { company_id: product.company.id }
        expect(response).to be_not_found
      end
    end

    describe "GET #show" do
      it "returns a success response", authorized: true do
        product = Product.create! valid_attributes
        get :show, params: { id: product.to_param }
        expect(response).to be_success
      end

      it "returns not found when the product is deleted", authorized: true do
        product = Product.create! valid_attributes
        product.discard
        get :show, params: { id: product.to_param }
        expect(response).to be_not_found
      end

      it "returns not found when the company is deleted", authorized: true do
        product = Product.create! valid_attributes
        product.company.discard
        get :show, params: { id: product.to_param }
        expect(response).to be_not_found
      end

      it "returns not found when product not found", authorized: true do
        get :show, params: { id: 0 }
        expect(response).to be_not_found
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new Product", authorized: true do
          company = create(:company)

          expect do
            post :create, params: { product: valid_attributes, company_id: company.hashid }
          end.to change(Product, :count).by(1)
        end

        it "returns not found if the company is deleted", authorized: true do
          company = create(:company)
          company.discard
          post :create, params: { product: valid_attributes, company_id: company.id }
          expect(response).to have_http_status(404)
          expect(response.content_type).to eq('application/json')
        end

        it "returns not found if the company is not found", authorized: true do
          post :create, params: { product: valid_attributes, company_id: 0 }
          expect(response).to have_http_status(404)
          expect(response.content_type).to eq('application/json')
        end

        it "renders a JSON response with the new product", authorized: true do
          company = create(:company)

          post :create, params: { product: valid_attributes, company_id: company.hashid }
          expect(response).to have_http_status(:created)
          expect(response.content_type).to eq('application/json')
          expect(response.location).to eq(product_url(Product.last))
        end
      end

      context "with invalid params", authorized: true do
        it "renders a JSON response with errors for the new product" do
          company = create(:company)

          post :create, params: { product: invalid_attributes, company_id: company.hashid }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.content_type).to eq('application/json')
        end
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) do
          attributes_for(:product)
        end

        it "updates the requested product", authorized: true do
          product = Product.create! valid_attributes

          put :update, params: { id: product.to_param, product: new_attributes }, session: valid_session
          product.reload
          expect(product.name).to eq(new_attributes[:name])
          expect(product.description).to eq(new_attributes[:description])
        end

        it "returns not found if the product is deleted", authorized: true do
          product = Product.create! valid_attributes
          original_product = product
          product.discard
          put :update, params: { id: product.to_param, product: new_attributes }, session: valid_session
          product.reload
          expect(product.name).to eq(original_product[:name])
          expect(product.description).to eq(original_product[:description])
        end

        it "returns not found if the company is deleted", authorized: true do
          product = Product.create! valid_attributes
          original_product = product
          product.company.discard
          put :update, params: { id: product.to_param, product: new_attributes }, session: valid_session
          product.reload
          expect(product.name).to eq(original_product[:name])
          expect(product.description).to eq(original_product[:description])
        end

        it "renders a JSON response with the product", authorized: true do
          product = Product.create! valid_attributes

          put :update, params: { id: product.to_param, product: valid_attributes }, session: valid_session
          expect(response).to have_http_status(:ok)
          expect(response.content_type).to eq('application/json')
        end
      end

      context "with invalid params" do
        it "renders a JSON response with errors for the product", authorized: true do
          product = Product.create! valid_attributes

          put :update, params: { id: product.to_param, product: invalid_attributes }, session: valid_session
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.content_type).to eq('application/json')
        end
      end
    end

    describe "DELETE #destroy" do
      it "soft deletes", authorized: true do
        product = Product.create! valid_attributes
        expect do
          delete :destroy, params: { id: product.to_param }, session: valid_session
        end.to change(Product, :count).by(0)
      end

      it "sets discarded_at datetime", authorized: true do
        product = Product.create! valid_attributes
        delete :destroy, params: { id: product.to_param }
        product.reload
        expect(product.discarded?).to be true
      end

      it "renders a JSON response with the product", authorized: true do
        product = Product.create! valid_attributes

        delete :destroy, params: { id: product.to_param }
        expect(response).to have_http_status(204)
      end

      it "returns not found if the product is deleted", authorized: true do
        product = Product.create! valid_attributes
        product.discard
        delete :destroy, params: { id: product.to_param }, session: valid_session
        expect(response).to have_http_status(404)
      end

      it "returns not found if the company is deleted", authorized: true do
        product = Product.create! valid_attributes
        product.company.discard
        delete :destroy, params: { id: product.to_param }, session: valid_session
        expect(response).to have_http_status(404)
      end

      it "returns a not found response when product not found", authorized: true do
        delete :destroy, params: { id: 0 }
        expect(response).to be_not_found
      end
    end

    describe "POST #search", authorized: true do
      it "returns a success response when product is found" do
        create(:product, name: "valid product")
        post :search, params: { product_name: 'valid product', company: { uen: 999, name: 'test', description: 'for test' } }
        expect(response).to be_success
      end

      it "returns a success response" do
        post :search, params: { product_name: 'test', product: { description: 'for test' }, company: { uen: 999, name: 'test', description: 'for test' } }
        expect(response).to be_success
      end

      it "returns a unprocessable_entity response when product creation failed" do
        post :search, params: { product_name: 'test', product: { description: '' }, company: { uen: 999, name: 'test', description: 'for test' } }
        expect(response.status).to eq(422)
      end

      it "returns a unprocessable_entity response when company creation failed" do
        post :search, params: { product_name: 'test', company: { uen: 999, name: '', description: '' } }
        expect(response.status).to eq(422)
      end
    end
  end

  describe "Unauthorised user" do
    describe "GET #index" do
      it "returns an unauthorized response", authorized: false do
        product = Product.create! valid_attributes
        get :index, params: { company_id: product.company.id }

        expect_unauthorized
      end
    end

    describe "GET #show" do
      it "returns an unauthorized response", authorized: false do
        product = Product.create! valid_attributes
        get :show, params: { id: product.to_param }

        expect_unauthorized
      end
    end

    describe "POST #create" do
      it "does not create a new Product", authorized: false do
        company = create(:company)

        expect do
          post :create, params: { product: valid_attributes, company_id: company.id }
        end.to change(Product, :count).by(0)
      end

      it "returns an unauthorized response", authorized: false do
        company = create(:company)

        post :create, params: { product: valid_attributes, company_id: company.id }
        expect_unauthorized
      end
    end

    describe "PUT #update" do
      let(:new_attributes) do
        attributes_for(:product)
      end

      it "does not update the requested product", authorized: false do
        product = Product.create! valid_attributes
        current_attributes = product.attributes

        put :update, params: { id: product.to_param, product: new_attributes }, session: valid_session
        product.reload
        expect(product.name).to eq(current_attributes["name"])
        expect(product.description).to eq(current_attributes["description"])
      end

      it "returns an unauthorized response", authorized: false do
        product = Product.create! valid_attributes

        put :update, params: { id: product.to_param, product: valid_attributes }, session: valid_session
        expect_unauthorized
      end
    end

    describe "DELETE #destroy" do
      it "does not destroy the requested product", authorized: false do
        product = Product.create! valid_attributes
        expect do
          delete :destroy, params: { id: product.to_param }, session: valid_session
        end.to change(Product, :count).by(0)
      end

      it "does not set discarded_at datetime", authorized: false do
        product = Product.create! valid_attributes
        delete :destroy, params: { id: product.to_param }
        product.reload
        expect(product.discarded?).to be false
      end

      it "returns an unauthorized response", authorized: false do
        product = Product.create! valid_attributes

        delete :destroy, params: { id: product.to_param }, session: valid_session
        expect_unauthorized
      end
    end
  end
end
