import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';

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

  @override
  void initState() {
    super.initState();
    _ageRange = RangeValues(
      _readDouble(widget.currentFilters['minAge'], 18).clamp(18, 99).toDouble(),
      _readDouble(widget.currentFilters['maxAge'], 99).clamp(18, 99).toDouble(),
    );
    if (_ageRange.start > _ageRange.end) {
      _ageRange = RangeValues(_ageRange.end, _ageRange.start);
    }
    _distance = _readDouble(widget.currentFilters['distance'], 100)
        .clamp(1, 100)
        .toDouble();
    _sortBy = widget.currentFilters['sortBy']?.toString() ?? 'nearest';
    _verifiedOnly = widget.currentFilters['verifiedOnly'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'FILTERS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppColors.blackTextColor,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Age Range
                  Text(
                    'AGE RANGE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.greyColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 99,
                    divisions: 81,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.greyColor.withOpacity(0.2),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAgeChip('${_ageRange.start.round()}'),
                      Container(
                        width: 20,
                        height: 1,
                        color: AppColors.blackColor.withOpacity(0.3),
                      ),
                      _buildAgeChip('${_ageRange.end.round()}'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Distance
                  Text(
                    'DISTANCE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.blackColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _distance,
                          min: 1,
                          max: 100,
                          divisions: 99,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.greyColor.withOpacity(0.2),
                          label: '${_distance.round()} km',
                          onChanged: (value) {
                            setState(() {
                              _distance = value;
                            });
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          '${_distance.round()} km',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Sort By
                  Text(
                    'SORT BY',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.greyColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildSortChip('Nearest', 'nearest'),
                      _buildSortChip('Active', 'active'),
                      _buildSortChip('Newest', 'newest'),
                      _buildSortChip('Match %', 'match_score'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Verified Only
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VERIFIED ONLY',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: AppColors.greyColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Show only verified profiles',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.greyColor,
                              ),
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
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withOpacity(0.3),
                          inactiveThumbColor: AppColors.greyColor,
                          inactiveTrackColor:
                              AppColors.greyColor.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Apply button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              border: Border(
                top: BorderSide(
                  color: AppColors.greyColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'APPLY FILTERS',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeChip(String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) _sortBy = value;
        });
      },
      backgroundColor: AppColors.whiteColor,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected
            ? AppColors.primary
            : AppColors.greyColor.withOpacity(0.2),
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.blackTextColor,
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _ageRange = const RangeValues(18, 99);
      _distance = 100;
      _sortBy = 'nearest';
      _verifiedOnly = false;
    });
  }

  void _applyFilters() {
    final filters = {
      'minAge': _ageRange.start.round(),
      'maxAge': _ageRange.end.round(),
      'distance': _distance.round(),
      'sortBy': _sortBy,
      'verifiedOnly': _verifiedOnly,
    };
    Navigator.pop(context, filters);
  }

  double _readDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}
