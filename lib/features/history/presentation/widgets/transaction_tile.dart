import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

class TransactionStatusBadge extends StatelessWidget {
  const TransactionStatusBadge({required this.status, super.key});
  final TransactionStatus status;
  @override
  Widget build(BuildContext context) {
    final (background, ink) = switch (status) {
      TransactionStatus.success => (
        const Color(0xFFEEF5F0),
        const Color(0xFF367C46),
      ),
      TransactionStatus.pending => (
        const Color(0xFFFFF4DB),
        const Color(0xFF875B00),
      ),
      TransactionStatus.failed => (
        const Color(0xFFFFEFED),
        const Color(0xFFAF382A),
      ),
      TransactionStatus.reversed => (
        const Color(0xFFEEEEF5),
        const Color(0xFF5E537E),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Switzer',
          fontWeight: FontWeight.w500,
          fontSize: 12,
          height: 1.4,
          color: ink,
        ),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.record,
    this.walletActivity = false,
    this.showAmount = true,
    super.key,
  });
  final Transaction record;
  final bool walletActivity;
  final bool showAmount;
  @override
  Widget build(BuildContext context) {
    final incoming = record.incoming(walletActivity: walletActivity);
    final neutral = record.status != TransactionStatus.success;
    final color = neutral
        ? const Color(0xFF171918)
        : incoming
        ? const Color(0xFF087A20)
        : const Color(0xFFAF382A);
    final icon = record.kind == TransactionKind.walletReturn
        ? '4e239.svg'
        : walletActivity && record.kind == TransactionKind.walletAllocation
        ? '3a8ba.svg'
        : 'c3eaf.svg';
    final bg = record.kind == TransactionKind.walletReturn
        ? const Color(0x0DC65948)
        : walletActivity && incoming
        ? const Color(0x0D0F9523)
        : incoming
        ? const Color(0xFF0F9523)
        : const Color(0xFF171918);
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final description = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        // One line, so a long name never pushes the row out of step with
        // its amount; the full name is on the detail screen.
        Text(
          record.title,
          maxLines: largeText ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            height: 1.2,
            color: Color(0xFF171918),
          ),
        ),
        Text(
          DateFormat('MMM d, y').format(record.time),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.2,
            color: Color(0xFF767676),
          ),
        ),
      ],
    );
    final amount = Text(
      showAmount
          ? '${incoming ? '+' : '−'}${Money.format(record.amountMinor)}'
          : 'Amount hidden',
      textAlign: largeText ? TextAlign.left : TextAlign.right,
      style: TextStyle(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
    final badge = TransactionStatusBadge(status: record.status);
    final symbol = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: AppSvgIcon('assets/icons/history/$icon', size: 14),
    );
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => context.push('/transactions/${record.id}'),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: largeText
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        symbol,
                        Expanded(child: description),
                      ],
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [amount, badge],
                    ),
                  ],
                )
              : Row(
                  children: [
                    symbol,
                    const SizedBox(width: 4),
                    // The amount takes the width it needs and the title
                    // gets the rest.
                    Expanded(child: description),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 2,
                      children: [amount, badge],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The month a group of transactions belongs to, with the design's rule
/// running to the trailing edge. The year is added outside the current one.
class MonthHeading extends StatelessWidget {
  const MonthHeading({required this.month, super.key});
  final DateTime month;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 10,
    children: [
      Text(
        DateFormat(
          month.year == DateTime.now().year ? 'MMMM' : 'MMMM y',
        ).format(month),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF171918),
        ),
      ),
      Expanded(
        child: SizedBox(
          height: 1,
          child: SvgPicture.asset(
            'assets/icons/history/6e8f7.svg',
            fit: BoxFit.fill,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ],
  );
}

/// Transactions grouped under month headings, as activity cards show them.
class TransactionMonthList extends StatelessWidget {
  const TransactionMonthList({
    required this.records,
    this.walletActivity = false,
    super.key,
  });
  final List<Transaction> records;
  final bool walletActivity;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, record) in records.indexed) ...[
        if (index == 0 ||
            records[index - 1].time.month != record.time.month ||
            records[index - 1].time.year != record.time.year)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 12, bottom: 8),
            child: MonthHeading(month: record.time),
          ),
        TransactionTile(record: record, walletActivity: walletActivity),
      ],
    ],
  );
}
