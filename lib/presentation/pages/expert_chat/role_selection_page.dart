import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/models/expert_chat_models.dart';
import '../../providers/expert_chat_provider.dart';
import '../../themes/app_theme.dart';

/// Role Selection Page - Compact & Clean
class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String _searchQuery = '';
  String? _selectedIndustryFilter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ExpertChatProvider>(
      builder: (context, provider, _) {
        final domain = provider.selectedDomain;

        if (domain == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chọn Vai Trò')),
            body: const Center(child: Text('Vui lòng chọn lĩnh vực trước')),
          );
        }

        // Filter industries and roles
        final filteredIndustries = domain.industries.where((industry) {
          if (_selectedIndustryFilter != null &&
              _selectedIndustryFilter!.isNotEmpty &&
              industry.industry != _selectedIndustryFilter) {
            return false;
          }
          if (_searchQuery.isEmpty) return true;

          if (industry.industry.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          )) {
            return true;
          }
          return industry.roles.any(
            (role) =>
                role.jobRole.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (role.keywords?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          );
        }).toList();

        return Scaffold(
          backgroundColor: isDark
              ? AppTheme.darkBackgroundPrimary
              : AppTheme.lightBackgroundPrimary,
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  domain.domain.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Chọn vai trò chuyên gia',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: AppTheme.primaryBlueDark,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '2/2',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search and Filter
              Container(
                padding: const EdgeInsets.all(12),
                color: isDark
                    ? AppTheme.darkCardBackground
                    : AppTheme.lightCardBackground,
                child: Row(
                  children: [
                    // Search
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm vai trò...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedIndustryFilter,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        hint: const Text(
                          'Tất cả',
                          style: TextStyle(fontSize: 11),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text(
                              'Tất cả',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          ...domain.industries.map(
                            (industry) => DropdownMenuItem(
                              value: industry.industry,
                              child: Text(
                                industry.industry,
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedIndustryFilter = value?.isEmpty == true
                                ? null
                                : value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Industries and Roles
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredIndustries.length,
                  itemBuilder: (context, index) {
                    final industry = filteredIndustries[index];
                    return _IndustrySection(
                      industry: industry,
                      searchQuery: _searchQuery,
                      onRoleSelected: (role) {
                        provider.selectIndustry(industry);
                        provider.selectRole(role);
                        provider.startNewChat();
                        context.push('/expert-chat/conversation');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IndustrySection extends StatelessWidget {
  final IndustryInfo industry;
  final String searchQuery;
  final Function(RoleInfo) onRoleSelected;

  const _IndustrySection({
    required this.industry,
    required this.searchQuery,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter roles
    final filteredRoles = searchQuery.isEmpty
        ? industry.roles
        : industry.roles
              .where(
                (role) =>
                    role.jobRole.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    (role.keywords?.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();

    if (filteredRoles.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Industry Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlueDark.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.category,
                  size: 16,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  industry.industry.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlueDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${filteredRoles.length}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryBlueDark,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Roles Grid
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: filteredRoles
                .map(
                  (role) =>
                      _RoleChip(role: role, onTap: () => onRoleSelected(role)),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final RoleInfo role;
  final VoidCallback onTap;

  const _RoleChip({required this.role, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
        child: Text(
          role.jobRole,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
      ),
    );
  }
}
