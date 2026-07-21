enum ServiceType {
  virtualAppointments,
  chats,
  both;

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

  static ServiceType fromString(String value) {
    switch (value) {
      case 'virtualAppointments':
        return ServiceType.virtualAppointments;
      case 'chats':
        return ServiceType.chats;
      case 'both':
      default:
        return ServiceType.both;
    }
  }
}
