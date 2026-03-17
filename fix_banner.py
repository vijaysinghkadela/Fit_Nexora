import re

with open('lib/widgets/subscription_banner.dart', 'r', encoding='utf-8') as f:
    text = f.read()

if 'core/extensions.dart' not in text:
    text = text.replace("import '../config/theme.dart';", "import '../config/theme.dart';\nimport '../core/extensions.dart';")

text = text.replace('class SubscriptionBanner extends StatelessWidget {', 
'''class SubscriptionBanner extends StatefulWidget {
  final Subscription? subscription;
  final VoidCallback? onUpgrade;

  const SubscriptionBanner({
    super.key,
    this.subscription,
    this.onUpgrade,
  });

  @override
  State<SubscriptionBanner> createState() => _SubscriptionBannerState();
}

class _SubscriptionBannerState extends State<SubscriptionBanner> {
  FitNexoraThemeTokens get colors => context.fitTheme;
''')

text = re.sub(r'  final Subscription\? subscription;\n  final VoidCallback\? onUpgrade;\n\n  const SubscriptionBanner\(\{.*?\}\);\n', '', text, flags=re.DOTALL)

text = text.replace('if (subscription == null)', 'if (widget.subscription == null)')
text = text.replace('final sub = subscription!;', 'final sub = widget.subscription!;')
text = text.replace('onPressed: onUpgrade,', 'onPressed: widget.onUpgrade,')
text = text.replace('sub.trialDaysRemaining', 'widget.subscription!.trialDaysRemaining')
text = text.replace('sub.planTier', 'widget.subscription!.planTier')
text = text.replace('sub.billingInterval', 'widget.subscription!.billingInterval')
text = text.replace('sub.periodDaysRemaining', 'widget.subscription!.periodDaysRemaining')


text = text.replace('class RevenueCard extends StatelessWidget {',
'''class RevenueCard extends StatefulWidget {
  final double monthlyRevenue;
  final int activeSubscriptions;
  final int newThisMonth;
  final double? growthPercent;

  const RevenueCard({
    super.key,
    this.monthlyRevenue = 0,
    this.activeSubscriptions = 0,
    this.newThisMonth = 0,
    this.growthPercent,
  });

  @override
  State<RevenueCard> createState() => _RevenueCardState();
}

class _RevenueCardState extends State<RevenueCard> {
  FitNexoraThemeTokens get colors => context.fitTheme;
''')

text = re.sub(r'  final double monthlyRevenue;\n  final int activeSubscriptions;\n  final int newThisMonth;\n  final double\? growthPercent;\n\n  const RevenueCard\(\{.*?\}\);\n', '', text, flags=re.DOTALL)

text = re.sub(r'monthlyRevenue', 'widget.monthlyRevenue', text)
text = re.sub(r'growthPercent', 'widget.growthPercent', text)
text = re.sub(r'activeSubscriptions', 'widget.activeSubscriptions', text)
text = re.sub(r'newThisMonth', 'widget.newThisMonth', text)
text = text.replace('widget.widget.', 'widget.')

with open('lib/widgets/subscription_banner.dart', 'w', encoding='utf-8') as f:
    f.write(text)
