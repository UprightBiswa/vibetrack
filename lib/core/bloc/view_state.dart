import 'package:equatable/equatable.dart';
import 'package:vibetreck/core/bloc/view_status.dart';

class ViewState<T> extends Equatable {
  const ViewState({
    this.status = ViewStatus.initial,
    this.data,
    this.errorMessage,
  });

  final ViewStatus status;
  final T? data;
  final String? errorMessage;

  bool get isInitial => status == ViewStatus.initial;
  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isFailure => status == ViewStatus.failure;

  ViewState<T> copyWith({
    ViewStatus? status,
    T? data,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ViewState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];

  @override
  String toString() {
    return 'ViewState(status: $status, data: $data, errorMessage: $errorMessage)';
  }
}
