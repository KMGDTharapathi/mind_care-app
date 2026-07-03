import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/doctor_search_cubit.dart';
import '../cubit/doctor_search_state.dart';
import '../models/nearby_doctor.dart';
import '../widgets/doctor_card_widget.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/permission_denied_view.dart';
import '../widgets/radius_selector_widget.dart';
import '../widgets/search_bar_widget.dart';
import 'doctor_detail_screen.dart';

const _kTeal = Color(0xFF5BA8A0);

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _navigateToDetail(BuildContext context, NearbyDoctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorDetailScreen(doctor: doctor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DoctorSearchCubit>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F9),
      appBar: AppBar(
        title: const Text(
          'Find a Doctor',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _kTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar — always visible below the app bar
          SearchBarWidget(
            controller: _searchController,
            onGpsTap: () => cubit.useCurrentLocation(),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                cubit.searchByDistrict(value.trim());
              }
            },
          ),

          // Scrollable / state-driven body area
          Expanded(
            child: BlocBuilder<DoctorSearchCubit, DoctorSearchState>(
              builder: (context, state) {
                if (state is DoctorSearchInitial) {
                  return _InitialHintView();
                }

                if (state is DoctorSearchLoading) {
                  return const LoadingView();
                }

                if (state is DoctorSearchLocationPermissionDenied) {
                  return const PermissionDeniedView(isPermanent: false);
                }

                if (state is DoctorSearchLocationPermissionPermanentlyDenied) {
                  return const PermissionDeniedView(isPermanent: true);
                }

                if (state is DoctorSearchNoConnectivity) {
                  return ErrorView(
                    message:
                        'No internet connection. Please check your network and try again.',
                    onRetry: () => cubit.retry(),
                  );
                }

                if (state is DoctorSearchError) {
                  return ErrorView(
                    message: state.message,
                    onRetry: state.canRetry ? () => cubit.retry() : null,
                  );
                }

                if (state is DoctorSearchEmpty) {
                  return Column(
                    children: [
                      RadiusSelectorWidget(
                        selectedRadius: state.radiusKm,
                        onRadiusChanged: (km) => cubit.changeRadius(km),
                      ),
                      Expanded(
                        child: EmptyView(radiusKm: state.radiusKm),
                      ),
                    ],
                  );
                }

                if (state is DoctorSearchLoaded) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RadiusSelectorWidget(
                        selectedRadius: state.radiusKm,
                        onRadiusChanged: (km) => cubit.changeRadius(km),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 4),
                        child: Text(
                          '${state.totalFound} provider${state.totalFound == 1 ? '' : 's'} found',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          itemCount: state.doctors.length,
                          itemBuilder: (context, index) {
                            final doctor = state.doctors[index];
                            return DoctorCardWidget(
                              doctor: doctor,
                              onTap: () =>
                                  _navigateToDetail(context, doctor),
                              onCallTap: doctor.phone != null
                                  ? () => _launchPhone(doctor.phone!)
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }

                // Fallback — should never be reached with a sealed class
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the screen first opens and no search has been performed yet.
class _InitialHintView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 64,
              color: _kTeal,
            ),
            SizedBox(height: 16),
            Text(
              'Search by district or use GPS to find nearby mental health professionals',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
