from django.shortcuts import get_object_or_404

from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView

from rest_framework_simplejwt.tokens import RefreshToken

from .models import User
from .serializers import (
    RegisterSerializer,
    LoginSerializer,
    ChangePasswordSerializer,
    UserProfileSerializer,
    AdminChangePasswordSerializer,
    AdminCreateUserSerializer,
    AdminUserUpdateSerializer
)
from .permissions import IsAdmin


# ======================================================
# AUTH
# ======================================================

# ------------------------------
# Register
# ------------------------------
class RegisterView(generics.CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]


# ------------------------------
# Login → return JWT tokens
# ------------------------------
class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = serializer.validated_data["user"]
        refresh = RefreshToken.for_user(user)

        return Response(
            {
                "refresh": str(refresh),
                "access": str(refresh.access_token),
                "user": UserProfileSerializer(user).data,
            },
            status=status.HTTP_200_OK,
        )


# ------------------------------
# Logout → blacklist refresh token
# ------------------------------
class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data["refresh"]
            token = RefreshToken(refresh_token)
            token.blacklist()

            return Response(
                {"detail": "Logged out successfully"},
                status=status.HTTP_205_RESET_CONTENT,
            )
        except Exception:
            return Response(
                {"detail": "Invalid or expired refresh token"},
                status=status.HTTP_400_BAD_REQUEST,
            )


# ======================================================
# USER SELF ACTIONS
# ======================================================

# ------------------------------
# Change own password
# ------------------------------
class ChangePasswordView(generics.UpdateAPIView):
    serializer_class = ChangePasswordSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


# ------------------------------
# Get / Update own profile
# ------------------------------
class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


# ======================================================
# ADMIN USER MANAGEMENT
# ======================================================

# ------------------------------
# Get ALL users (Admin)
# ------------------------------
class AdminUserListView(generics.ListAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [IsAdmin]

    def get_queryset(self):
        queryset = User.objects.all().order_by("-id")

        phone = self.request.query_params.get("phone")
        role = self.request.query_params.get("role")

        if phone:
            queryset = queryset.filter(phone__icontains=phone)
        if role:
            queryset = queryset.filter(role__iexact=role)

        return queryset



# ------------------------------
# Get user by ID (Admin)
# ------------------------------
class AdminUserDetailView(generics.RetrieveAPIView):
    queryset = User.objects.all()
    serializer_class = UserProfileSerializer
    permission_classes = [IsAdmin]
    lookup_field = "id"


# ------------------------------
# Update user by ID (Admin)
# ------------------------------
class AdminUserUpdateView(generics.UpdateAPIView):
    queryset = User.objects.all()
    serializer_class = AdminUserUpdateSerializer
    permission_classes = [IsAdmin]
    lookup_field = "id"


# ------------------------------
# Change user password (Admin)
# No old password required
# ------------------------------
class AdminChangeUserPasswordView(APIView):
    permission_classes = [IsAdmin]

    def post(self, request, id):
        user = get_object_or_404(User, id=id)

        serializer = AdminChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user.set_password(serializer.validated_data["new_password"])
        user.save()

        return Response(
            {"detail": "Password changed successfully"},
            status=status.HTTP_200_OK,
        )


# user/views.py

class AdminCreateUserView(generics.CreateAPIView):
    serializer_class = AdminCreateUserSerializer
    permission_classes = [IsAdmin]
