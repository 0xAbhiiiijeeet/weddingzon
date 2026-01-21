class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? nextCursor;
  final List<dynamic>? errors;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.nextCursor,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      nextCursor: json['nextCursor'],
      errors: json['errors'] as List<dynamic>?,
    );
  }
}
