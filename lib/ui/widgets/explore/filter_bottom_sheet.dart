import 'package:flutter/material.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';

class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;

  const FilterBottomSheet({
    super.key,
    required this.currentFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _ageRange;
  late double _distance;
  late String _sortBy;
  late bool _verifiedOnly;
  late String _filterType;

  @override
  void initState() {
    super.initState();
    _ageRange = RangeValues(
      (widget.currentFilters['minAge'] ?? 18).toDouble(),
      (widget.currentFilters['maxAge'] ?? 99).toDouble(),
    );
    _distance = (widget.currentFilters['distance'] ?? 100).toDouble();
    _sortBy = widget.currentFilters['sortBy'] ?? 'nearest';
    _verifiedOnly = widget.currentFilters['verifiedOnly'] ?? false;
    _filterType = widget.currentFilters['filter'] ?? 'all';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterTypeSection(),
                  const SizedBox(height: 24),
                  _buildAgeRangeSection(),
                  const SizedBox(height: 24),
                  _buildDistanceSection(),
                  const SizedBox(height: 24),
                  _buildSortSection(),
                  const SizedBox(height: 24),
                  _buildVerifiedSection(),
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
            ),
          ),
          Text(
            'Filters',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 20),
          ),
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'Reset',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Show',
          style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 12),
            _buildFilterChip('Nearby', 'nearby'),
            const SizedBox(width: 12),
            _buildFilterChip('Popular', 'popular'),
            const SizedBox(width: 12),
            _buildFilterChip('New', 'new'),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) _filterType = value;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: AppColors.purpleColor.withOpacity(0.1),
      checkmarkColor: AppColors.purpleColor,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.purpleColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? AppColors.purpleColor : Colors.transparent,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildAgeRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age Range',
          style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAgeChip(
                '${_ageRange.start.round()}', Icons.arrow_back_ios_new),
            Text(
              'to',
              style: AppTheme.greyTextStyle,
            ),
            _buildAgeChip('${_ageRange.end.round()}', Icons.arrow_forward_ios),
          ],
        ),
        RangeSlider(
          values: _ageRange,
          min: 18,
          max: 99,
          divisions: 81,
          activeColor: AppColors.purpleColor,
          inactiveColor: Colors.grey[300],
          labels: RangeLabels(
            '${_ageRange.start.round()}',
            '${_ageRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() {
              _ageRange = values;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAgeChip(String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.purpleColor),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maximum Distance',
          style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _distance,
                min: 1,
                max: 100,
                divisions: 99,
                activeColor: AppColors.purpleColor,
                inactiveColor: Colors.grey[300],
                label: '${_distance.round()} km',
                onChanged: (value) {
                  setState(() {
                    _distance = value;
                  });
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.purpleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_distance.round()} km',
                style: const TextStyle(
                  color: AppColors.purpleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            _buildSortChip('Nearest', 'nearest'),
            _buildSortChip('Most Active', 'active'),
            _buildSortChip('Recently Joined', 'newest'),
            _buildSortChip('Most Popular', 'popular'),
          ],
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) _sortBy = value;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: AppColors.purpleColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildVerifiedSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verified Users Only',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Show only verified profiles',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
            ),
          ],
        ),
        Switch(
          value: _verifiedOnly,
          onChanged: (value) {
            setState(() {
              _verifiedOnly = value;
            });
          },
          activeThumbColor: AppColors.purpleColor,
          activeTrackColor: AppColors.purpleColor.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _ageRange = const RangeValues(18, 99);
      _distance = 100;
      _sortBy = 'nearest';
      _verifiedOnly = false;
      _filterType = 'all';
    });
  }

  void _applyFilters() {
    final filters = {
      'minAge': _ageRange.start.round(),
      'maxAge': _ageRange.end.round(),
      'distance': _distance.round(),
      'sortBy': _sortBy,
      'verifiedOnly': _verifiedOnly,
      'filter': _filterType,
    };
    Navigator.pop(context, filters);
  }
}
