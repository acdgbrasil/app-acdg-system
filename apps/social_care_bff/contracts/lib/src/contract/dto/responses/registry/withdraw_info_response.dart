import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'withdraw_info_response.g.dart';

@JsonSerializable()
class WithdrawInfoResponse with Equatable {
  const WithdrawInfoResponse({
    required this.reason,
    required this.withdrawnAt,
    required this.withdrawnBy,
    this.notes,
  });

  factory WithdrawInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$WithdrawInfoResponseFromJson(json);

  final String reason;
  final String? notes;
  final String withdrawnAt;
  final String withdrawnBy;

  Map<String, dynamic> toJson() => _$WithdrawInfoResponseToJson(this);

  @override
  List<Object?> get props => [reason, notes, withdrawnAt, withdrawnBy];
}
