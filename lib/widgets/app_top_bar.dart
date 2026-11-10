import 'package:flutter/material.dart';

import '../core/app_feedback.dart';

/// Thanh điều khiển mỏng phía trên, dùng chung cho các màn hình.
class AppTopBar extends StatelessWidget {
  final Widget title;
  final List<Widget> actions;

  const AppTopBar({super.key, required this.title, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
        ],
      ),
    );
  }
}
