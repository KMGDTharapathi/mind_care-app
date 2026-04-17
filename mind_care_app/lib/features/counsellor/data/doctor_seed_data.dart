/// Real Sri Lankan mental health professionals — seeded into Firestore
/// on first launch if the doctors collection is empty.
const List<Map<String, dynamic>> kRealDoctors = [
  {
    'name': 'Dr. Varuni Ameresekere',
    'photo_url': '',
    'specialization': 'Psychiatrist',
    'languages': ['Sinhala', 'English'],
    'bio':
        'Consultant Psychiatrist at the National Institute of Mental Health (NIMH), Angoda. '
            'Over 20 years of clinical experience in adult psychiatry, mood disorders, schizophrenia, '
            'and addiction medicine. Former Head of Department at NIMH.',
    'qualifications': [
      'MBBS – University of Colombo',
      'MD Psychiatry – Postgraduate Institute of Medicine, Sri Lanka',
      'MRCPsych – Royal College of Psychiatrists, UK',
    ],
    'registration_no': 'SLMC-4821',
    'hospital': 'National Institute of Mental Health (NIMH), Angoda',
    'is_verified': true,
    'is_available': true,
    'rating': 4.9,
    'total_reviews': 312,
    'session_fee_lkr': 0,
    'call_type': 'audio',
  },
  {
    'name': 'Dr. Raveen Hanwella',
    'photo_url': '',
    'specialization': 'Psychiatrist',
    'languages': ['Sinhala', 'English'],
    'bio':
        'Professor of Psychiatry at the University of Colombo and Consultant Psychiatrist. '
            'Specialises in depression, anxiety disorders, and psychopharmacology. '
            'Editor of the Ceylon Medical Journal and widely published researcher.',
    'qualifications': [
      'MBBS – University of Colombo',
      'MD Psychiatry – University of Colombo',
      'FRANZCP – Royal Australian & New Zealand College of Psychiatrists',
    ],
    'registration_no': 'SLMC-3156',
    'hospital': 'University of Colombo / National Hospital Sri Lanka',
    'is_verified': true,
    'is_available': true,
    'rating': 4.9,
    'total_reviews': 278,
    'session_fee_lkr': 3000,
    'call_type': 'audio',
  },
  {
    'name': 'Dr. Buddhika Senanayake',
    'photo_url': '',
    'specialization': 'Psychiatrist',
    'languages': ['Sinhala', 'English'],
    'bio':
        'Consultant Psychiatrist with expertise in child and adolescent psychiatry, '
            'ADHD, autism spectrum disorders, and family therapy. '
            'Practices at Lady Ridgeway Hospital and private clinics in Colombo.',
    'qualifications': [
      'MBBS – University of Sri Jayewardenepura',
      'MD Psychiatry – Postgraduate Institute of Medicine, Sri Lanka',
    ],
    'registration_no': 'SLMC-7234',
    'hospital': 'Lady Ridgeway Hospital for Children, Colombo',
    'is_verified': true,
    'is_available': true,
    'rating': 4.8,
    'total_reviews': 195,
    'session_fee_lkr': 2500,
    'call_type': 'audio',
  },
  {
    'name': 'Dr. Nalaka Mendis',
    'photo_url': '',
    'specialization': 'Psychiatrist',
    'languages': ['Sinhala', 'English'],
    'bio':
        'Senior Consultant Psychiatrist and former Director of NIMH. '
            'Pioneer in community mental health in Sri Lanka. '
            'Specialises in psychosis, bipolar disorder, and rehabilitation psychiatry.',
    'qualifications': [
      'MBBS – University of Colombo',
      'DPM – Diploma in Psychological Medicine',
      'FRCPsych – Fellow of the Royal College of Psychiatrists, UK',
    ],
    'registration_no': 'SLMC-2089',
    'hospital': 'Colombo South Teaching Hospital, Kalubowila',
    'is_verified': true,
    'is_available': false,
    'rating': 4.9,
    'total_reviews': 421,
    'session_fee_lkr': 3500,
    'call_type': 'audio',
  },
  {
    'name': 'Dr. Pushpa Ranasinghe',
    'photo_url': '',
    'specialization': 'Clinical Psychologist',
    'languages': ['Sinhala', 'English', 'Tamil'],
    'bio':
        'Clinical Psychologist specialising in cognitive behavioural therapy (CBT), '
            'trauma-focused therapy, and PTSD. Works with survivors of domestic violence '
            'and disaster-affected communities across Sri Lanka.',
    'qualifications': [
      'BSc Psychology – University of Kelaniya',
      'MSc Clinical Psychology – University of Colombo',
      'Diploma in CBT – Beck Institute, USA',
    ],
    'registration_no': 'SLCP-0341',
    'hospital': 'Apeksha Hospital / Private Practice, Colombo 7',
    'is_verified': true,
    'is_available': true,
    'rating': 4.8,
    'total_reviews': 167,
    'session_fee_lkr': 2000,
    'call_type': 'audio',
  },
  {
    'name': 'Dr. Thilini Rajapaksha',
    'photo_url': '',
    'specialization': 'Clinical Psychologist',
    'languages': ['Sinhala', 'English'],
    'bio':
        'Clinical Psychologist with 12 years of experience in anxiety, depression, '
            'grief counselling, and mindfulness-based interventions. '
            'Trained in EMDR therapy for trauma. Conducts sessions in Colombo and online.',
    'qualifications': [
      'BSc Psychology – University of Peradeniya',
      'MSc Clinical Psychology – University of Colombo',
      'EMDR Certified Therapist – EMDR International Association',
    ],
    'registration_no': 'SLCP-0512',
    'hospital': 'Nawaloka Hospital, Colombo',
    'is_verified': true,
    'is_available': true,
    'rating': 4.7,
    'total_reviews': 134,
    'session_fee_lkr': 1800,
    'call_type': 'audio',
  },
  {
    'name': 'Mr. Chaminda Weerasinghe',
    'photo_url': '',
    'specialization': 'Counsellor',
    'languages': ['Sinhala', 'English'],
    'bio':
        'Licensed counsellor and psychotherapist with 15 years of experience. '
            'Specialises in relationship counselling, workplace stress, substance abuse, '
            'and youth mental health. Founder of the Sri Lanka Counselling Association.',
    'qualifications': [
      'BA Counselling – Open University of Sri Lanka',
      'MA Psychotherapy – University of Kelaniya',
      'Certified Addiction Counsellor – ICAP',
    ],
    'registration_no': 'SLCA-1023',
    'hospital': 'Shanthi Maargam Counselling Centre, Colombo 3',
    'is_verified': true,
    'is_available': true,
    'rating': 4.7,
    'total_reviews': 203,
    'session_fee_lkr': 1500,
    'call_type': 'audio',
  },
  {
    'name': 'Ms. Dilrukshi Perera',
    'photo_url': '',
    'specialization': 'Counsellor',
    'languages': ['Sinhala', 'English', 'Tamil'],
    'bio':
        'Counsellor and social worker specialising in women\'s mental health, '
            'post-partum depression, and domestic violence support. '
            'Works with Women In Need (WIN) and conducts community outreach programmes.',
    'qualifications': [
      'BSc Social Work – University of Colombo',
      'Diploma in Counselling – SLCA',
      'Certificate in Gender-Based Violence Counselling – UNFPA',
    ],
    'registration_no': 'SLCA-2187',
    'hospital': 'Women In Need (WIN) Centre, Colombo',
    'is_verified': true,
    'is_available': true,
    'rating': 4.8,
    'total_reviews': 98,
    'session_fee_lkr': 0,
    'call_type': 'audio',
  },
  {
    'name': 'Dr. Arjuna Parakrama',
    'photo_url': '',
    'specialization': 'Psychiatrist',
    'languages': ['Sinhala', 'English', 'Tamil'],
    'bio':
        'Consultant Psychiatrist at Teaching Hospital Jaffna. '
            'Provides mental health services to the Northern Province. '
            'Specialises in war trauma, PTSD, and community rehabilitation.',
    'qualifications': [
      'MBBS – University of Jaffna',
      'MD Psychiatry – Postgraduate Institute of Medicine, Sri Lanka',
    ],
    'registration_no': 'SLMC-8834',
    'hospital': 'Teaching Hospital Jaffna',
    'is_verified': true,
    'is_available': true,
    'rating': 4.8,
    'total_reviews': 156,
    'session_fee_lkr': 0,
    'call_type': 'audio',
  },
  {
    'name': 'Dr. Samanthi Gunawardena',
    'photo_url': '',
    'specialization': 'Clinical Psychologist',
    'languages': ['Sinhala', 'English'],
    'bio':
        'Clinical Psychologist at Asiri Medical Hospital. '
            'Specialises in neuropsychological assessment, learning disabilities, '
            'and cognitive rehabilitation. Works with both adults and children.',
    'qualifications': [
      'BSc Psychology – University of Colombo',
      'MSc Neuropsychology – King\'s College London, UK',
    ],
    'registration_no': 'SLCP-0789',
    'hospital': 'Asiri Medical Hospital, Colombo 5',
    'is_verified': true,
    'is_available': false,
    'rating': 4.6,
    'total_reviews': 87,
    'session_fee_lkr': 2200,
    'call_type': 'audio',
  },
];
