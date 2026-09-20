import 'package:equatable/equatable.dart';
import '../models/nearby_doctor.dart';
import '../services/distance_calculator.dart';

sealed class DoctorSearchState extends Equatable {
  const DoctorSearchState();
}

/// Screen just opened, no search initiated yet.
final class DoctorSearchInitial extends DoctorSearchState {
  const DoctorSearchInitial();
  @override
  List<Object?> get props => [];
}

/// An async operation is in progress (permission check, GPS, API call).
final class DoctorSearchLoading extends DoctorSearchState {
  const DoctorSearchLoading();
  @override
  List<Object?> get props => [];
}

/// Location permission was denied by the user.
final class DoctorSearchLocationPermissionDenied extends DoctorSearchState {
  const DoctorSearchLocationPermissionDenied();
  @override
  List<Object?> get props => [];
}

/// Location permission was permanently denied; user must go to Settings.
final class DoctorSearchLocationPermissionPermanentlyDenied
    extends DoctorSearchState {
  const DoctorSearchLocationPermissionPermanentlyDenied();
  @override
  List<Object?> get props => [];
}

/// Search completed successfully with one or more results.
final class DoctorSearchLoaded extends DoctorSearchState {
  /// Already sorted ascending by distanceKm, max 50 entries.
  final List<NearbyDoctor> doctors;
  final LatLng center;
  final int radiusKm;

  /// Total count before the 50-entry cap (for display purposes).
  final int totalFound;

  const DoctorSearchLoaded({
    required this.doctors,
    required this.center,
    required this.radiusKm,
    required this.totalFound,
  });

  @override
  List<Object?> get props => [doctors, center, radiusKm, totalFound];
}

/// Search completed but no providers were found within the radius.
final class DoctorSearchEmpty extends DoctorSearchState {
  final int radiusKm;
  const DoctorSearchEmpty({required this.radiusKm});
  @override
  List<Object?> get props => [radiusKm];
}

/// An error occurred (network failure, GPS timeout, geocoding failure).
final class DoctorSearchError extends DoctorSearchState {
  final String message;
  final bool canRetry;
  const DoctorSearchError({required this.message, this.canRetry = true});
  @override
  List<Object?> get props => [message, canRetry];
}

/// No internet connection detected before the API call.
final class DoctorSearchNoConnectivity extends DoctorSearchState {
  const DoctorSearchNoConnectivity();
  @override
  List<Object?> get props => [];
}
