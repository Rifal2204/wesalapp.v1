import 'package:flutter/material.dart';
import 'package:wesalapp/screens/myprofile_screen.dart';
import 'package:wesalapp/widget/interest_card.dart';
import 'package:wesalapp/widget/popular_group_card.dart';
import 'add_activity_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  final List<String> interests = const [
    'نادي الكتاب',
    'يوغا',
    'أصحاب المشي',
    'STEM',
  ];

  final List<Map<String, String>> groups = const [
    {
      'image': 'assets/images/explore.jpg',
      'title': 'مستكشفو نهاية الأسبوع',
      'subtitle': 'تبقى فقط 5 أماكن',
    },
    {
      'image': 'assets/images/sunset.jpg',
      'title': 'لقاء غروب الشمس',
      'subtitle': 'اقتراب من الامتلاء',
    },
    {'image': 'assets/images/bike.jpg', 'title': 'سباق دراجات', 'subtitle': ''},
    {'image': 'assets/images/flower.jpg', 'title': 'رسم', 'subtitle': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // — Header row —
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/images/profile.png'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ريفال',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'hello@reallygreatsite.com',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none),
                        onPressed: () {},
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // — Search bar —
              TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن نشاط، اهتمامات، مواعيد…',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // — Today's Agenda card —
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أنشطة اليوم',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('لقاء أصدقاء الجيم اليوم الساعة 4 مساءً'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text('انضم الآن'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // — My interests —
              const Text(
                'اهتماماتي',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: interests.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder:
                      (ctx, i) => InterestCard(
                        title: interests[i],
                        color:
                            [
                              Colors.amber.shade200,
                              Colors.red.shade200,
                              Colors.lightBlue.shade200,
                              Colors.blue.shade300,
                            ][i],
                      ),
                ),
              ),

              const SizedBox(height: 26),

              // — Popular groups grid —
              const Text(
                'مجموعات شائعة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3 / 4,
                ),
                itemBuilder:
                    (ctx, i) => PopularGroupCard(
                      imagePath: groups[i]['image']!,
                      title: groups[i]['title']!,
                      subtitle: groups[i]['subtitle']!,
                    ),
              ),

              // const SizedBox(height: 80), // leave space for bottom nav
            ],
          ),
        ),
      ),

      // — Bottom Navigation —
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1️⃣ Profile (active)
              // Container(
              //   padding: const EdgeInsets.all(2),
              //   decoration: BoxDecoration(
              //     shape: BoxShape.circle,
              //     border: Border.all(color: Colors.blue, width: 2),
              //   ),
              //   child: const Icon(Icons.person, size: 28, color: Colors.blue),
              // ),
              IconButton(
                icon: const Icon(Icons.person, size: 28),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              // 2️⃣ Notifications
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 28),
                onPressed: () {},
              ),

              // 3️⃣ Add
              IconButton(
                icon: const Icon(Icons.add_box_outlined, size: 28),
                onPressed: () async {
                  final added = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddActivityScreen(),
                    ),
                  );
                  if (added == true) {
                    // Optionally refresh activities list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت إضافة النشاط بنجاح!')),
                    );
                  }
                },
              ),

              // 4️⃣ Search
              IconButton(
                icon: const Icon(Icons.search, size: 28),
                onPressed: () {},
              ),

              // 5️⃣ Home
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  size: 28,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
