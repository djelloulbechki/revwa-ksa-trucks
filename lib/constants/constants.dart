// عدد الشاحنات من 1 إلى 500
const minTrucksCount = 1;
const maxTrucksCount = 500;
final List<int> trucksCountOptions = List.generate(maxTrucksCount, (i) => i + 1);

// سنوات التصنيع
final List<String> clientYearOptions =
List.generate(50, (i) => (1990 + i).toString()); // 1990 إلى 2039


// ==================
// سنوات الصنع للسائقين
// ==================
final List<int> driverManufacturingYears = List<int>.generate(
  2025 - 1970 + 1,
      (index) => 1970 + index,
);

final List<String> driverYearOptions = [
  ...driverManufacturingYears.map((year) => year.toString()),
];

// ==================
// أنواع الشاحنات
// ==================
