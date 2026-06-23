class ApiEndpoints {
  static const String dashboardAdmin = '/dashboard/admin';
  static const String dashboardWaiter = '/dashboard/waiter';
  static const String dashboardKitchen = '/dashboard/kitchen';
  static const String dashboardCashier = '/dashboard/cashier';

  static const String login = "/auth/login";
  static const String userRegister = "/auth/user-register";
  static const String verifyEmail = "/auth/verify-email";
  static const String me = "/auth/me";
  static const String categories = "/categories";
  static const String menus = "/menus";
  static const String orders = "/orders";
  static const String activeOrders = "/orders/active";
  static const String users = "/users";
  static const String imageUpload = "/images/upload";

  // ─── Email ────────────────────────────────────────────────────────────────
  static const String emailSendCustom = "/emails/send-custom";
  static const String emailSendBulk = "/emails/send-bulk";
}
