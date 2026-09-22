require "test_helper"

class ApplicationHeaderTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:chris))
  end

  test "shows the account name and signed in user" do
    get root_url

    assert_response :success
    assert_select "header.app-header" do
      assert_select "a.app-header-brand[href=?]", root_path, text: accounts(:pymm_account).name
      assert_select ".app-header-user-name", text: users(:chris).email_address
    end
  end

  test "offers profile, account settings and sign out in the user menu" do
    get root_url

    assert_select ".app-header-menu" do
      assert_select "a.app-header-menu-item[href=?]", edit_profile_path, text: "Edit profile"
      assert_select "a.app-header-menu-item[href=?]", edit_account_path, text: "Account settings"
      assert_select "form.app-header-menu-form[action=?]", session_path do
        assert_select "input[name='_method'][value=?]", "delete"
        assert_select "button", text: "Sign out"
      end
    end
  end

  test "menu is collapsed and driven by the dropdown controller" do
    get root_url

    assert_select ".app-header-user[data-controller=?]", "dropdown"
    assert_select "button.app-header-user-button[aria-expanded=?]", "false"
    assert_select ".app-header-menu[hidden]"
  end

  test "renders on pages other than the calendar" do
    get edit_account_url

    assert_response :success
    assert_select "header.app-header a.app-header-brand", text: accounts(:pymm_account).name
  end

  test "is hidden when signed out" do
    sign_out

    get new_session_url

    assert_response :success
    assert_select "header.app-header", count: 0
  end

  test "calendar controls no longer duplicate the header actions" do
    get root_url

    assert_select ".calendar-controls a[href=?]", edit_account_path, count: 0
    assert_select ".calendar-controls a[href=?]", session_path, count: 0
  end
end
