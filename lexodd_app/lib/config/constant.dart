class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android Emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS Simulator
  // static const String baseUrl = 'http://YOUR_IP:5000/api'; // Physical Device

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String employeeKey = 'employee_data';
  static const String onboardingKey = 'onboarding_complete';

  // App Info
  static const String appName = 'EMS Portal';
  static const String appVersion = '1.0.0';

  // Departments
  static const List<String> departments = [
    'Engineering',
    'Human Resources',
    'Finance',
    'Marketing',
    'Sales',
    'Operations',
    'Customer Support',
    'Design',
    'Product',
    'Legal',
    'Administration',
    'IT',
    'Research',
    'Other'
  ];

  // Employment Types
  static const List<String> employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Intern',
    'Freelance'
  ];

  // Gender Options
  static const List<String> genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];

  // Blood Groups
  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  // Marital Status
  static const List<String> maritalStatusOptions = [
    'Single', 'Married', 'Divorced', 'Widowed'
  ];

  // Work Locations
  static const List<String> workLocations = ['Office', 'Remote', 'Hybrid'];

  // Carousel Images
  static const List<String> carouselImages = [
    'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800',
    'https://https://images.unsplash.com/photo-1552664730-d307ca884978?w=800',
    'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=800',
  ];

  // Carousel Captions
  static const List<Map<String, String>> carouselItems = [
    {
      'title': 'Welcome to EMS',
      'subtitle': 'Your complete employee management solution',
      'image': 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800',
    },
    {
      'title': 'Team Collaboration',
      'subtitle': 'Work together, achieve together',
      'image': 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=800',
    },
    {
      'title': 'Growth & Development',
      'subtitle': 'Track your career progress',
      'image': 'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=800',
    },
  ];
}
