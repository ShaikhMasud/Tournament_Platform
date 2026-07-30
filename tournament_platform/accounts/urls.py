from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .views import LogoutView, SessionView, SignupView

urlpatterns = [
    path("signup", SignupView.as_view(), name="auth-signup"),
    path("login", TokenObtainPairView.as_view(), name="auth-login"),
    path("refresh", TokenRefreshView.as_view(), name="auth-refresh"),
    path("logout", LogoutView.as_view(), name="auth-logout"),
    path("session", SessionView.as_view(), name="auth-session"),
]
