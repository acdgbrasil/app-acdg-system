final class RegisterWorkerIntent {
  const RegisterWorkerIntent({
    required this.fullName,
    required this.birthDate,
    required this.email,
    required this.role,
    this.cpf,
    this.initialPassword,
  });

  final String fullName;
  final String birthDate;
  final String email;
  final String role;
  final String? cpf;
  final String? initialPassword;
}
