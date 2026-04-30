import 'package:flutter/material.dart';
import '../../widgets/skillverse_app_bar.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SkillVerseAppBar(title: 'Terms of Service'),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('Terms of Service', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('Terms and conditions placeholder...'),
            ]),
          ),
        ),
      ),
    );
  }
}
