import 'package:analyzer/error/error.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:leancode_lint/lints/use_instead_type.dart';

final class UseDesignSystemItemConfig {
  const UseDesignSystemItemConfig(this.replacements);

  factory UseDesignSystemItemConfig.fromConfig(Map<String, Object?> json) {
    final replacements = json.entries.map(
      (entry) {
        final value = entry.value;
        if (value is! List) {
          throw ArgumentError(
            'Invalid configuration format for key: ${entry.key}',
          );
        }
        return MapEntry(
          entry.key,
          [
            for (final forbidden in value)
              (
                name: (forbidden as Map)['instead_of'] as String,
                packageName: forbidden['from_package'] as String,
                message: forbidden['message'] as String,
              ),
          ],
        );
      },
    );

    return UseDesignSystemItemConfig(Map.fromEntries(replacements));
  }

  final Map<String, List<ForbiddenItem>> replacements;
}

final class UseDesignSystemItemConfigError {
  const UseDesignSystemItemConfigError(this.replacements);

  factory UseDesignSystemItemConfigError.fromConfig(Map<String, Object?> json) {
    final mappedReplacements = json.map((key, value) {
      final normalizedValue = value.toString().trim();
      return MapEntry(key, _mapToErrorSeverity(normalizedValue));
    });

    return UseDesignSystemItemConfigError(mappedReplacements);
  }

  static ErrorSeverity _mapToErrorSeverity(String value) {
    final normalizedValue = value.trim().toLowerCase();
    switch (normalizedValue) {
      case 'warning':
        return ErrorSeverity.WARNING;
      case 'error':
        return ErrorSeverity.ERROR;
      case 'info':
        return ErrorSeverity.INFO;
      default:
        throw ArgumentError('Invalid error severity: $value');
    }
  }

  final Map<String, ErrorSeverity> replacements;
}

final class UseDesignSystemItem extends UseInsteadType {
  UseDesignSystemItem({
    required String preferredItemName,
    required Iterable<ForbiddenItem> replacements,
    required super.errorSeverity,
  }) : super(
          lintCodeName: '${ruleName}_$preferredItemName',
          replacements: {preferredItemName: replacements.toList()},
        );

  static const ruleName = 'use_design_system_item';
  static const ruleError = 'use_design_system_error';

  static Iterable<UseDesignSystemItem> getRulesListFromConfigs(
    CustomLintConfigs configs,
  ) {
    final config = UseDesignSystemItemConfig.fromConfig(
      configs.rules[ruleName]?.json ?? {},
    );

    final configError = UseDesignSystemItemConfigError.fromConfig(
      configs.rules[ruleError]?.json ?? {},
    );

    final errorSeverity = configError.replacements.values.isNotEmpty
        ? configError.replacements.values.first
        : ErrorSeverity.INFO;

    return config.replacements.entries.map(
      (entry) => UseDesignSystemItem(
        preferredItemName: entry.key,
        replacements: entry.value,
        errorSeverity: errorSeverity,
      ),
    );
  }

  @override
  String correctionMessage(String preferredItemName) {
    return 'Use the alternative defined in the design system: $preferredItemName.';
  }

  @override
  String problemMessage(String itemName) {
    return '$itemName is forbidden within this design system.';
  }
}
