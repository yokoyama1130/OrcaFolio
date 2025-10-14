import 'package:flutter/material.dart';
import 'employer_home_page.dart';
import 'employer_post_page.dart';
import 'company_profile_page.dart';

class EmployerShell extends StatefulWidget {
  const EmployerShell({super.key});

  @override
  State<EmployerShell> createState() => _EmployerShellState();
}

class _EmployerShellState extends State<EmployerShell> {
  int _index = 0;
  final _pages = const [
    EmployerHomePage(),
    EmployerPostPage(),
    CompanyProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.add_business_outlined), label: 'Post'),
          NavigationDestination(icon: Icon(Icons.apartment_outlined), label: 'Company'),
        ],
      ),
    );
  }
}
