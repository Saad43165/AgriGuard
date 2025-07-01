class AppStrings {
  // TODO: Consider using `intl` package for localization support in the future

  // Authentication
  /// Shown on the login screen title
  static const String welcomeBack = 'Welcome Back';
  /// Subtitle for login screen
  static const String signInSubtitle = 'Sign in to continue protecting your crops';
  /// Shown on the registration screen title
  static const String joinAgriGuard = 'Join AgriGuard';
  /// Subtitle for registration screen
  static const String registerSubtitle = 'Create an account to start protecting your crops';
  /// Button text for login action
  static const String login = 'Login';
  /// Button text for registration action
  static const String register = 'Register';
  /// Button text for creating a new account
  static const String createAccount = 'Create Account';
  /// Prompt for users who already have an account
  static const String alreadyHaveAccount = 'Already have an account?';
  /// Prompt for new users on login screen
  static const String newFarmer = 'New Farmer?';
  /// Link text for forgot password option
  static const String forgotPassword = 'Forgot Password?';
  /// Title for reset password screen
  static const String resetPassword = 'Reset Password';
  /// Subtitle for reset password screen
  static const String resetPasswordSubtitle = 'Enter your email to receive a password reset link';
  /// Button text for sending reset link
  static const String sendResetLink = 'Send Reset Link';

  // Input Hints
  /// Hint text for email input field
  static const String emailHint = 'your@email.com';
  /// Hint text for password input field
  static const String passwordHint = 'Enter your password';
  /// Hint text for confirm password input field
  static const String confirmPasswordHint = 'Confirm your password';
  /// Hint text for full name input field
  static const String nameHint = 'Enter your full name';

  // Feedback and Errors
  /// Success message for account creation
  static const String accountCreated = 'Account created successfully';
  /// Error message for duplicate email during registration
  static const String emailAlreadyRegistered = 'Email is already registered';
  /// Error message for invalid login credentials
  static const String invalidCredentials = 'Invalid email or password';
  /// Error message when no account is found for the email
  static const String noAccountFound = 'No account found with this email';
  /// Success message for sending password reset link
  static const String resetLinkSent = 'Password reset link sent to your email';
  /// Error message when scan refresh fails
  static const String scanRefreshFailed = 'Failed to refresh scans. Please try again.';
  /// Error message when image fails to load
  static const String failedToLoadImage = 'Failed to Load Image';
  /// Error message when image picking fails
  static const String failedToPickImage = 'Failed to pick image. Please try again.';
  /// Error message when image processing fails
  static const String failedToProcessImage = 'Failed to process image. Please try again.';

  // Home and Scanning
  /// Welcome message on home screen
  static const String welcome = 'Welcome';
  /// Title for recent scans section
  static const String recentScans = 'Recent Scans';
  /// Message when no scans are available
  static const String noScansAvailable = 'No recent scans available';
  /// Button text to start a new scan
  static const String startNewScan = 'Start New Scan';
  /// Prompt for first-time users to scan
  static const String getStartedScan = 'Get started by scanning your first plant!';
  /// Message for crop health insights
  static const String cropHealthInsights = 'Monitor your crop health with real-time insights';
  /// Title for scanning a plant
  static const String scanYourPlant = 'Scan Your Plant';
  /// Prompt to scan the first plant
  static const String scanFirstPlant = 'Scan your first plant to see results here';
  /// Action to refresh scans
  static const String refreshScans = 'Refresh Scans';
  /// Success message for refreshing scans
  static const String scansRefreshed = 'Scans refreshed successfully';
  /// Message when no scans exist
  static const String noScansYet = 'No Scans Yet';
  /// Link text to view all scans
  static const String viewAll = 'View All';

  // Image Capture
  /// Message when no image is selected
  static const String noImageSelected = 'No Image Selected';
  /// Prompt to capture or select a leaf image
  static const String captureOrSelectLeaf = 'Capture or select a leaf image';
  /// Title for scan plant screen
  static const String scanPlant = 'Scan Plant';
  /// Button text for editing and analyzing an image
  static const String editAndAnalyze = 'Edit and Analyze';
  /// Label for camera option
  static const String camera = 'Camera';
  /// Label for gallery option
  static const String gallery = 'Gallery';
  /// Instruction for capturing a leaf photo
  static const String captureClearLeafPhoto = 'Capture a clear photo of your plant’s leaves';

  // Onboarding / Tutorial
  /// Title for onboarding guide
  static const String howToGetStarted = 'How to Get Started';
  /// Prefix for onboarding steps
  static const String step = 'Step';
  /// Title for diagnosis step
  static const String getDiagnosis = 'Get Diagnosis';
  /// Description for diagnosis step
  static const String aiAnalyzesSymptoms = 'Our AI analyzes symptoms and identifies issues';
  /// Title for recommendations step
  static const String viewRecommendations = 'View Recommendations';
  /// Description for recommendations step
  static const String tailoredTreatmentAdvice = 'Receive tailored treatment advice';

  // Image Editing
  /// Title for image editing screen
  static const String editImage = 'Edit Image';
  /// Button text for undoing an action
  static const String undo = 'Undo';
  /// Button text for redoing an action
  static const String redo = 'Redo';
  /// Button text to save edited image
  static const String save = 'Save';
  /// Button text to reset image edits
  static const String reset = 'Reset';
  /// Label for selecting color
  static const String selectColor = 'Select Color';
  /// Button text to clear marks
  static const String clearMarks = 'Clear Marks';
  /// Label for selecting highlight color
  static const String selectHighlightColor = 'Select Highlight Color';
  /// Button text for confirmation
  static const String ok = 'OK';
  /// Button text for analyzing image
  static const String analyze = 'Analyze';
  /// Label for brightness adjustment
  static const String brightness = 'Brightness';
  /// Label for contrast adjustment
  static const String contrast = 'Contrast';
  /// Label for saturation adjustment
  static const String saturation = 'Saturation';
  /// Label for hue adjustment
  static const String hue = 'Hue';
  /// Label for temperature adjustment
  static const String temperature = 'Temperature';
  /// Label for tint adjustment
  static const String tint = 'Tint';
  /// Label for highlight size adjustment
  static const String highlightSize = 'Highlight Size';
  /// Label for choosing a color
  static const String chooseColor = 'Choose Color';
  /// Button text to start cropping
  static const String startCrop = 'Start Crop';
  /// Button text to apply crop
  static const String applyCrop = 'Apply Crop';
  /// Button text to reset crop
  static const String resetCrop = 'Reset Crop';
  /// Label for brush size adjustment
  static const String brushSize = 'Brush Size';
  /// Label for brush opacity adjustment
  static const String brushOpacity = 'Brush Opacity';
  /// Label for entering text annotation
  static const String enterText = 'Enter Text';
  /// Label for blur effect
  static const String blur = 'Blur';
  /// Label for posterize effect
  static const String posterize = 'Posterize';
  /// Label for grayscale effect
  static const String grayscale = 'Grayscale';
  /// Label for sepia effect
  static const String sepia = 'Sepia';

  // Profile and Other
  /// Button text for logout action
  static const String logout = 'Logout';
  /// Placeholder for profile screen title
  static const String profile = 'Profile';
  /// Placeholder for scan history screen title
  static const String history = 'History';
  /// Placeholder for scan results screen title
  static const String results = 'Results';

  static const String done = 'Done';
}