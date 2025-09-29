/// Enum representing the types of services a mentor can offer
enum ServiceType {
  virtualAppointments,
  chats,
  both;

  /// Display name for the service type
  String get displayName {
    switch (this) {
      case ServiceType.virtualAppointments:
        return 'Virtual Appointments';
      case ServiceType.chats:
        return 'Chat Sessions';
      case ServiceType.both:
        return 'Both Services';
    }
  }

  /// Description for the service type
  String get description {
    switch (this) {
      case ServiceType.virtualAppointments:
        return 'Schedule video calls with mentees';
      case ServiceType.chats:
        return 'Offer text-based mentoring sessions';
      case ServiceType.both:
        return 'Provide both video calls and chat sessions';
    }
  }

  /// Icon name for the service type
  String get iconName {
    switch (this) {
      case ServiceType.virtualAppointments:
        return 'video_call';
      case ServiceType.chats:
        return 'chat';
      case ServiceType.both:
        return 'all_inclusive';
    }
  }

  /// Convert from string representation
  static ServiceType fromString(String value) {
    switch (value) {
      case 'virtualAppointments':
        return ServiceType.virtualAppointments;
      case 'chats':
        return ServiceType.chats;
      case 'both':
        return ServiceType.both;
      default:
        return ServiceType.both;
    }
  }

  /// Convert to string representation for storage
  String toString() => name;
}
