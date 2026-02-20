require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:html_headers) { { "Accept" => "text/html" } }
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  before { sign_in admin }

  describe "GET /admin/users" do
    let!(:other_user) { create(:user) }

    it "returns list of users" do
      get admin_users_path, headers: html_headers
      expect(response).to have_http_status(:ok)
    end

    it "shows all users" do
      get admin_users_path, headers: html_headers
      expect(response.body).to include(admin.email, other_user.email)
    end

    it "denies access to non-admin users" do
      sign_in regular_user
      get admin_users_path, headers: html_headers
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /admin/users/:id" do
    context "when changing another user's role" do
      it "promotes a user to admin" do
        patch admin_user_path(regular_user),
              params: { user: { role: "admin" } },
              headers: html_headers
        expect(regular_user.reload.role).to eq("admin")
      end

      it "demotes an admin to user" do
        other_admin = create(:user, :admin)
        patch admin_user_path(other_admin),
              params: { user: { role: "user" } },
              headers: html_headers
        expect(other_admin.reload.role).to eq("user")
      end

      it "redirects to users list with notice" do
        patch admin_user_path(regular_user),
              params: { user: { role: "admin" } },
              headers: html_headers
        expect(response).to redirect_to(admin_users_path)
        follow_redirect!
        expect(response.body).to include("изменена")
      end
    end

    context "when trying to change own role" do
      it "does not change the role" do
        patch admin_user_path(admin),
              params: { user: { role: "user" } },
              headers: html_headers
        expect(admin.reload.role).to eq("admin")
      end

      it "redirects with alert" do
        patch admin_user_path(admin),
              params: { user: { role: "user" } },
              headers: html_headers
        expect(response).to redirect_to(admin_users_path)
        follow_redirect!
        expect(response.body).to include("Нельзя изменить собственную роль")
      end
    end

    context "when denying access to non-admin" do
      it "redirects to root" do
        sign_in regular_user
        patch admin_user_path(admin),
              params: { user: { role: "user" } },
              headers: html_headers
        expect(response).to redirect_to(root_path)
      end
    end

    context "when passing invalid role" do
      it "redirects with alert and does not change role" do
        patch admin_user_path(regular_user),
              params: { user: { role: "superuser" } },
              headers: html_headers
        expect(response).to redirect_to(admin_users_path)
        expect(regular_user.reload.role).to eq("user")
        follow_redirect!
        expect(response.body).to include("Недопустимая роль")
      end
    end
  end
end
