import 'package:flutter/material.dart';
import 'portfolio_overview_page.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    // No Scaffold needed - MainLayout already provides it
    return const PortfolioOverviewPage();
  }
}
