# Niti Therapist App

A Flutter application for therapists to manage their bookings, view analytics, and interact with the community.

## Features

### 🔐 Authentication
- Secure login with phone number and password
- Token-based authentication with automatic expiry handling
- Persistent login state with SharedPreferences
- Automatic logout on token expiration

### 🏠 Home Screen
- View and manage bookings
- Filter bookings by status (All, Booked, Confirmed, Pending, Cancelled, Completed)
- Search bookings by client name or type
- Cancel bookings with confirmation
- Copy meeting links to clipboard
- Pull-to-refresh functionality

### 📊 Analytics Screen
- Real-time analytics data from backend
- Monthly booking trends
- Earnings overview
- Success rate calculations
- Interactive charts using fl_chart

### 👥 Community Screen
- View community posts
- Create new posts with anonymous option
- Like and comment on posts
- Pull-to-refresh functionality

### 👤 Profile Screen
- View and edit profile information
- Display expertise, languages, and qualifications
- Show availability schedule
- Logout functionality

## Architecture Improvements

### 🔧 Centralized API Service
- `ApiService` class handles all backend communication
- Consistent error handling and response parsing
- Automatic token management
- Timeout handling for network requests

### 🗄️ Enhanced Auth Service
- Token caching and validation
- Automatic token expiry checking
- User data caching for better performance
- Stream-based auth state management

### 📱 State Management
- `AppState` class for global state management
- Stream-based data updates across screens
- Cached data for offline functionality
- Automatic data synchronization

### 🎨 UI/UX Improvements
- Consistent loading states
- Better error handling with user-friendly messages
- Pull-to-refresh on all screens
- Improved snackbar notifications
- Responsive design with proper scaling

## Technical Stack

- **Framework**: Flutter
- **State Management**: Streams and Singleton pattern
- **HTTP Client**: http package
- **Local Storage**: SharedPreferences
- **Charts**: fl_chart
- **Architecture**: Service-oriented with centralized API layer

## API Endpoints

The app communicates with the following backend endpoints:

- `POST /api/userLogin` - User authentication
- `POST /api/getPsychologistHomePage` - Get bookings
- `GET /api/getUserProfile/{id}` - Get user profile
- `GET /api/getAnalytics/{id}` - Get analytics data
- `POST /api/cancelBooking` - Cancel booking
- `GET /api/getCommunityPosts` - Get community posts
- `POST /api/createCommunityPost` - Create community post

## Getting Started

1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

## Key Improvements Made

### Flow Issues Fixed:
1. **Auth Wrapper**: Simplified and made more robust with better error handling
2. **Data Persistence**: Added proper caching and state management
3. **Error Handling**: Consistent error handling across all screens
4. **API Calls**: Centralized API service with proper error management
5. **State Management**: Added global state management for better data flow
6. **Loading States**: Consistent loading states and user feedback

### Data Flow Improvements:
1. **Login Flow**: Streamlined authentication with proper token management
2. **Home Screen**: Real-time data fetching with caching and refresh capabilities
3. **Analytics**: Live data from backend with fallback to cached data
4. **Community**: Real-time post creation and viewing
5. **Profile**: Cached user data with backend synchronization

### User Experience Enhancements:
1. **Loading Indicators**: Proper loading states on all screens
2. **Error Messages**: User-friendly error messages with retry options
3. **Pull-to-Refresh**: Added to all screens for better UX
4. **Snackbar Notifications**: Consistent notification system
5. **Responsive Design**: Better scaling across different screen sizes

## Future Enhancements

- [ ] Push notifications for new bookings
- [ ] Offline mode with local data storage
- [ ] Real-time chat functionality
- [ ] Video call integration
- [ ] Payment processing
- [ ] Multi-language support
