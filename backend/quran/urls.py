from django.urls import path, include
from . import views

urlpatterns = [
    path('bookmarks/', views.BookmarkListCreateView.as_view(), name='bookmark-list-create'),
    path('bookmarks/<int:pk>/delete/', views.BookmarkDeleteView.as_view(), name='bookmark-delete'),
    path('reading-progress/', views.ReadingProgressView.as_view(), name='reading-progress'),
]