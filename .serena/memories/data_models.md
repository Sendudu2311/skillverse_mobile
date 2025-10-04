# Data Models and DTOs

## Authentication DTOs
Based on the existing TypeScript interfaces, these need to be converted to Dart models:

### User Authentication
- `LoginRequest` - email, password
- `RegisterRequest` - registration data
- `AuthResponse` - authentication response with tokens
- `UserDto` - user information (id, email, fullName, roles)
- `RefreshTokenRequest` - token refresh
- `VerifyEmailRequest` - email verification
- `ResendOtpRequest` - OTP resend

### User Profile DTOs
- `UserProfileResponse` - complete user profile
- `UserSkillResponse` - user skills information
- `MentorProfileResponse` - mentor-specific profile
- `BusinessProfileResponse` - business user profile
- `ApplicationStatusResponse` - application status tracking

### Registration Types
- `BaseRegistrationRequest` - common registration fields
- `UserRegistrationRequest` - regular user registration
- `MentorRegistrationRequest` - mentor registration
- `BusinessRegistrationRequest` - business registration

### Location Data
- `Province` - province information
- `District` - district information

## Learning Data Models
### Roadmap Structure
- Roadmap with id, title, category, progress, steps
- RoadmapStep with completion status, duration
- Categories: Programming, Data Science, Marketing, Infrastructure, Design

### Course Structure
- Course information with progress tracking
- Learning goals and achievements
- Recent courses and recommendations

## API Response Models
- `ApiErrorResponse` - standardized error handling
- Various response wrappers for different endpoints