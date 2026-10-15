import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gazi_portfolio_app/data/models.dart';

/// The offline cache is the app's riskiest component: it is what makes the app
/// work with no connection, and a bug in it is invisible until someone opens the
/// app offline and sees nothing. These tests pin the round trip.
void main() {
  group('Profile', () {
    test('reads every field and keeps only usable links', () {
      final profile = Profile.fromJson({
        'fullName': 'Gazi Monir-Uz-Zaman',
        'headline': 'Senior Laravel & React Full-Stack Developer',
        'subheadline': '8+ years building web, mobile and industrial systems - ERP.',
        'summary': 'Summary text.',
        'location': 'Dhaka, Bangladesh',
        'email': 'ciphercall@gmail.com',
        'phone': '+8801710272659',
        'whatsapp': '+8801710272659',
        'linkedinUrl': 'https://www.linkedin.com/in/gazi-apu-12a16ba6',
        'githubUrl': 'https://github.com/ciphercall',
        'facebookUrl': 'https://facebook.com/apufirestl',
        'messengerUsername': 'apufirestl',
        'avatarPath': null,
        'links': {
          'whatsapp': 'https://wa.me/8801710272659?text=Hi',
          'messenger': 'https://m.me/apufirestl',
          'website': null,
          'github': '',
        },
      });

      expect(profile.fullName, 'Gazi Monir-Uz-Zaman');
      expect(profile.messengerUsername, 'apufirestl');
      expect(profile.avatarPath, isNull);

      // A null or empty href must not become a dead button on the contact screen.
      expect(profile.links.keys, containsAll(['whatsapp', 'messenger']));
      expect(profile.links.containsKey('website'), isFalse);
      expect(profile.links.containsKey('github'), isFalse);
    });

    test('survives a payload with optional fields missing', () {
      final profile = Profile.fromJson({'fullName': 'Gazi'});

      expect(profile.fullName, 'Gazi');
      expect(profile.headline, '');
      expect(profile.links, isEmpty);
    });
  });

  group('Experience', () {
    test('distinguishes part-time from full-time', () {
      final full = Experience.fromJson({
        'slug': 'a',
        'title': 'Senior Software Developer',
        'company': 'People\'s Poultry & Hatchery Limited',
        'employmentType': 'FULL_TIME',
        'startDate': '2024-10-15',
        'isCurrent': true,
      });
      final part = Experience.fromJson({
        'slug': 'b',
        'title': 'Project Manager',
        'company': 'Chittagong Soft Limited',
        'employmentType': 'PART_TIME',
        'startDate': '2021-07-01',
        'isCurrent': false,
      });

      expect(full.isPartTime, isFalse);
      expect(part.isPartTime, isTrue);
      expect(full.bullets, isEmpty);
      expect(full.tags, isEmpty);
    });
  });

  group('PortfolioSnapshot', () {
    final payload = <String, dynamic>{
      'profile': {'fullName': 'Gazi Monir-Uz-Zaman', 'headline': 'Developer'},
      'experiences': [
        {
          'slug': 'peoples-erp',
          'title': 'Senior Software Developer',
          'company': 'People\'s Poultry & Hatchery Limited',
          'employmentType': 'FULL_TIME',
          'startDate': '2024-10-15',
          'isCurrent': true,
          'bullets': ['Built things'],
          'tags': ['Laravel', 'React'],
        },
      ],
      'partTimeExperiences': [
        {
          'slug': 'chittagong-soft',
          'title': 'Project Manager',
          'company': 'Chittagong Soft Limited',
          'employmentType': 'PART_TIME',
          'startDate': '2021-07-01',
          'isCurrent': false,
        },
      ],
      'projects': [
        {
          'slug': 'swop',
          'title': 'SWOP',
          'summary': 'A decentralized marketplace.',
          'techStack': ['React', 'Node.js'],
          'featured': true,
          'images': [
            {'path': '/media/projects/1.webp', 'alt': 'Screenshot', 'width': 1920, 'height': 1080},
          ],
        },
        {
          'slug': 'other',
          'title': 'Other',
          'summary': 'Not featured.',
          'techStack': ['Laravel'],
          'featured': false,
          'images': <dynamic>[],
        },
      ],
      'skillGroups': [
        {
          'category': 'Backend',
          'items': ['PHP', 'Laravel'],
        },
      ],
      'contentHash': 'abc123',
      'fetchedAt': '2026-10-15T10:44:30.574Z',
    };

    test('survives a JSON round trip unchanged', () {
      final original = PortfolioSnapshot.fromJson(payload);
      final restored = PortfolioSnapshot.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.profile.fullName, original.profile.fullName);
      expect(restored.allExperiences.length, 2);
      expect(restored.partTimeExperiences.single.title, 'Project Manager');
      expect(restored.projects.length, 2);
      expect(restored.projects.first.images.single.alt, 'Screenshot');
      expect(restored.skillGroups.single.items, ['PHP', 'Laravel']);
      expect(restored.contentHash, 'abc123');
      expect(restored.fetchedAt.toUtc(), DateTime.utc(2026, 10, 15, 10, 44, 30, 574));
    });

    test('derives featured projects and the technology list', () {
      final snapshot = PortfolioSnapshot.fromJson(payload);

      expect(snapshot.featuredProjects.map((p) => p.slug), ['swop']);
      // Sorted and de-duplicated across every project.
      expect(snapshot.allTech, ['Laravel', 'Node.js', 'React']);
    });

    test('an empty payload yields an empty snapshot rather than throwing', () {
      final snapshot = PortfolioSnapshot.fromJson(const {});

      expect(snapshot.profile.fullName, '');
      expect(snapshot.allExperiences, isEmpty);
      expect(snapshot.projects, isEmpty);
      expect(snapshot.allTech, isEmpty);
    });
  });
}
