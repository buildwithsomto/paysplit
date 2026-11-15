import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const walletCategories = [
  'Savings',
  'Emergency',
  'Rent',
  'Bills',
  'Education',
  'Travel',
  'Investment',
  'Other',
];
const beneficiaryCategories = [
  'Family',
  'Personal',
  'Rent',
  'Utilities',
  'Education',
  'Bills',
  'Other',
];

enum WalletAccent {
  green('Green', Color(0xFF10B51A)),
  blue('Blue', Color(0xFF33A7F5)),
  orange('Orange', Color(0xFFFF5834)),
  purple('Purple', Color(0xFF8862CE));

  const WalletAccent(this.label, this.color);
  final String label;
  final Color color;
}

@immutable
class WalletViewData {
  const WalletViewData({
    required this.id,
    required this.name,
    required this.category,
    required this.accent,
    required this.createdAt,
    this.targetMinor,
    this.balanceMinor = 0,
  });
  final String id;
  final String name;
  final String category;
  final WalletAccent accent;
  final DateTime createdAt;
  final int? targetMinor;
  final int balanceMinor;
}

@immutable
class BeneficiaryViewData {
  const BeneficiaryViewData({
    required this.id,
    required this.name,
    required this.bank,
    required this.accountNumber,
    required this.category,
    required this.narration,
    required this.createdAt,
  });
  final String id;
  final String name;
  final String bank;
  final String accountNumber;
  final String category;
  final String narration;
  final DateTime createdAt;
  String get maskedAccount =>
      '••••••${accountNumber.substring(accountNumber.length - 4)}';
}

@immutable
class DestinationsState {
  const DestinationsState({
    this.wallets = const [],
    this.beneficiaries = const [],
  });
  final List<WalletViewData> wallets;
  final List<BeneficiaryViewData> beneficiaries;
}

/// Local presentation records. Creating a record never provisions or funds it.
class DestinationsController extends Notifier<DestinationsState> {
  int _sequence = 0;
  @override
  DestinationsState build() => const DestinationsState();

  bool removeWallet(String id) {
    final wallet = state.wallets.where((item) => item.id == id).firstOrNull;
    if (wallet == null || wallet.balanceMinor != 0) return false;
    state = DestinationsState(
      wallets: List.unmodifiable(state.wallets.where((item) => item.id != id)),
      beneficiaries: state.beneficiaries,
    );
    return true;
  }

  void removeBeneficiary(String id) {
    state = DestinationsState(
      wallets: state.wallets,
      beneficiaries: List.unmodifiable(
        state.beneficiaries.where((item) => item.id != id),
      ),
    );
  }

  WalletViewData saveWallet({
    String? id,
    required String name,
    required String category,
    required WalletAccent accent,
    int? targetMinor,
  }) {
    WalletViewData? previous;
    for (final item in state.wallets) {
      if (item.id == id) previous = item;
    }
    final wallet = WalletViewData(
      id: previous?.id ?? 'wallet-${++_sequence}',
      name: name.trim(),
      category: category,
      accent: accent,
      targetMinor: targetMinor,
      balanceMinor: previous?.balanceMinor ?? 0,
      createdAt: previous?.createdAt ?? DateTime.now(),
    );
    state = DestinationsState(
      wallets: List.unmodifiable(
        previous == null
            ? [...state.wallets, wallet]
            : [
                for (final item in state.wallets)
                  item.id == wallet.id ? wallet : item,
              ],
      ),
      beneficiaries: state.beneficiaries,
    );
    return wallet;
  }

  BeneficiaryViewData saveBeneficiary({
    String? id,
    required String name,
    required String bank,
    required String accountNumber,
    required String category,
    required String narration,
  }) {
    BeneficiaryViewData? previous;
    for (final item in state.beneficiaries) {
      if (item.id == id) previous = item;
    }
    final beneficiary = BeneficiaryViewData(
      id: previous?.id ?? 'beneficiary-${++_sequence}',
      name: name.trim(),
      bank: bank.trim(),
      accountNumber: accountNumber.trim(),
      category: category,
      narration: narration.trim(),
      createdAt: previous?.createdAt ?? DateTime.now(),
    );
    state = DestinationsState(
      wallets: state.wallets,
      beneficiaries: List.unmodifiable(
        previous == null
            ? [...state.beneficiaries, beneficiary]
            : [
                for (final item in state.beneficiaries)
                  item.id == beneficiary.id ? beneficiary : item,
              ],
      ),
    );
    return beneficiary;
  }
}

final destinationsControllerProvider =
    NotifierProvider<DestinationsController, DestinationsState>(
      DestinationsController.new,
    );
