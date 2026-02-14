require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:html_headers) { { "Accept" => "text/html" } }

  describe "POST /users (sign up)" do
    let(:valid_params) do
      {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123",
          first_name: "Ivan",
          last_name: "Petrov"
        }
      }
    end

    it "creates a new user with valid params" do
      expect {
        post user_registration_path, params: valid_params, headers: html_headers
      }.to change(User, :count).by(1)
    end

    it "rejects registration with missing fields" do
      expect {
        post user_registration_path,
             params: { user: { email: "test@test.com", password: "password123", password_confirmation: "password123" } },
             headers: html_headers
      }.not_to change(User, :count)
    end
  end

  describe "POST /users/sign_in" do
    let!(:user) { create(:user, email: "test@example.com", password: "password123") }

    it "signs in with valid credentials" do
      post user_session_path,
           params: { user: { email: "test@example.com", password: "password123" } },
           headers: html_headers
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(root_path)
    end

    it "rejects invalid credentials" do
      post user_session_path,
           params: { user: { email: "test@example.com", password: "wrong" } },
           headers: html_headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /users/sign_out" do
    let(:user) { create(:user) }

    it "signs out the user" do
      sign_in user
      delete destroy_user_session_path, headers: html_headers
      expect(response).to redirect_to(root_path)
    end
  end

  describe "unauthorized access" do
    it "redirects unauthenticated user to sign in" do
      get media_files_path, headers: html_headers
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
