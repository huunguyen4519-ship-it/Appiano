import 'package:flutter/material.dart';

import '../core/app_feedback.dart';
import 'glass_box.dart';

/// Thanh điều khiển kính nổi phía trên, dùng chung cho các màn hình.
class AppTopBar extends StatelessWidget {
  final Widget title;
  final List<Widget> actions;

  const AppTopBar({super.key, required this.title, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: GlassBox(
        radius: 18,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Quay lại',
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  AppFeedback.tap();
                  Navigator.of(context).maybePop();
                },
              ),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.titleMedium!,
                  child: title,
                ),
              ),
              ...actions,
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
