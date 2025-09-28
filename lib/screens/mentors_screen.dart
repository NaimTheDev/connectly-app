import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mentor.dart';
import '../providers/mentors_providers.dart';
import '../screens/home_screen.dart'; // For MentorAvatar
import '../theme/theme.dart';
import '../widgets/spacers.dart';

/// Screen displaying list of mentors with search functionality
class MentorsScreen extends ConsumerStatefulWidget {
  const MentorsScreen({super.key});

  @override
  ConsumerState<MentorsScreen> createState() => _MentorsScreenState();
}

class _MentorsScreenState extends ConsumerState<MentorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Mentor> _filterMentors(List<Mentor> mentors) {
    if (_searchQuery.isEmpty) return mentors;

    return mentors.where((mentor) {
      return mentor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          mentor.expertise.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mentorsAsync = ref.watch(mentorsProvider);
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Mentors',
          style: textTheme.headlineSmall?.copyWith(
            color: brand.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: brand.softGrey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search mentors by name or expertise...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: brand.graphite.withOpacity(0.6),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: brand.graphite.withOpacity(0.6),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    hintStyle: TextStyle(
                      color: brand.graphite.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),
            // Mentors List
            Expanded(
              child: mentorsAsync.when(
                data: (mentors) {
                  final filteredMentors = _filterMentors(mentors);

                  if (filteredMentors.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty
                                ? Icons.people_outline
                                : Icons.search_off,
                            size: 64,
                            color: brand.graphite.withOpacity(0.5),
                          ),
                          Spacers.h16,
                          Text(
                            _searchQuery.isEmpty
                                ? 'No mentors available'
                                : 'No mentors found for "$_searchQuery"',
                            style: textTheme.bodyLarge?.copyWith(
                              color: brand.graphite.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredMentors.length,
                    separatorBuilder: (context, index) => Spacers.h12,
                    itemBuilder: (context, index) {
                      return _MentorListCard(mentor: filteredMentors[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: brand.danger),
                      Spacers.h16,
                      Text(
                        'Failed to load mentors',
                        style: textTheme.bodyLarge?.copyWith(
                          color: brand.danger,
                        ),
                      ),
                      Spacers.h8,
                      Text(
                        'Please try again later',
                        style: textTheme.bodyMedium?.copyWith(
                          color: brand.graphite.withOpacity(0.7),
                        ),
                      ),
                    ],
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

/// Card widget for displaying mentor in list view
class _MentorListCard extends StatelessWidget {
  final Mentor mentor;

  const _MentorListCard({required this.mentor});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: brand.softGrey, width: 1),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to mentor detail screen
          Navigator.of(context).pushNamed('/mentor/${mentor.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Picture
              MentorAvatar(
                name: mentor.name,
                imageUrl: mentor.imageUrl,
                size: 60,
                backgroundColor: brand.brand,
                textColor: Colors.white,
              ),
              Spacers.w16,
              // Mentor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentor.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: brand.ink,
                      ),
                    ),
                    if (mentor.expertise.isNotEmpty) ...[
                      Spacers.h4,
                      Text(
                        mentor.expertise,
                        style: textTheme.bodyMedium?.copyWith(
                          color: brand.graphite,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (mentor.bio.isNotEmpty) ...[
                      Spacers.h8,
                      Text(
                        mentor.bio,
                        style: textTheme.bodySmall?.copyWith(
                          color: brand.graphite.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: brand.graphite.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
