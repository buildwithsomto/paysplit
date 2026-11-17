import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/features/auth/data/models/auth_models.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/features/settings/data/repositories/profile_repository.dart';
import 'package:paysplit/features/settings/presentation/controllers/settings_controller.dart';
import 'package:paysplit/features/setup/data/repositories/setup_repository.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_controller.dart';

/// The editable part of Profile Details, as text the form shows.
@immutable
class ProfileForm {
  const ProfileForm({
    this.name = '',
    this.dialCode,
    this.phone = '',
    this.employer = '',
    this.salary = '',
    this.payDay,
  });

  /// What the form shows for [profile]. [dialCodes] maps a country code to
  /// its calling code (for example `NG` to `+234`) so the saved number can be
  /// split the way the design shows it; without a match the whole number is
  /// edited as one value.
  factory ProfileForm.of(
    UserProfile profile, {
    Map<String, String> dialCodes = const {},
  }) {
    final user = profile.user;
    final income = profile.income;
    final number = user.phoneNumber ?? '';
    final home = dialCodes[user.countryCode];
    String? dialCode;
    var phone = number;
    if (number.startsWith('+')) {
      // Longest first, so `+1` never claims a `+1242` number.
      final known = dialCodes.values.toSet().toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      dialCode = home != null && number.startsWith(home)
          ? home
          : known.where(number.startsWith).firstOrNull;
      if (dialCode != null) phone = number.substring(dialCode.length);
    } else {
      dialCode = home;
    }
    return ProfileForm(
      name: user.fullName,
      dialCode: dialCode,
      phone: phone,
      employer: income?.employerName ?? '',
      salary: income == null ? '' : Money.plain(income.monthlyAmount),
      payDay: income?.paydayDay,
    );
  }

  final String name, phone, employer, salary;

  /// Null when the calling code is unknown and [phone] holds the full number.
  final String? dialCode;
  final int? payDay;

  String get _tidyName => name.trim().replaceAll(RegExp(r'\s+'), ' ');
  String get _digits => phone.replaceAll(RegExp(r'\D'), '');

  bool sameName(ProfileForm other) => _tidyName == other._tidyName;

  bool samePhone(ProfileForm other) =>
      dialCode == other.dialCode && _digits == other._digits;

  bool sameIncome(ProfileForm other) {
    final amount = Money.parse(salary), otherAmount = Money.parse(other.salary);
    return employer.trim() == other.employer.trim() &&
        payDay == other.payDay &&
        (amount != null || otherAmount != null
            ? amount == otherAmount
            : salary.trim() == other.salary.trim());
  }
}

@immutable
class ProfileEditorState {
  const ProfileEditorState({this.errors = const {}, this.busy = false});

  /// Keyed by form field (`name`, `phone`, `employer`, `salary`, `day`);
  /// `form` holds a failure that belongs to no field.
  final Map<String, String> errors;
  final bool busy;
}

/// Saves Profile Details: personal details through `PATCH /users/me` and the
/// salary income source through `PUT /setup/income`. Only what changed is sent.
class ProfileEditorController extends Notifier<ProfileEditorState> {
  @override
  ProfileEditorState build() => const ProfileEditorState();

  void clearError(String key) {
    if (!state.errors.containsKey(key)) return;
    state = ProfileEditorState(
      errors: Map.unmodifiable({...state.errors}..remove(key)),
      busy: state.busy,
    );
  }

  /// [initial] is what the form was filled from; [form] is what it holds now.
  Future<bool> save({
    required ProfileForm initial,
    required ProfileForm form,
  }) async {
    if (state.busy) return false;
    final profile = ref.read(settingsControllerProvider).profile;
    if (profile == null) return false;

    final name = form._tidyName;
    final nameChanged = !profile.namesLocked && !form.sameName(initial);
    final phoneChanged = !form.samePhone(initial);
    final incomeChanged = !form.sameIncome(initial);
    final employer = form.employer.trim();
    final amount = Money.parse(form.salary);
    final payDay = form.payDay;
    // A leading trunk zero is dropped once the calling code is prefixed.
    final national = form.dialCode == null
        ? form._digits
        : form._digits.replaceFirst(RegExp(r'^0+'), '');
    final dialDigits = (form.dialCode ?? '').replaceAll(RegExp(r'\D'), '');

    final errors = <String, String>{
      if (nameChanged && !name.contains(' '))
        'name': 'Enter your first and last name.',
      if (phoneChanged &&
          (national.length < 7 || dialDigits.length + national.length > 15))
        'phone': 'Enter a valid phone number.',
      if (incomeChanged) ...{
        if (employer.isEmpty)
          'employer': 'Enter your employer or income source.'
        else if (employer.length > 120)
          'employer': 'Use 120 characters or fewer.',
        if (amount == null || amount <= 0)
          'salary': 'Enter a monthly salary greater than zero.',
        if (payDay == null || payDay < 1 || payDay > 31)
          'day': 'Select your expected payday.',
      },
    };
    if (errors.isNotEmpty) {
      state = ProfileEditorState(errors: Map.unmodifiable(errors));
      return false;
    }
    if (!nameChanged && !phoneChanged && !incomeChanged) return true;

    state = const ProfileEditorState(busy: true);
    final settings = ref.read(settingsControllerProvider.notifier);
    var detailsSaved = false;
    try {
      if (nameChanged || phoneChanged) {
        final (first, last) = nameChanged
            ? _splitName(name, profile.user)
            : (null, null);
        final updated = await ref
            .read(profileRepositoryProvider)
            .updateDetails(
              firstName: first,
              lastName: last,
              phoneNumber: !phoneChanged
                  ? null
                  : form.dialCode == null
                  ? form.phone.trim()
                  : '${form.dialCode}$national',
            );
        if (!ref.mounted) return false;
        // Also refreshes the name the dashboard greets.
        settings.adopt(updated);
        detailsSaved = true;
      }
      if (incomeChanged) {
        final saved = await ref
            .read(setupRepositoryProvider)
            .saveIncome(
              employerName: employer,
              monthlyAmount: amount!,
              paydayDay: payDay!,
            );
        if (!ref.mounted) return false;
        settings.adoptIncome(saved.income, onboarding: saved.onboarding);
        ref
            .read(accountControllerProvider.notifier)
            .apply(onboarding: saved.onboarding);
        // The rules screens read the salary and employer from the setup
        // state, which reloads so they show this edit.
        ref.invalidate(setupControllerProvider);
      }
      state = const ProfileEditorState();
      return true;
    } on Object catch (error) {
      if (!ref.mounted) return false;
      final failed = <String, String>{};
      if (error is ApiException) {
        switch (error.code) {
          case 'NAME_LOCKED':
            failed['name'] = error.message;
            // The profile now reports the lock; show the field read-only.
            unawaited(settings.load());
          case 'INVALID_PHONE':
            failed['phone'] = error.message;
        }
        // Validation answers name the API field in technical wording.
        const fields = {
          'firstName': ('name', 'Check your name and try again.'),
          'lastName': ('name', 'Check your name and try again.'),
          'phoneNumber': ('phone', 'Enter a valid phone number.'),
          'employerName': ('employer', 'Check your employer and try again.'),
          'monthlyAmount': ('salary', 'Enter a valid monthly salary.'),
          'paydayDay': ('day', 'Select your expected payday.'),
        };
        for (final MapEntry(key: field, value: (key, message))
            in fields.entries) {
          if (error.fieldError(field) != null) {
            failed.putIfAbsent(key, () => message);
          }
        }
      }
      if (failed.isEmpty) {
        failed['form'] = detailsSaved
            ? 'Your personal details were saved, but your salary details '
                  'were not. ${describeError(error)}'
            : describeError(error);
      }
      state = ProfileEditorState(errors: Map.unmodifiable(failed));
      return false;
    }
  }

  /// The form shows one name field; the API stores first and last name.
  /// Whichever stored part the new text still contains is kept as it was.
  static (String, String) _splitName(String name, AppUser user) {
    final first = user.firstName, last = user.lastName;
    if (first.isNotEmpty && name.startsWith('$first ')) {
      return (first, name.substring(first.length + 1));
    }
    if (last.isNotEmpty && name.endsWith(' $last')) {
      return (name.substring(0, name.length - last.length - 1), last);
    }
    final space = name.indexOf(' ');
    return (name.substring(0, space), name.substring(space + 1));
  }
}

final profileEditorProvider =
    NotifierProvider.autoDispose<ProfileEditorController, ProfileEditorState>(
      ProfileEditorController.new,
    );
