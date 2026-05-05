import 'package:flutter/material.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';

class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Matches & Connections',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // New Matches
              Text(
                'New Matches',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: AppTheme.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    final matches = [
                      {
                        'name': 'Sarah',
                        'avatar': 'profiles/profile_1.jpeg',
                        'isNew': true,
                      },
                      {
                        'name': 'Mike',
                        'avatar': 'profiles/profile_2.jpeg',
                        'isNew': true,
                      },
                      {
                        'name': 'Emma',
                        'avatar': 'profiles/profile_3.jpeg',
                        'isNew': true,
                      },
                      {
                        'name': 'James',
                        'avatar': 'profiles/profiles/profile_4.jpeg',
                        'isNew': false,
                      },
                      {
                        'name': 'Lisa',
                        'avatar': 'profiles/profile_1.jpeg',
                        'isNew': false,
                      },
                      {
                        'name': 'David',
                        'avatar': 'profiles/profile_2.jpeg',
                        'isNew': false,
                      },
                    ];
                    final match = matches[index];
                    final String name = match['name']?.toString() ?? '';
                    final String avatar = match['avatar']?.toString() ?? '';
                    final bool isNew = match['isNew'] == true;

                    return GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.purpleColor,
                                        Colors.pink,
                                      ],
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: AssetImage(avatar),
                                      ),
                                    ),
                                  ),
                                ),
                                if (isNew)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.redColor,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'NEW',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name,
                              style: AppTheme.blackTextStyle.copyWith(
                                fontSize: 12,
                                fontWeight: AppTheme.medium,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Recent Connections
              Text(
                'Recently Connected',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: AppTheme.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(4, (index) {
                final List<Map<String, String>> connections = [
                  {
                    'name': 'Sophie Anderson',
                    'username': '@sophie',
                    'avatar': 'profiles/profile_3.jpeg',
                    'time': '2m ago',
                    'mutual': '8 mutual friends',
                  },
                  {
                    'name': 'Alex Thompson',
                    'username': '@alex.t',
                    'avatar': 'profiles/profile_4.jpeg',
                    'time': '15m ago',
                    'mutual': '12 mutual friends',
                  },
                  {
                    'name': 'Olivia Chen',
                    'username': '@olivia',
                    'avatar': 'profiles/profile_1.jpeg',
                    'time': '1h ago',
                    'mutual': '5 mutual friends',
                  },
                  {
                    'name': 'Marcus Johnson',
                    'username': '@marcus',
                    'avatar': 'profiles/profile_2.jpeg',
                    'time': '2h ago',
                    'mutual': '3 mutual friends',
                  },
                ];
                final connection = connections[index];
                final String name = connection['name'] ?? '';
                final String username = connection['username'] ?? '';
                final String avatar = connection['avatar'] ?? '';
                final String time = connection['time'] ?? '';
                final String mutual = connection['mutual'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: AssetImage(avatar),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTheme.blackTextStyle.copyWith(
                                fontWeight: AppTheme.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$username · $time',
                              style: AppTheme.greyTextStyle.copyWith(
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              mutual,
                              style: AppTheme.greyTextStyle.copyWith(
                                fontSize: 11,
                                color: AppColors.purpleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.message_outlined,
                          color: AppColors.purpleColor,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
