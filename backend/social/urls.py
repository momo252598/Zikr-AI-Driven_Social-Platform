from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'posts', views.PostViewSet)
router.register(r'comments', views.CommentViewSet, basename='comment')
router.register(r'tags', views.TagViewSet)

app_name = 'social'

urlpatterns = [
    path('', include(router.urls)),
]