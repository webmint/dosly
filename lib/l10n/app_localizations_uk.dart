// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get settingsTooltip => 'Налаштування';

  @override
  String get settingsTitle => 'Налаштування';

  @override
  String get bottomNavToday => 'Сьогодні';

  @override
  String get bottomNavMeds => 'Ліки';

  @override
  String get bottomNavHistory => 'Історія';

  @override
  String get settingsAppearanceHeader => 'Зовнішній вигляд';

  @override
  String get settingsUseSystemTheme => 'Системна тема';

  @override
  String get settingsUseSystemThemeSub =>
      'Використовувати налаштування пристрою';

  @override
  String get settingsThemeLight => 'Світла';

  @override
  String get settingsThemeDark => 'Темна';

  @override
  String get settingsLanguageHeader => 'Мова';

  @override
  String get settingsUseDeviceLanguage => 'Мова пристрою';

  @override
  String get settingsUseDeviceLanguageSub =>
      'Використовувати налаштування пристрою';

  @override
  String get settingsPersistenceError =>
      'Не вдалося зберегти налаштування. Спробуйте ще раз.';

  @override
  String get medsAddFabTooltip => 'Додати ліки';

  @override
  String get medsAddTitle => 'Додати ліки';

  @override
  String get medsAddNameLabel => 'Назва ліків';

  @override
  String get medsAddSaveButton => 'Зберегти';

  @override
  String get medsAddFormLabel => 'Форма препарату';

  @override
  String get medsAddFormPlaceholder => 'Оберіть форму';

  @override
  String get medsAddFormGridTitle => 'Типові форми';

  @override
  String get medsAddFormTablet => 'Таблетка';

  @override
  String get medsAddFormTabletSub => 'Пресована форма';

  @override
  String get medsAddFormCapsule => 'Капсули';

  @override
  String get medsAddFormCapsuleSub => 'Тверда желатинова оболонка';

  @override
  String get medsAddFormSyrup => 'Сироп';

  @override
  String get medsAddFormSyrupSub => 'Рідка лікарська форма';

  @override
  String get medsAddFormDrops => 'Краплі';

  @override
  String get medsAddFormDropsSub => 'Рідка крапельна форма';

  @override
  String get medsAddFormInjection => 'Ін\'єкція';

  @override
  String get medsAddFormInjectionSub => 'Внутрішньом\'язова/в/в';

  @override
  String get medsAddFormInhaler => 'Інгалятор';

  @override
  String get medsAddFormInhalerSub => 'Аерозольна форма';

  @override
  String get medsAddFormCream => 'Крем / Мазь';

  @override
  String get medsAddFormCreamSub => 'Зовнішня форма';

  @override
  String get medsAddFormSachet => 'Саше';

  @override
  String get medsAddFormSachetSub => 'Розчинний порошок';

  @override
  String get medsAddDoseLabel => 'Доза';

  @override
  String get medsAddDoseUnitLabel => 'Одиниця';

  @override
  String get medsAddQuantityLabel => 'Кількість на прийом';

  @override
  String get medsAddStockTitle => 'Залишок у пачці';

  @override
  String get medsAddStockNote =>
      'Для капсул, таблеток та подібних форм. Автоматично зменшується після кожного прийому.';

  @override
  String get medsAddStockRemainingLabel => 'Залишок';

  @override
  String get medsAddStockTotalLabel => 'Всього в пачці';

  @override
  String get medsAddStockWarnLabel => 'Попередити коли лишиться';

  @override
  String get medsAddUnitMl => 'мл';

  @override
  String get medsAddUnitMg => 'мг';

  @override
  String get medsAddUnitUnits => 'МО';

  @override
  String get medsAddUnitDrops => 'краплі';

  @override
  String get medsAddUnitTablet => 'табл';

  @override
  String get medsAddUnitCapsule => 'капс';

  @override
  String get medsAddTimeTitle => 'Час прийому';

  @override
  String get medsAddTimeAddChip => 'Час';

  @override
  String get medsAddTimeRemoveTooltip => 'Видалити час';

  @override
  String get medsAddTimeDuplicate => 'Цей час уже додано';

  @override
  String get medsAddIntakeTypeTitle => 'Тип прийому';

  @override
  String get medsAddIntakeTypeContinuous => 'Постійний';

  @override
  String get medsAddIntakeTypeCourse => 'Курс';

  @override
  String get medsAddCourseParamsTitle => 'Параметри курсу';

  @override
  String get medsAddCourseDurationLabel => 'Тривалість (дні)';

  @override
  String get medsAddCoursePauseLabel => 'Пауза (дні)';

  @override
  String get medsAddCourseStartLabel => 'Дата початку';

  @override
  String medsAddCourseRangeLabel(String range, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count днів',
      few: '$count дні',
      one: '$count день',
    );
    return 'Курс: $range ($_temp0)';
  }

  @override
  String medsAddCourseStartOnly(String date) {
    return 'Курс починається $date';
  }

  @override
  String get medsAddSaveSuccess => 'Ліки збережено';

  @override
  String get medsEditTitle => 'Редагувати ліки';

  @override
  String get medsEditSaveSuccess => 'Ліки оновлено';

  @override
  String get medsAddSaveErrorName => 'Введіть назву ліків';

  @override
  String get medsAddSaveErrorTimes => 'Додайте принаймні один час прийому';

  @override
  String get medsAddSaveErrorDuration =>
      'Тривалість курсу має бути не менше 1 дня';

  @override
  String get medsAddSaveErrorDose => 'Введіть дозу більшу за нуль';

  @override
  String get medsAddSaveErrorGeneric =>
      'Не вдалося зберегти ліки. Спробуйте ще раз.';

  @override
  String get errorScreenTitle => 'Сторінку не знайдено';

  @override
  String get errorScreenBody => 'Не вдалося знайти цей маршрут.';

  @override
  String get errorScreenGoHome => 'На головну';

  @override
  String get splashLoading => 'Завантаження…';

  @override
  String get prefsLoadErrorMessage =>
      'Не вдалося завантажити ваші налаштування.';

  @override
  String get prefsLoadRetry => 'Повторити';

  @override
  String get medsListTitle => 'Мої ліки';

  @override
  String get medsListSearchHint => 'Пошук ліків…';

  @override
  String get medsListSearchTooltip => 'Пошук';

  @override
  String get medsListFilterAll => 'Всі';

  @override
  String get medsListFilterActive => 'Активні';

  @override
  String get medsListSectionContinuous => 'Постійні';

  @override
  String get medsListSectionCourse => 'Курсові';

  @override
  String get medsListSectionEmpty => 'Нічого не знайдено';

  @override
  String get medsListEmptyTitle => 'Поки що немає ліків';

  @override
  String get medsListEmptyBody => 'Натисніть +, щоб додати перші ліки';

  @override
  String get medsListStatusActive => 'Активний';

  @override
  String get medsListStatusCompleted => 'Завершено';

  @override
  String get medsListTypeContinuous => 'постійний';

  @override
  String get medsListTypeCoursePaused => 'Пауза';

  @override
  String medsListTypeCourseDay(int current, int total) {
    return 'День $current/$total';
  }

  @override
  String medsListStock(int remaining, int total) {
    return '$remaining з $total шт';
  }

  @override
  String get doseUnitTablet => 'таб';

  @override
  String get doseUnitCapsule => 'кап';

  @override
  String get doseUnitMl => 'мл';

  @override
  String get doseUnitMg => 'мг';

  @override
  String get doseUnitDrops => 'крап';

  @override
  String get doseUnitUnits => 'МО';

  @override
  String get doseUnitPuff => 'впорск';

  @override
  String get doseUnitApplication => 'доза';

  @override
  String get doseUnitSachet => 'саше';
}
