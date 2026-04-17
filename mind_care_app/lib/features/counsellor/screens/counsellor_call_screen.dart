import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import '../models/doctor_model.dart';
import '../data/doctor_seed_service.dart';

const _kTeal = Color(0xFF5BA8A0);
const _kDark = Color(0xFF1A4A4A);

class CounsellorCallScreen extends StatefulWidget {
  const CounsellorCallScreen({super.key});

  @override
  State<CounsellorCallScreen> createState() => _CounsellorCallScreenState();
}

class _CounsellorCallScreenState extends State<CounsellorCallScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterSpec = 'All';
  String _filterLang = 'All';

  // Canonical English values used for Firestore filtering
  static const _specValues = ['All', 'Clinical Psychologist', 'Counsellor', 'Psychiatrist', 'GP'];
  static const _langValues = ['All', 'Sinhala', 'English', 'Tamil'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    DoctorSeedService.seedIfEmpty();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    final specLabels = [s.specAll, s.specClinicalPsychologist, s.specCounsellor, s.specPsychiatrist, s.specGP];
    final langLabels = [s.langAll, s.langSinhala, s.langEnglish, s.langTamil];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F9),
      appBar: AppBar(
        backgroundColor: _kTeal,
        foregroundColor: Colors.white,
        title: Text(s.counsellorCallTitle,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: const Icon(Icons.people_outline), text: s.doctorsTab),
            Tab(icon: const Icon(Icons.phone_outlined), text: s.hotlinesTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DoctorListTab(
            filterSpec: _filterSpec,
            filterLang: _filterLang,
            specValues: _specValues,
            specLabels: specLabels,
            langValues: _langValues,
            langLabels: langLabels,
            strings: s,
            onSpecChanged: (v) => setState(() => _filterSpec = v),
            onLangChanged: (v) => setState(() => _filterLang = v),
          ),
          _HotlineTab(strings: s),
        ],
      ),
    );
  }
}

// ── Doctor List Tab ───────────────────────────────────────────────────────────

class _DoctorListTab extends StatelessWidget {
  final String filterSpec;
  final String filterLang;
  final List<String> specValues;
  final List<String> specLabels;
  final List<String> langValues;
  final List<String> langLabels;
  final AppStrings strings;
  final ValueChanged<String> onSpecChanged;
  final ValueChanged<String> onLangChanged;

  const _DoctorListTab({
    required this.filterSpec,
    required this.filterLang,
    required this.specValues,
    required this.specLabels,
    required this.langValues,
    required this.langLabels,
    required this.strings,
    required this.onSpecChanged,
    required this.onLangChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterBar(
          options: specValues,
          labels: specLabels,
          selected: filterSpec,
          onChanged: onSpecChanged,
        ),
        _FilterBar(
          options: langValues,
          labels: langLabels,
          selected: filterLang,
          onChanged: onLangChanged,
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doctors')
                .where('is_verified', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorState(strings: strings, onRetry: () {});
              }
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: _kTeal));
              }

              var doctors = snapshot.data!.docs
                  .map((d) => Doctor.fromFirestore(d))
                  .where((d) {
                if (filterSpec != 'All' && d.specialization != filterSpec) {
                  return false;
                }
                if (filterLang != 'All' && !d.languages.contains(filterLang)) {
                  return false;
                }
                return true;
              }).toList();

              doctors.sort((a, b) =>
                  (b.isAvailable ? 1 : 0).compareTo(a.isAvailable ? 1 : 0));

              if (doctors.isEmpty) {
                return Center(
                  child: Text(strings.noDoctorsFound,
                      style: const TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: doctors.length,
                itemBuilder: (_, i) => _DoctorCard(doctor: doctors[i], strings: strings),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final List<String> options;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({
    required this.options,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final opt = options[i];
          final label = labels[i];
          final isSelected = opt == selected;
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? _kTeal : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? _kTeal : Colors.grey.shade300),
              ),
              child: Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  )),
            ),
          );
        },
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final AppStrings strings;
  const _DoctorCard({required this.doctor, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDoctorProfile(context, doctor),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _kTeal.withOpacity(0.15),
                    backgroundImage: doctor.photoUrl.isNotEmpty
                        ? NetworkImage(doctor.photoUrl)
                        : null,
                    child: doctor.photoUrl.isEmpty
                        ? const Icon(Icons.person, color: _kTeal, size: 30)
                        : null,
                  ),
                  if (doctor.isAvailable)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(doctor.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _kDark)),
                        ),
                        if (doctor.isVerified)
                          const Icon(Icons.verified_rounded,
                              size: 16, color: _kTeal),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(doctor.specialization,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text('${doctor.rating}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Text('(${doctor.totalReviews})',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                        const Spacer(),
                        Text(
                          doctor.sessionFeeLkr == 0
                              ? strings.freeLabel
                              : 'LKR ${doctor.sessionFeeLkr}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: doctor.sessionFeeLkr == 0
                                ? Colors.green
                                : _kTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: doctor.languages
                          .map((l) => _Chip(label: l))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDoctorProfile(BuildContext context, Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DoctorProfileSheet(doctor: doctor, strings: strings),
    );
  }
}

// ── Doctor Profile Bottom Sheet ───────────────────────────────────────────────

class _DoctorProfileSheet extends StatelessWidget {
  final Doctor doctor;
  final AppStrings strings;
  const _DoctorProfileSheet({required this.doctor, required this.strings});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _kTeal.withOpacity(0.15),
                  backgroundImage: doctor.photoUrl.isNotEmpty
                      ? NetworkImage(doctor.photoUrl)
                      : null,
                  child: doctor.photoUrl.isEmpty
                      ? const Icon(Icons.person, color: _kTeal, size: 36)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(doctor.name,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: _kDark)),
                        ),
                        if (doctor.isVerified)
                          const Icon(Icons.verified_rounded,
                              color: _kTeal, size: 18),
                      ]),
                      Text(doctor.specialization,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                      Text(doctor.hospital,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBox(
                    label: strings.ratingLabel,
                    value: '${doctor.rating}',
                    icon: Icons.star_rounded,
                    iconColor: Colors.amber),
                _StatBox(
                    label: strings.reviewsLabel,
                    value: '${doctor.totalReviews}',
                    icon: Icons.reviews_outlined,
                    iconColor: _kTeal),
                _StatBox(
                    label: strings.feeLabel,
                    value: doctor.sessionFeeLkr == 0
                        ? strings.freeLabel
                        : 'LKR ${doctor.sessionFeeLkr}',
                    icon: Icons.payments_outlined,
                    iconColor: Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            // Availability badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: doctor.isAvailable
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle,
                    size: 10,
                    color:
                        doctor.isAvailable ? Colors.green : Colors.grey),
                const SizedBox(width: 6),
                Text(
                  doctor.isAvailable ? strings.availableNow : strings.currentlyUnavailable,
                  style: TextStyle(
                      fontSize: 13,
                      color: doctor.isAvailable
                          ? Colors.green
                          : Colors.grey,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            _SectionTitle(strings.aboutSection),
            Text(doctor.bio,
                style: const TextStyle(
                    fontSize: 14, color: Colors.black87, height: 1.5)),
            const SizedBox(height: 14),
            _SectionTitle(strings.qualificationsSection),
            ...doctor.qualifications.map((q) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.school_outlined,
                        size: 16, color: _kTeal),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(q,
                            style: const TextStyle(fontSize: 13))),
                  ]),
                )),
            const SizedBox(height: 14),
            _SectionTitle(strings.languagesSection),
            Wrap(
              spacing: 6,
              children:
                  doctor.languages.map((l) => _Chip(label: l)).toList(),
            ),
            const SizedBox(height: 6),
            Text('Reg. No: ${doctor.registrationNo}',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            // Book button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: doctor.isAvailable
                    ? () {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(strings.bookingComingSoon),
                            backgroundColor: _kTeal,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.headset_mic_outlined),
                label: Text(strings.bookAudioSession),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kTeal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hotline Tab ───────────────────────────────────────────────────────────────

class _HotlineTab extends StatelessWidget {
  final AppStrings strings;
  const _HotlineTab({required this.strings});

  static const _categoryColors = {
    'mental_health': Color(0xFF5BA8A0),
    'suicide': Color(0xFFE57373),
    'domestic_violence': Color(0xFFFF8A65),
    'emergency': Color(0xFFEF5350),
    'general': Color(0xFF78909C),
  };

  Map<String, String> _categoryLabels() => {
    'mental_health': strings.catMentalHealth,
    'suicide': strings.catCrisisSupport,
    'domestic_violence': strings.catDomesticViolence,
    'emergency': strings.catEmergency,
    'general': strings.catGeneral,
  };

  @override
  Widget build(BuildContext context) {
    final catLabels = _categoryLabels();
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance.collection('hotlines').get(),
      builder: (context, snapshot) {
        List<Hotline> hotlines;

        if (snapshot.hasError || !snapshot.hasData) {
          hotlines = Hotline.fallback;
        } else {
          hotlines = snapshot.data!.docs
              .map((d) => Hotline.fromFirestore(d))
              .toList();
          if (hotlines.isEmpty) hotlines = Hotline.fallback;
        }

        // Group by category
        final grouped = <String, List<Hotline>>{};
        for (final h in hotlines) {
          grouped.putIfAbsent(h.category, () => []).add(h);
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.hotlineInfoNote,
                    style: const TextStyle(fontSize: 13, color: Colors.green),
                  ),
                ),
              ]),
            ),
            for (final entry in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  catLabels[entry.key] ?? entry.key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _categoryColors[entry.key] ?? Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...entry.value.map((h) => _HotlineCard(
                    hotline: h,
                    accentColor:
                        _categoryColors[h.category] ?? Colors.grey,
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _HotlineCard extends StatelessWidget {
  final Hotline hotline;
  final Color accentColor;
  const _HotlineCard({required this.hotline, required this.accentColor});

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: hotline.number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.phone_outlined, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hotline.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _kDark)),
                  const SizedBox(height: 2),
                  Text(hotline.description,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.access_time_outlined,
                        size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(hotline.available,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    if (hotline.isFree) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('FREE',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            GestureDetector(
              onTap: _call,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(hotline.number,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _kTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10, color: _kTeal, fontWeight: FontWeight.w600)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kDark)),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _StatBox(
      {required this.label,
      required this.value,
      required this.icon,
      required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: iconColor, size: 22),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14, color: _kDark)),
      Text(label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
    ]);
  }
}

class _ErrorState extends StatelessWidget {
  final AppStrings strings;
  final VoidCallback onRetry;
  const _ErrorState({required this.strings, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(strings.couldNotLoadDoctors,
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: Text(strings.retry)),
      ]),
    );
  }
}
