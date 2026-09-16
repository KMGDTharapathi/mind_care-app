import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import '../models/doctor_model.dart';
import '../data/doctor_seed_service.dart';
import '../data/doctor_seed_data.dart';

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
  String _selectedProvince = 'All Provinces';

  // Canonical English values used for filtering
  static const _specValues = [
    'All',
    'Clinical Psychologist',
    'Counsellor',
    'Psychiatrist',
    'GP',
  ];
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
    final specLabels = [
      s.specAll,
      s.specClinicalPsychologist,
      s.specCounsellor,
      s.specPsychiatrist,
      s.specGP,
    ];
    final langLabels = [s.langAll, s.langSinhala, s.langEnglish, s.langTamil];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F9),
      appBar: AppBar(
        backgroundColor: _kTeal,
        foregroundColor: Colors.white,
        title: Text(
          s.counsellorCallTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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
            filterProvince: _selectedProvince,
            specValues: _specValues,
            specLabels: specLabels,
            langValues: _langValues,
            langLabels: langLabels,
            strings: s,
            onSpecChanged: (v) => setState(() => _filterSpec = v),
            onLangChanged: (v) => setState(() => _filterLang = v),
            onProvinceChanged: (v) => setState(() => _selectedProvince = v),
          ),
          _HotlineTab(strings: s),
        ],
      ),
    );
  }
}

// ── Doctor List Tab ───────────────────────────────────────────────────────────

class _DoctorListTab extends StatefulWidget {
  final String filterSpec;
  final String filterLang;
  final String filterProvince;
  final List<String> specValues;
  final List<String> specLabels;
  final List<String> langValues;
  final List<String> langLabels;
  final AppStrings strings;
  final ValueChanged<String> onSpecChanged;
  final ValueChanged<String> onLangChanged;
  final ValueChanged<String> onProvinceChanged;

  const _DoctorListTab({
    required this.filterSpec,
    required this.filterLang,
    required this.filterProvince,
    required this.specValues,
    required this.specLabels,
    required this.langValues,
    required this.langLabels,
    required this.strings,
    required this.onSpecChanged,
    required this.onLangChanged,
    required this.onProvinceChanged,
  });

  @override
  State<_DoctorListTab> createState() => _DoctorListTabState();
}

/// All 9 provinces of Sri Lanka — used for the autocomplete province selector.
const List<String> _kProvinces = [
  'All Provinces',
  'Western Province',
  'Central Province',
  'Southern Province',
  'Northern Province',
  'Eastern Province',
  'North Western Province',
  'North Central Province',
  'Uva Province',
  'Sabaragamuwa Province',
];

/// Keywords in doctor addresses that map to each province.
/// Used to filter the doctor list by selected province.
const Map<String, List<String>> _kProvinceKeywords = {
  'Western Province': [
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Angoda',
    'Dehiwala',
    'Maharagama',
    'Wattala',
    'Ragama',
    'Kelaniya',
    'Western Province',
  ],
  'Central Province': [
    'Kandy',
    'Peradeniya',
    'Matale',
    'Nuwara Eliya',
    'Central Province',
  ],
  'Southern Province': [
    'Galle',
    'Matara',
    'Hambantota',
    'Karapitiya',
    'Southern Province',
  ],
  'Northern Province': [
    'Jaffna',
    'Vavuniya',
    'Kilinochchi',
    'Mannar',
    'Northern Province',
  ],
  'Eastern Province': [
    'Batticaloa',
    'Trincomalee',
    'Ampara',
    'Eastern Province',
  ],
  'North Western Province': [
    'Kurunegala',
    'Puttalam',
    'North Western Province',
  ],
  'North Central Province': [
    'Anuradhapura',
    'Polonnaruwa',
    'North Central Province',
  ],
  'Uva Province': ['Badulla', 'Monaragala', 'Uva Province'],
  'Sabaragamuwa Province': ['Ratnapura', 'Kegalle', 'Sabaragamuwa Province'],
};

class _DoctorListTabState extends State<_DoctorListTab> {
  final _provinceController = TextEditingController();
  late String _selectedProvince;

  @override
  void initState() {
    super.initState();
    _selectedProvince = widget.filterProvince;
  }

  @override
  void dispose() {
    _provinceController.dispose();
    super.dispose();
  }

  void _onProvinceSelected(String province) {
    setState(() {
      _selectedProvince = province;
      _provinceController.text = province == 'All Provinces' ? '' : province;
      widget.onProvinceChanged(province);
    });
  }

  void _clearProvince() {
    setState(() {
      _selectedProvince = 'All Provinces';
      _provinceController.clear();
      widget.onProvinceChanged('All Provinces');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Load doctors from local seed data
    final doctors = _loadDoctorsFromSeed();

    return Column(
      children: [
        // ── Province autocomplete dropdown ───────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textValue) {
              final input = textValue.text.trim().toLowerCase();
              if (input.isEmpty) {
                return _kProvinces.skip(1);
              }
              return _kProvinces
                  .skip(1)
                  .where((p) => p.toLowerCase().startsWith(input));
            },
            displayStringForOption: (p) => p,
            onSelected: _onProvinceSelected,
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              if (_selectedProvince == 'All Provinces' &&
                  controller.text.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) controller.clear();
                });
              }
              return TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmitted(),
                decoration: InputDecoration(
                  hintText: 'Type a province (e.g. Western, Kandy...)',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: const Icon(
                    Icons.map_outlined,
                    color: _kTeal,
                    size: 20,
                  ),
                  suffixIcon: _selectedProvince != 'All Provinces'
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey,
                          ),
                          tooltip: 'Clear province filter',
                          onPressed: () {
                            controller.clear();
                            _clearProvince();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kTeal),
                  ),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final province = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(province),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: _kTeal,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  province,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _kDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Active province chip ─────────────────────────────────────────
        if (_selectedProvince != 'All Provinces')
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_outlined, size: 14, color: _kTeal),
                const SizedBox(width: 4),
                Text(
                  'Showing doctors in: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedProvince,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Spec / language filters ──────────────────────────────────────
        _FilterBar(
          options: widget.specValues,
          labels: widget.specLabels,
          selected: widget.filterSpec,
          onChanged: widget.onSpecChanged,
        ),
        _FilterBar(
          options: widget.langValues,
          labels: widget.langLabels,
          selected: widget.filterLang,
          onChanged: widget.onLangChanged,
        ),

        // ── Doctor list filtered by province ─────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _LocalDoctorList(
                doctors: doctors,
                filterSpec: widget.filterSpec,
                filterLang: widget.filterLang,
                filterProvince: widget.filterProvince,
                strings: widget.strings,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Load doctors from local seed data
  List<Doctor> _loadDoctorsFromSeed() {
    return kRealDoctors
        .where((d) => d['verified'] == true)
        .map(
          (data) => Doctor.fromMap(
            data['id'] as String? ?? data['name'] as String? ?? 'unknown',
            data,
          ),
        )
        .toList();
  }
}

// ── Local doctor list (no Firebase) ─────────────────────────────────────

class _LocalDoctorList extends StatelessWidget {
  final List<Doctor> doctors;
  final String filterSpec;
  final String filterLang;
  final String filterProvince;
  final AppStrings strings;

  const _LocalDoctorList({
    required this.doctors,
    required this.filterSpec,
    required this.filterLang,
    required this.filterProvince,
    required this.strings,
  });

  /// Returns true if the doctor's address contains any keyword for the province.
  bool _matchesProvince(Doctor doctor) {
    if (filterProvince == 'All Provinces') return true;
    final keywords = _kProvinceKeywords[filterProvince] ?? [];
    final address = (doctor.address ?? '').toLowerCase();
    final hospital = doctor.hospital.toLowerCase();
    return keywords.any(
      (kw) =>
          address.contains(kw.toLowerCase()) ||
          hospital.contains(kw.toLowerCase()),
    );
  }

  @override
  Widget build(BuildContext context) {
    var filtered = doctors.where((d) {
      if (filterSpec != 'All' && d.specialization != filterSpec) return false;
      if (filterLang != 'All' && !d.languages.contains(filterLang))
        return false;
      if (!_matchesProvince(d)) return false;
      return true;
    }).toList();

    filtered.sort(
      (a, b) => (b.isAvailable ? 1 : 0).compareTo(a.isAvailable ? 1 : 0),
    );

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_search_outlined,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                filterProvince == 'All Provinces'
                    ? strings.noDoctorsFound
                    : 'No doctors found in $filterProvince',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${filtered.length} provider${filtered.length == 1 ? '' : 's'} found',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        ...filtered.map((d) => _DoctorCard(doctor: d, strings: strings)),
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
        separatorBuilder: (_, _) => const SizedBox(width: 6),
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
                  color: isSelected ? _kTeal : Colors.grey.shade300,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
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
                    backgroundColor: _kTeal.withValues(alpha: 0.15),
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
                          child: Text(
                            doctor.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _kDark,
                            ),
                          ),
                        ),
                        if (doctor.isVerified)
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: _kTeal,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialization,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _kTeal.withValues(alpha: 0.15),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              doctor.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _kDark,
                              ),
                            ),
                          ),
                          if (doctor.isVerified)
                            const Icon(
                              Icons.verified_rounded,
                              color: _kTeal,
                              size: 18,
                            ),
                        ],
                      ),
                      Text(
                        doctor.specialization,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        doctor.hospital,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Availability badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: doctor.isAvailable
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: doctor.isAvailable ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    doctor.isAvailable
                        ? strings.availableNow
                        : strings.currentlyUnavailable,
                    style: TextStyle(
                      fontSize: 13,
                      color: doctor.isAvailable ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(strings.aboutSection),
            Text(
              doctor.bio,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            _SectionTitle(strings.qualificationsSection),
            ...doctor.qualifications.map(
              (q) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 16, color: _kTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(q, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _SectionTitle(strings.languagesSection),
            Wrap(
              spacing: 6,
              children: doctor.languages.map((l) => _Chip(label: l)).toList(),
            ),
            const SizedBox(height: 6),
            Text(
              'Reg. No: ${doctor.registrationNo}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            // ── Contact & Location ─────────────────────────────────────
            _SectionTitle(strings.contactSection),
            if (doctor.address != null && doctor.address!.isNotEmpty)
              _ContactRow(
                icon: Icons.location_on_outlined,
                label: doctor.address!,
                color: Colors.orange,
                onTap: () async {
                  final encoded = Uri.encodeComponent(doctor.address!);
                  final uri = Uri.parse('https://maps.google.com/?q=$encoded');
                  if (await canLaunchUrl(uri))
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            if (doctor.clinicHours != null && doctor.clinicHours!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.access_time_outlined,
                      size: 18,
                      color: _kTeal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        doctor.clinicHours!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
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
    // Use fallback hotlines since we don't have Firestore
    final hotlines = Hotline.fallback;

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
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.hotlineInfoNote,
                  style: const TextStyle(fontSize: 13, color: Colors.green),
                ),
              ),
            ],
          ),
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
          ...entry.value.map(
            (h) => _HotlineCard(
              hotline: h,
              accentColor: _categoryColors[h.category] ?? Colors.grey,
            ),
          ),
        ],
      ],
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
    final isSinhala = LanguageProvider.of(context).isSinhala;
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
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.phone_outlined, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotline.localName(isSinhala),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hotline.localDescription(isSinhala),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hotline.available,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (hotline.isFree) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'FREE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _call,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hotline.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  decoration: TextDecoration.underline,
                  decorationColor: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _kTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: _kTeal,
          fontWeight: FontWeight.w600,
        ),
      ),
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
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _kDark,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: _kDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
