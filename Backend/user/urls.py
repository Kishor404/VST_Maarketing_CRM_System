from django.urls import path

from .views import (
    # Auth
    RegisterView,
    LoginView,
    LogoutView,

    # User self
    ChangePasswordView,
    ProfileView,

    # Admin
    AdminUserListView,
    AdminUserDetailView,
    AdminUserUpdateView,
    AdminChangeUserPasswordView,
    AdminCreateUserView
)

urlpatterns = [
    # ==========================
    # AUTH
    # ==========================
    path("register/", RegisterView.as_view(), name="register"),
    path("login/", LoginView.as_view(), name="login"),
    path("logout/", LogoutView.as_view(), name="logout"),

    # ==========================
    # USER SELF
    # ==========================
    path("me/", ProfileView.as_view(), name="profile"),
    path("change-password/", ChangePasswordView.as_view(), name="change-password"),

    # ==========================
    # ADMIN USER MANAGEMENT
    # ==========================
    path("admin/users/", AdminUserListView.as_view(), name="admin-user-list"),
    path("admin/users/<int:id>/", AdminUserDetailView.as_view(), name="admin-user-detail"),
    path("admin/users/<int:id>/update/", AdminUserUpdateView.as_view(), name="admin-user-update"),
    path(
        "admin/users/<int:id>/change-password/",
        AdminChangeUserPasswordView.as_view(),
        name="admin-user-change-password",
    ),
    path(
        "admin/users/create/",
        AdminCreateUserView.as_view(),
        name="admin-user-create",
    ),
    
]
