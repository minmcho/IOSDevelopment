# SwiftUI Login Interface

A modern SwiftUI login interface with support for traditional email/password authentication, Gmail, and Hotmail/Outlook sign-in.

## Features

- Clean and modern UI design
- Email/Password authentication
- Gmail OAuth integration (placeholder)
- Hotmail/Outlook OAuth integration (placeholder)
- Form validation
- Loading states
- Error handling
- Responsive design

## Project Structure

```
Sources/
├── LoginApp.swift              # Main app entry point
├── Models/
│   └── User.swift              # User data model
├── ViewModels/
│   └── AuthenticationViewModel.swift  # Authentication logic
└── Views/
    ├── ContentView.swift       # Root view with auth state management
    └── LoginView.swift         # Login UI
```

## Setup Instructions

### Basic Setup

1. Open the project in Xcode
2. Build and run on iOS 15.0 or later

### Gmail Authentication Setup

To enable Gmail sign-in:

1. **Add Google Sign-In SDK**:
   - Add package dependency: `https://github.com/google/GoogleSignIn-iOS`

2. **Configure Google Cloud Console**:
   - Create a project at [Google Cloud Console](https://console.cloud.google.com/)
   - Enable Google Sign-In API
   - Create OAuth 2.0 client ID (iOS)
   - Note your client ID

3. **Update Info.plist**:
   ```xml
   <key>GIDClientID</key>
   <string>YOUR_CLIENT_ID_HERE</string>
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
       </array>
     </dict>
   </array>
   ```

4. **Update AuthenticationViewModel.swift**:
   - Uncomment the Google Sign-In implementation code
   - Import GoogleSignIn framework

### Hotmail/Outlook Authentication Setup

To enable Hotmail/Outlook sign-in:

1. **Add Microsoft Authentication Library (MSAL)**:
   - Add package dependency: `https://github.com/AzureAD/microsoft-authentication-library-for-objc`

2. **Register App in Azure Portal**:
   - Go to [Azure Portal](https://portal.azure.com/)
   - Register a new application
   - Add iOS platform
   - Configure redirect URI: `msauth.[BUNDLE_ID]://auth`
   - Note your Application (client) ID

3. **Update Info.plist**:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>msauth.[BUNDLE_ID]</string>
       </array>
     </dict>
   </array>
   <key>LSApplicationQueriesSchemes</key>
   <array>
     <string>msauthv2</string>
     <string>msauthv3</string>
   </array>
   ```

4. **Update AuthenticationViewModel.swift**:
   - Uncomment the MSAL implementation code
   - Import MSAL framework

## Current Implementation

The current implementation includes:
- Fully functional UI components
- Mock authentication for demonstration
- Proper state management
- Error handling framework

The OAuth integrations are prepared with placeholder code and detailed TODO comments for actual implementation.

## Testing

For testing purposes, use:
- Email: Any email containing "test"
- Password: Any password with 6+ characters

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## Next Steps

1. Implement actual backend authentication API
2. Add Google Sign-In SDK and configure OAuth
3. Add Microsoft MSAL and configure Azure AD
4. Add secure token storage (Keychain)
5. Implement password reset functionality
6. Add biometric authentication (Face ID/Touch ID)
7. Add sign-up flow

## License

This is a sample project for demonstration purposes.
