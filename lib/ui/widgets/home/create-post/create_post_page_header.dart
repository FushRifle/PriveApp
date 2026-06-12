part of '../../../pages/main/home/create_post_page.dart';

class _Header extends StatelessWidget {
  final String title;
  final bool isFirstStep;
  final bool isSubmitting;
  final bool canSubmit;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _Header({
    required this.title,
    required this.isFirstStep,
    required this.isSubmitting,
    required this.canSubmit,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          _CircleButton(
            icon: isFirstStep ? Icons.close : Icons.arrow_back,
            onTap: onBack,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isFirstStep ? 0 : 1,
            child: IgnorePointer(
              ignoring: isFirstStep,
              child: GestureDetector(
                onTap: canSubmit ? onSubmit : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: canSubmit
                        ? AppColors.primary
                        : AppColors.dynamicBorder.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            'Post',
                            style: TextStyle(
                              color: canSubmit
                                  ? AppColors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: AppColors.blackTextColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}
