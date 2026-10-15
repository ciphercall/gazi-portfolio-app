/// Models for the `/api/v1` contract.
///
/// Every field here maps to a field the API actually returns — the shapes were
/// read off the running stack, not assumed. Parsing is defensive: a missing
/// optional field must never crash the app, because the whole point of this
/// client is that it keeps working from its last good snapshot.
library;

class Profile {
  const Profile({
    required this.fullName,
    required this.headline,
    required this.subheadline,
    required this.summary,
    required this.location,
    required this.email,
    required this.phone,
    required this.whatsapp,
    required this.linkedinUrl,
    required this.githubUrl,
    required this.facebookUrl,
    required this.messengerUsername,
    required this.avatarPath,
    required this.links,
  });

  final String fullName;
  final String headline;
  final String subheadline;
  final String summary;
  final String location;
  final String email;
  final String phone;
  final String whatsapp;
  final String linkedinUrl;
  final String githubUrl;
  final String facebookUrl;
  final String messengerUsername;
  final String? avatarPath;

  /// Server-computed DM links. The app never rebuilds these rules, so a change
  /// on the server takes effect without shipping a new APK.
  final Map<String, String> links;

  static Profile fromJson(Map<String, dynamic> json) {
    final rawLinks = (json['links'] as Map?) ?? const {};
    final links = <String, String>{};
    rawLinks.forEach((key, value) {
      if (value is String && value.isNotEmpty) links['$key'] = value;
    });

    String s(String key) => (json[key] as String?)?.trim() ?? '';

    return Profile(
      fullName: s('fullName'),
      headline: s('headline'),
      subheadline: s('subheadline'),
      summary: s('summary'),
      location: s('location'),
      email: s('email'),
      phone: s('phone'),
      whatsapp: s('whatsapp'),
      linkedinUrl: s('linkedinUrl'),
      githubUrl: s('githubUrl'),
      facebookUrl: s('facebookUrl'),
      messengerUsername: s('messengerUsername'),
      avatarPath: (json['avatarPath'] as String?)?.trim(),
      links: links,
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'headline': headline,
    'subheadline': subheadline,
    'summary': summary,
    'location': location,
    'email': email,
    'phone': phone,
    'whatsapp': whatsapp,
    'linkedinUrl': linkedinUrl,
    'githubUrl': githubUrl,
    'facebookUrl': facebookUrl,
    'messengerUsername': messengerUsername,
    'avatarPath': avatarPath,
    'links': links,
  };
}

class Experience {
  const Experience({
    required this.slug,
    required this.title,
    required this.company,
    required this.employmentType,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.summary,
    required this.bullets,
    required this.tags,
  });

  final String slug;
  final String title;
  final String company;
  final String employmentType;
  final String? location;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final String summary;
  final List<String> bullets;
  final List<String> tags;

  bool get isPartTime => employmentType != 'FULL_TIME';

  static Experience fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        ((json[key] as List?) ?? const []).whereType<String>().toList(growable: false);

    return Experience(
      slug: (json['slug'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      company: (json['company'] as String?) ?? '',
      employmentType: (json['employmentType'] as String?) ?? 'FULL_TIME',
      location: (json['location'] as String?)?.trim(),
      startDate: (json['startDate'] as String?) ?? '',
      endDate: (json['endDate'] as String?)?.trim(),
      isCurrent: json['isCurrent'] == true,
      summary: (json['summary'] as String?) ?? '',
      bullets: strings('bullets'),
      tags: strings('tags'),
    );
  }

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'title': title,
    'company': company,
    'employmentType': employmentType,
    'location': location,
    'startDate': startDate,
    'endDate': endDate,
    'isCurrent': isCurrent,
    'summary': summary,
    'bullets': bullets,
    'tags': tags,
  };
}

class ProjectImage {
  const ProjectImage({
    required this.path,
    required this.alt,
    required this.caption,
    required this.width,
    required this.height,
  });

  final String path;
  final String alt;
  final String? caption;
  final int width;
  final int height;

  static ProjectImage fromJson(Map<String, dynamic> json) => ProjectImage(
    path: (json['path'] as String?) ?? '',
    alt: (json['alt'] as String?) ?? '',
    caption: (json['caption'] as String?)?.trim(),
    width: (json['width'] as num?)?.toInt() ?? 0,
    height: (json['height'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'path': path,
    'alt': alt,
    'caption': caption,
    'width': width,
    'height': height,
  };
}

class Project {
  const Project({
    required this.slug,
    required this.title,
    required this.summary,
    required this.body,
    required this.role,
    required this.client,
    required this.year,
    required this.liveUrl,
    required this.repoUrl,
    required this.techStack,
    required this.coverPath,
    required this.featured,
    required this.images,
  });

  final String slug;
  final String title;
  final String summary;

  /// Markdown. Empty in list payloads — only the detail endpoint returns it.
  final String body;
  final String? role;
  final String? client;
  final int? year;
  final String? liveUrl;
  final String? repoUrl;
  final List<String> techStack;
  final String? coverPath;
  final bool featured;
  final List<ProjectImage> images;

  static Project fromJson(Map<String, dynamic> json) {
    final rawImages = (json['images'] as List?) ?? const [];

    return Project(
      slug: (json['slug'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      role: (json['role'] as String?)?.trim(),
      client: (json['client'] as String?)?.trim(),
      year: (json['year'] as num?)?.toInt(),
      liveUrl: (json['liveUrl'] as String?)?.trim(),
      repoUrl: (json['repoUrl'] as String?)?.trim(),
      techStack: ((json['techStack'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
      coverPath: (json['coverPath'] as String?)?.trim(),
      featured: json['featured'] == true,
      images: rawImages
          .whereType<Map>()
          .map((raw) => ProjectImage.fromJson(Map<String, dynamic>.from(raw)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'title': title,
    'summary': summary,
    'body': body,
    'role': role,
    'client': client,
    'year': year,
    'liveUrl': liveUrl,
    'repoUrl': repoUrl,
    'techStack': techStack,
    'coverPath': coverPath,
    'featured': featured,
    'images': images.map((image) => image.toJson()).toList(),
  };

  Project withBody(String detailBody, List<ProjectImage> detailImages) => Project(
    slug: slug,
    title: title,
    summary: summary,
    body: detailBody,
    role: role,
    client: client,
    year: year,
    liveUrl: liveUrl,
    repoUrl: repoUrl,
    techStack: techStack,
    coverPath: coverPath,
    featured: featured,
    images: detailImages,
  );
}

class SkillGroup {
  const SkillGroup({required this.category, required this.items});

  final String category;
  final List<String> items;

  static SkillGroup fromJson(Map<String, dynamic> json) => SkillGroup(
    category: (json['category'] as String?) ?? 'General',
    items: ((json['items'] as List?) ?? const []).whereType<String>().toList(growable: false),
  );

  Map<String, dynamic> toJson() => {'category': category, 'items': items};
}

/// The complete payload the app renders from. Cached as one JSON document, so a
/// snapshot is always internally consistent.
class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.profile,
    required this.experiences,
    required this.partTimeExperiences,
    required this.projects,
    required this.skillGroups,
    required this.contentHash,
    required this.fetchedAt,
  });

  final Profile profile;
  final List<Experience> experiences;
  final List<Experience> partTimeExperiences;
  final List<Project> projects;
  final List<SkillGroup> skillGroups;
  final String contentHash;
  final DateTime fetchedAt;

  List<Experience> get allExperiences => [...experiences, ...partTimeExperiences];

  List<Project> get featuredProjects =>
      projects.where((project) => project.featured).toList(growable: false);

  List<String> get allTech {
    final seen = <String>{};
    for (final project in projects) {
      seen.addAll(project.techStack);
    }
    final list = seen.toList()..sort();
    return list;
  }

  Map<String, dynamic> toJson() => {
    'profile': profile.toJson(),
    'experiences': experiences.map((item) => item.toJson()).toList(),
    'partTimeExperiences': partTimeExperiences.map((item) => item.toJson()).toList(),
    'projects': projects.map((item) => item.toJson()).toList(),
    'skillGroups': skillGroups.map((item) => item.toJson()).toList(),
    'contentHash': contentHash,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  static PortfolioSnapshot fromJson(Map<String, dynamic> json) {
    List<Experience> experiences(String key) =>
        ((json[key] as List?) ?? const [])
            .whereType<Map>()
            .map((raw) => Experience.fromJson(Map<String, dynamic>.from(raw)))
            .toList(growable: false);

    return PortfolioSnapshot(
      profile: Profile.fromJson(Map<String, dynamic>.from(json['profile'] as Map? ?? const {})),
      experiences: experiences('experiences'),
      partTimeExperiences: experiences('partTimeExperiences'),
      projects: ((json['projects'] as List?) ?? const [])
          .whereType<Map>()
          .map((raw) => Project.fromJson(Map<String, dynamic>.from(raw)))
          .toList(growable: false),
      skillGroups: ((json['skillGroups'] as List?) ?? const [])
          .whereType<Map>()
          .map((raw) => SkillGroup.fromJson(Map<String, dynamic>.from(raw)))
          .toList(growable: false),
      contentHash: (json['contentHash'] as String?) ?? '',
      fetchedAt: DateTime.tryParse((json['fetchedAt'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}
