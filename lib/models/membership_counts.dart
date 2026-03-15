class MembershipCounts {
  const MembershipCounts({
    required this.total,
    required this.active,
    required this.expiring,
  });

  final int total;
  final int active;
  final int expiring;
}
