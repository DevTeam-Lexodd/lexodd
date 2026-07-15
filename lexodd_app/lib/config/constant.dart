class AppConstants {
  // API Configuration - Production
  static const String baseUrl = 'https://lexodd-app.onrender.com/api';
  
  // API Configuration - Local Development
  // static const String baseUrl = 'http://10.0.2.2:5001/api'; // Android Emulator
  // static const String baseUrl = 'http://localhost:5001/api'; // iOS Simulator

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String employeeKey = 'employee_data';

  // App Info
  static const String appName = 'Lexodd HRMS';
  static const String appVersion = '1.0.0';

  // Departments
  static const List<String> departments = [
    'Engineering', 'Human Resources', 'Finance', 'Marketing',
    'Sales', 'Operations', 'Customer Support', 'Design',
    'Product', 'Legal', 'Administration', 'IT', 'Research', 'Other'
  ];

  // Employment Types
  static const List<String> employmentTypes = ['Full-time', 'Part-time', 'Contract', 'Intern', 'Freelance'];

  // Gender Options
  static const List<String> genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  // Blood Groups
  static const List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  // Marital Status
  static const List<String> maritalStatusOptions = ['Single', 'Married', 'Divorced', 'Widowed'];

  // Work Locations
  static const List<String> workLocations = ['Office', 'Remote', 'Hybrid'];

  // Carousel Items
  static const List<Map<String, String>> carouselItems = [
    {
      'title': 'Welcome to Lexodd',
      'subtitle': 'Your complete employee management solution',
    },
    {
      'title': 'Team Collaboration',
      'subtitle': 'Work together, achieve together',
    },
    {
      'title': 'Growth & Development',
      'subtitle': 'Track your career progress',
    },
  ];
}
