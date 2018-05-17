require 'rails_helper'
require 'support/api_login_helper'

RSpec.describe "Projects", type: :request do
  let(:valid_attributes) do
    build(:project).attributes
  end

  let(:invalid_attributes) do
    build(:project, name: nil).attributes
  end

  describe "Authorised user" do
    describe "GET /api/v1/companies/:company_id/projects" do
      it "returns a success response" do
        project = Project.create! valid_attributes
        get company_projects_path(project.company.hashid), headers: request_login

        expect(response).to be_success
      end

      it "returns not found if the company is deleted" do
        project = Project.create! valid_attributes
        project.company.discard
        get company_projects_path(project.company.id), headers: request_login

        expect(response).to be_not_found
      end

      it "returns not found if the company is not found" do
        get company_projects_path(0), headers: request_login

        expect(response).to be_not_found
      end

      it "does not return deleted projects" do
        project = Project.create! valid_attributes
        project.discard
        get company_projects_path(project.company.hashid), headers: request_login

        expect(response).to be_success
        expect(parsed_response).to match([])
      end
    end

    describe "GET /projects/:id" do
      it "returns a success response" do
        project = Project.create! valid_attributes
        get project_path(project.hashid), headers: request_login
        expect(response).to be_success
      end

      it "returns not found when the project is deleted" do
        project = Project.create! valid_attributes
        project.discard
        get project_path(project.id), headers: request_login
        expect(response).to be_not_found
      end

      it "returns not found when the company is deleted" do
        project = Project.create! valid_attributes
        project.company.discard
        get project_path(project.id), headers: request_login
        expect(response).to be_not_found
      end

      it "returns not found when project not found" do
        get project_path(0), headers: request_login
        expect(response).to be_not_found
      end
    end

    describe "POST /api/v1/companies/:company_id/projects" do
      context "with valid params" do
        it "creates a new Project" do
          company = create(:company)

          expect do
            post company_projects_path(company.hashid), params: { project: valid_attributes }, headers: request_login
          end.to change(Project, :count).by(1)
        end

        it "renders a JSON response with the new project" do
          company = create(:company)

          post company_projects_path(company.hashid), params: { project: valid_attributes }, headers: request_login
          expect(response).to have_http_status(:created)
          expect(response.content_type).to eq('application/json')
          expect(response.location).to eq(project_url(Project.last))
        end

        it "renders not found if the company is not found" do
          post company_projects_path(0), params: { project: valid_attributes }, headers: request_login
          expect(response).to have_http_status(404)
          expect(response.content_type).to eq('application/json')
        end

        it "renders not found if the company is deleted" do
          company = create(:company)
          company.discard

          post company_projects_path(company.id), params: { project: valid_attributes }, headers: request_login
          expect(response).to have_http_status(404)
          expect(response.content_type).to eq('application/json')
        end
      end

      context "with invalid params" do
        it "renders a JSON response with errors for the new project" do
          company = create(:company)

          post company_projects_path(company.hashid), params: { project: invalid_attributes }, headers: request_login
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.content_type).to eq('application/json')
        end
      end
    end

    describe "PUT /api/v1/projects/:id" do
      context "with valid params" do
        let(:new_attributes) do
          attributes_for(:project)
        end

        it "updates the requested project" do
          project = Project.create! valid_attributes

          put project_path(project), params: { project: new_attributes }, headers: request_login
          project.reload
          expect(project.name).to eq(new_attributes[:name])
          expect(project.description).to eq(new_attributes[:description])
        end

        it "renders a JSON response with the project" do
          project = Project.create! valid_attributes

          put project_path(project), params: { project: new_attributes }, headers: request_login
          expect(response).to have_http_status(:ok)
          expect(response.content_type).to eq('application/json')
        end

        it "does not update the requested project when the company is deleted" do
          project = Project.create! valid_attributes
          original_project = project
          project.company.discard
          put project_path(project), params: { project: new_attributes }, headers: request_login
          project.reload
          expect(project.name).to eq(original_project[:name])
          expect(project.description).to eq(original_project[:description])
        end

        it "does not update the requested project when the project is deleted" do
          project = Project.create! valid_attributes
          original_project = project
          project.discard
          put project_path(project), params: { project: new_attributes }, headers: request_login
          project.reload
          expect(project.name).to eq(original_project[:name])
          expect(project.description).to eq(original_project[:description])
        end

        it "renders not found when the project is not found" do
          put project_path(0), params: { project: new_attributes }, headers: request_login
          expect(response).to have_http_status(404)
          expect(response.content_type).to eq('application/json')
        end

        it "renders a JSON response with the project" do
          project = Project.create! valid_attributes

          put project_path(project), params: { project: new_attributes }, headers: request_login
          expect(response).to have_http_status(:ok)
          expect(response.content_type).to eq('application/json')
        end
      end

      context "with invalid params" do
        it "renders a JSON response with errors for the project" do
          project = Project.create! valid_attributes

          put project_path(project), params: { project: invalid_attributes }, headers: request_login
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.content_type).to eq('application/json')
        end
      end
    end

    describe "DELETE /api/v1/projects/:id" do
      it "soft deletes" do
        project = Project.create! valid_attributes
        expect do
          delete project_path(project.id), params: {}, headers: request_login
        end.to change(Project, :count).by(0)
      end

      it "sets discarded_at datetime" do
        project = Project.create! valid_attributes
        delete project_path(project.hashid), params: {}, headers: request_login
        project.reload
        expect(project.discarded?).to be true
      end

      it "renders a JSON response with the project" do
        project = Project.create! valid_attributes

        delete project_path(project.hashid), params: {}, headers: request_login
        expect(response).to have_http_status(204)
      end

      it "render not found when the project is deleted" do
        project = Project.create! valid_attributes
        project.discard
        delete project_path(project.id), params: {}, headers: request_login
        expect(response).to have_http_status(404)
      end

      it "render not found when the company is deleted" do
        project = Project.create! valid_attributes
        project.company.discard
        delete project_path(project.id), params: {}, headers: request_login
        expect(response).to have_http_status(404)
      end

      it "returns a not found response when project not found" do
        delete project_path(0), params: {}, headers: request_login
        expect(response).to be_not_found
      end
    end
  end

  describe "Unauthorised user" do
    describe "GET /api/v1/companies/:company_id/projects" do
      it "returns an unauthorized response" do
        project = Project.create! valid_attributes
        get company_projects_path(project.company.id), headers: nil

        expect_unauthorized
      end
    end

    describe "GET /projects/:id" do
      it "returns an unauthorized response" do
        project = Project.create! valid_attributes
        get project_path(project.id), headers: nil

        expect_unauthorized
      end
    end

    describe "POST /api/v1/companies/:company_id/projects" do
      it "does not create a new Project" do
        company = create(:company)

        expect do
          post company_projects_path(company.id), params: { project: valid_attributes }, headers: nil
        end.to change(Project, :count).by(0)
      end

      it "returns an unauthorized response" do
        company = create(:company)

        post company_projects_path(company.id), params: { project: valid_attributes }, headers: nil
        expect_unauthorized
      end
    end

    describe "PUT /projects/:id" do
      let(:new_attributes) do
        attributes_for(:project)
      end

      it "does not update the requested project" do
        project = Project.create! valid_attributes
        current_attributes = project.attributes

        put project_path(project), params: { project: new_attributes }, headers: nil
        project.reload
        expect(project.name).to eq(current_attributes["name"])
        expect(project.description).to eq(current_attributes["description"])
      end

      it "returns an unauthorized response" do
        project = Project.create! valid_attributes

        put project_path(project), params: { project: new_attributes }, headers: nil
        expect_unauthorized
      end
    end

    describe "DELETE /api/v1/projects/:id" do
      it "does not destroy the requested project" do
        project = Project.create! valid_attributes
        expect do
          delete project_path(project.id), params: {}, headers: nil
        end.to change(Project, :count).by(0)
      end

      it "does not set discarded_at datetime" do
        project = Project.create! valid_attributes
        delete project_path(project.id), params: {}, headers: nil
        project.reload
        expect(project.discarded?).to be false
      end

      it "returns an unauthorized response" do
        project = Project.create! valid_attributes

        delete project_path(project.id), params: {}, headers: nil
        expect_unauthorized
      end
    end
  end
end