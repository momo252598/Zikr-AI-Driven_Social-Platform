# Zikr: AI-Driven Islamic Social Platform

Zikr is a graduation project that combines an Islamic social community with AI-powered religious learning tools in one platform.

The system is designed to support Muslims worldwide through authentic content, meaningful social interaction, and practical daily worship features.

## Project Overview

Most Islamic applications focus on one isolated feature (for example, prayer times or Quran reading). Zikr takes a unified approach by integrating:

- A social feed for sharing posts, comments, likes, and discussions
- A Quran reading and study experience with topic-based verse highlighting
- A multilingual Islamic QA assistant based on Retrieval-Augmented Generation (RAG)
- Personalized post recommendations using a fuzzy-logic suggestion algorithm
- Real-time chat and push notifications
- Daily Azkar and prayer-time utilities

This repository contains the main full-stack application (Flutter frontend + Django backend).

## Core AI Components

1. RAG Islamic Assistant
- Answers Islamic Fatawa questions in Arabic and English
- Uses retrieval over curated Islamic sources before generating responses
- Built to improve relevance, grounding, and trustworthiness

2. Quran Topic Modeling
- Uses K-Means clustering to group Quranic content by theme
- Applies visual highlighting to verses to support focused reading and study

3. Fuzzy Recommendation Engine
- Suggests social posts using user behavior and topic affinity
- Balances personalization with content diversity

## System Architecture

- Frontend: Flutter (mobile + web)
- Backend: Django + Django REST Framework
- Auth: JWT-based authentication
- Data layer: PostgreSQL (configured via environment variables), Firebase services, and Supabase storage integration
- Realtime/Notifications: Firebase (chat/auth token flow and push notifications)

Main backend modules:
- accounts: registration, login, profile, verification, auth workflows
- social: posts, likes, comments, feed, recommendation hooks
- quran: Quran reading, bookmarking, and related endpoints
- chat: conversations, messaging, Firebase token integration

## Key Features

- User registration, login, profile management, and password reset
- Sheikh verification workflow and admin review tools
- Islamic social feed with topic filtering and engagement actions
- Quran reading interface with bookmarks, tafseer access, and audio recitation controls
- AI chatbot for Islamic Q&A
- Daily Azkar and prayer-time support
- Real-time messaging and notification delivery

## Repository Structure

- Frontend/: Flutter application
- backend/: Django REST backend
- assets/: static assets, Quran/azkar data files, fonts, and app resources
- Report.pdf: full graduation report and methodology

## Getting Started

### 1) Backend Setup (Django)

Prerequisites:
- Python 3.11+
- PostgreSQL

Steps:

```bash
cd backend
python -m venv venv
# Windows
venv\Scripts\activate
# Linux/macOS
# source venv/bin/activate

pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

Backend will run on:
- http://127.0.0.1:8000/

### 2) Frontend Setup (Flutter)

Prerequisites:
- Flutter SDK (3.x)

Steps:

```bash
cd Frontend
flutter pub get
flutter run
```

For web:

```bash
flutter run -d chrome
```

## Environment Configuration

Before running in your own environment, configure secrets and infrastructure settings for:

- Database credentials
- Firebase project keys and service account
- Supabase URL, key, and storage buckets
- Email SMTP settings

Important: do not commit real credentials to public repositories.

## Testing

Backend tests can be run with:

```bash
cd backend
pytest
```

## Related Work

K-Means Quran topic model repository:
- https://github.com/mo-matar/K-means-Topic-Modeling-of-Quran

## Academic Context

This project was developed as part of the Bachelor of Science in Computer Engineering at An-Najah National University (2025).

The full technical report (problem statement, methodology, system analysis, results, and discussion) is available in this repository as Report.pdf.
