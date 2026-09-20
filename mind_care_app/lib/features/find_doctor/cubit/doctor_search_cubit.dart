import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../services/distance_calculator.dart';
import '../services/firestore_doctor_service.dart';
import '../services/geocoder_service.dart';
import '../services/location_service.dart';
import '../services/overpass_service.dart';
import 'doctor_search_state.dart';

/// Tracks which operation was last performed, so [retry] knows what to repeat.
enum _Operation { firestore, gps, district }

/// Orchestrates [FirestoreDoctorService], [LocationService], [GeocoderService],
/// [OverpassService], and connectivity checks to drive the doctor-search feature.
///
/// Default behaviour (no search performed yet): loads all doctors/counsellors
/// from Firestore so the full seeded list is shown immediately.
///
/// GPS / district search: queries the Overpass API for nearby facilities and
/// merges them with the Firestore list, deduplicating by name.
class DoctorSearchCubit extends Cubit<DoctorSearchState> {
  final FirestoreDoctorService _firestoreService;
  final LocationService _locationService;
  final GeocoderService _geocoderService;
  final OverpassService _overpassService;
  final Connectivity _connectivity;

  int _radiusKm = 50;
  LatLng? _lastCenter;
  _Operation? _lastOperation;
  String? _lastDistrict;

  DoctorSearchCubit({
    required FirestoreDoctorService firestoreService,
    required LocationService locationService,
    required GeocoderService geocoderService,
    required OverpassService overpassService,
    required Connectivity connectivity,
  })  : _firestoreService = firestoreService,
        _locationService = locationService,
        _geocoderService = geocoderService,
        _overpassService = overpassService,
        _connectivity = connectivity,
        super(const DoctorSearchInitial());

  /// Called once when the screen is first built.
  ///
  /// Always loads the full Firestore list first so all seeded doctors are
  /// visible immediately. If location permission is already granted, also
  /// kicks off a GPS-based Overpass search to enrich the list with nearby
  /// facilities.
  Future<void> init() async {
    await _loadFromFirestore();

    final permission = await _locationService.checkAndRequestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await useCurrentLocation();
    }
  }

  /// Loads all verified doctors/counsellors from Firestore and emits
  /// [DoctorSearchLoaded] with the full list.
  Future<void> _loadFromFirestore() async {
    emit(const DoctorSearchLoading());
    try {
      final doctors = await _firestoreService.fetchAll();
      _lastOperation = _Operation.firestore;
      if (doctors.isEmpty) {
        emit(DoctorSearchEmpty(radiusKm: _radiusKm));
      } else {
        emit(DoctorSearchLoaded(
          doctors: doctors,
          center: const LatLng(7.8731, 80.7718), // Sri Lanka centre
          radiusKm: _radiusKm,
          totalFound: doctors.length,
        ));
      }
    } catch (e) {
      emit(DoctorSearchError(
        message: 'Could not load doctors. Please try again.',
        canRetry: true,
      ));
    }
  }

  /// Requests the device's GPS location and executes a nearby Overpass search,
  /// then merges results with the Firestore list.
  Future<void> useCurrentLocation() async {
    emit(const DoctorSearchLoading());

    final permission = await _locationService.checkAndRequestPermission();

    if (permission == LocationPermission.denied) {
      // Fall back to showing the full Firestore list
      await _loadFromFirestore();
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      emit(const DoctorSearchLocationPermissionPermanentlyDenied());
      return;
    }

    Position position;
    try {
      position = await _locationService.getCurrentPosition();
    } on TimeoutException {
      // GPS timed out — fall back to Firestore list
      await _loadFromFirestore();
      return;
    }

    _lastCenter = LatLng(position.latitude, position.longitude);
    _lastOperation = _Operation.gps;

    await _executeSearch(_lastCenter!, _radiusKm);
  }

  /// Geocodes [district] via Nominatim and executes a nearby Overpass search.
  Future<void> searchByDistrict(String district) async {
    emit(const DoctorSearchLoading());

    if (!await _hasConnectivity()) {
      emit(const DoctorSearchNoConnectivity());
      return;
    }

    final LatLng? result = await _geocoderService.geocode(district);
    if (result == null) {
      emit(DoctorSearchError(
        message:
            'No location found for "$district". Please try a different name.',
        canRetry: false,
      ));
      return;
    }

    _lastCenter = result;
    _lastDistrict = district;
    _lastOperation = _Operation.district;

    await _executeSearch(_lastCenter!, _radiusKm);
  }

  /// Changes the search radius and re-runs the last search with the new value.
  Future<void> changeRadius(int km) async {
    _radiusKm = km;
    if (_lastCenter != null &&
        (_lastOperation == _Operation.gps ||
            _lastOperation == _Operation.district)) {
      await _executeSearch(_lastCenter!, _radiusKm);
    } else {
      // No GPS/district search yet — just reload Firestore list
      await _loadFromFirestore();
    }
  }

  /// Retries the last failed operation.
  Future<void> retry() async {
    switch (_lastOperation) {
      case _Operation.gps:
        await useCurrentLocation();
      case _Operation.district:
        if (_lastDistrict != null) await searchByDistrict(_lastDistrict!);
      case _Operation.firestore:
      case null:
        await _loadFromFirestore();
    }
  }

  /// Checks connectivity, calls [OverpassService], merges with Firestore list,
  /// and emits the appropriate result state.
  Future<void> _executeSearch(LatLng center, int radiusKm) async {
    if (!await _hasConnectivity()) {
      // No connectivity — fall back to Firestore list
      await _loadFromFirestore();
      return;
    }

    try {
      // Fetch both sources in parallel
      final results = await Future.wait([
        _overpassService.searchNearby(center, radiusKm),
        _firestoreService.fetchAll(),
      ]);

      final overpassDoctors = results[0];
      final firestoreDoctors = results[1];

      // Merge: Firestore doctors first, then Overpass results not already
      // represented by name in the Firestore list
      final firestoreNames =
          firestoreDoctors.map((d) => d.name.toLowerCase()).toSet();
      final uniqueOverpass = overpassDoctors
          .where((d) => !firestoreNames.contains(d.name.toLowerCase()))
          .toList();

      final merged = [...firestoreDoctors, ...uniqueOverpass];

      if (merged.isEmpty) {
        emit(DoctorSearchEmpty(radiusKm: radiusKm));
      } else {
        emit(DoctorSearchLoaded(
          doctors: merged,
          center: center,
          radiusKm: radiusKm,
          totalFound: merged.length,
        ));
      }
    } on OverpassException {
      // Overpass failed — still show Firestore list
      await _loadFromFirestore();
    } on GeocoderException {
      emit(const DoctorSearchError(
        message: 'Could not reach the geocoding service. Please try again.',
      ));
    }
  }

  /// Returns `true` when the device has an active network connection.
  Future<bool> _hasConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}
