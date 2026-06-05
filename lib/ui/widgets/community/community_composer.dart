import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';

class CommunityComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPost;

  const CommunityComposer({
    super.key,
    required this.controller,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Start a discussion',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          IconButton.filled(
            onPressed: onPost,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.send, size: 18),
            tooltip: 'Post',
          ),
        ],
      ),
    );
  }
}
