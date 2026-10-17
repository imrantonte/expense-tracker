import 'package:flutter/material.dart';

import '../models/managed_category.dart';
import '../models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORIES
// ─────────────────────────────────────────────────────────────────────────────

/// All expense categories.
final List<Category> expenseCategories = [
  Category(
    id: 'food',
    name: 'Food',
    icon: Icons.restaurant_rounded,
    color: const Color(0xFFFF7043), // deep orange
    isIncome: false,
  ),
  Category(
    id: 'transport',
    name: 'Transport',
    icon: Icons.directions_bus_rounded,
    color: const Color(0xFF42A5F5), // blue
    isIncome: false,
  ),
  Category(
    id: 'bills',
    name: 'Bills',
    icon: Icons.receipt_long_rounded,
    color: const Color(0xFFAB47BC), // purple
    isIncome: false,
  ),
  Category(
    id: 'entertainment',
    name: 'Entertainment',
    icon: Icons.movie_rounded,
    color: const Color(0xFF5C6BC0), // indigo
    isIncome: false,
  ),
  Category(
    id: 'shopping',
    name: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: const Color(0xFFEC407A), // pink
    isIncome: false,
  ),
  Category(
    id: 'health',
    name: 'Health',
    icon: Icons.medical_services_rounded,
    color: const Color(0xFF26A69A), // teal
    isIncome: false,
  ),
  Category(
    id: 'education',
    name: 'Education',
    icon: Icons.school_rounded,
    color: const Color(0xFF78909C), // blue-grey
    isIncome: false,
  ),
  Category(
    id: 'rent',
    name: 'Rent',
    icon: Icons.home_rounded,
    color: const Color(0xFF8D6E63), // brown
    isIncome: false,
  ),
  Category(
    id: 'other_expense',
    name: 'Other',
    icon: Icons.category_rounded,
    color: const Color(0xFF90A4AE), // grey-blue
    isIncome: false,
  ),
];

/// All income categories.
final List<Category> incomeCategories = [
  Category(
    id: 'salary',
    name: 'Salary',
    icon: Icons.account_balance_wallet_rounded,
    color: const Color(0xFF00897B), // teal (primary)
    isIncome: true,
  ),
  Category(
    id: 'tutoring',
    name: 'Tutoring',
    icon: Icons.menu_book_rounded,
    color: const Color(0xFF42A5F5), // blue
    isIncome: true,
  ),
  Category(
    id: 'freelance',
    name: 'Freelance',
    icon: Icons.laptop_rounded,
    color: const Color(0xFF5C6BC0), // indigo
    isIncome: true,
  ),
  Category(
    id: 'allowance',
    name: 'Allowance',
    icon: Icons.family_restroom_rounded,
    color: const Color(0xFFFF7043), // orange
    isIncome: true,
  ),
  Category(
    id: 'scholarship',
    name: 'Scholarship',
    icon: Icons.emoji_events_rounded,
    color: const Color(0xFFFFB300), // amber
    isIncome: true,
  ),
  Category(
    id: 'gift',
    name: 'Gift',
    icon: Icons.card_giftcard_rounded,
    color: const Color(0xFFEC407A), // pink
    isIncome: true,
  ),
  Category(
    id: 'business',
    name: 'Business',
    icon: Icons.business_rounded,
    color: const Color(0xFF2E9E5B), // green
    isIncome: true,
  ),
  Category(
    id: 'other_income',
    name: 'Other',
    icon: Icons.category_rounded,
    color: const Color(0xFF90A4AE), // grey-blue
    isIncome: true,
  ),
];

/// All categories combined, keyed by id for O(1) lookup.
final Map<String, Category> categoryById = {
  for (final c in [...expenseCategories, ...incomeCategories]) c.id: c,
};

// ─────────────────────────────────────────────────────────────────────────────
// USER PROFILE
// ─────────────────────────────────────────────────────────────────────────────

/// Demo user — change name / email here to customise the demo.
final UserProfile mockUser = UserProfile(
  name: 'Ayesha Rahman',
  email: 'ayesha.rahman@gmail.com',
  currencyCode: 'BDT',
  joinedDate: DateTime(2026, 10, 6),
);

// ─────────────────────────────────────────────────────────────────────────────
// TRANSACTIONS  (October 2026)
// ─────────────────────────────────────────────────────────────────────────────

final List<TransactionItem> mockTransactions = [
  TransactionItem(
    id: 't001',
    title: 'Campus lunch',
    note: 'Canteen',
    categoryId: 'food',
    amount: 120,
    date: DateTime(2026, 10, 6),
    isIncome: false,
  ),
  TransactionItem(
    id: 't002',
    title: 'Metro to office',
    note: 'Morning commute',
    categoryId: 'transport',
    amount: 60,
    date: DateTime(2026, 10, 6),
    isIncome: false,
  ),
  TransactionItem(
    id: 't003',
    title: 'Tutoring payment',
    note: 'Weekly lessons',
    categoryId: 'tutoring',
    amount: 3000,
    date: DateTime(2026, 10, 5),
    isIncome: true,
  ),
  TransactionItem(
    id: 't004',
    title: 'Mobile data pack',
    note: '30-day internet',
    categoryId: 'other_expense',
    amount: 299,
    date: DateTime(2026, 10, 5),
    isIncome: false,
  ),
  TransactionItem(
    id: 't005',
    title: 'Shwapno groceries',
    note: 'Weekly essentials',
    categoryId: 'food',
    amount: 650,
    date: DateTime(2026, 10, 4),
    isIncome: false,
  ),
  TransactionItem(
    id: 't006',
    title: 'October rent',
    note: 'Shared apartment',
    categoryId: 'rent',
    amount: 2250,
    date: DateTime(2026, 10, 4),
    isIncome: false,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// BUDGET
// ─────────────────────────────────────────────────────────────────────────────

const Budget mockBudget = Budget(
  limit: 10000,
  alertThreshold: 0.80, // 80 %
);

// ─────────────────────────────────────────────────────────────────────────────
// MONTH SUMMARY CONSTANTS  (shown on Home & Reports)
// ─────────────────────────────────────────────────────────────────────────────
//
// These are fixed display constants for the demo; they represent the full
// October 2026 summary rather than the sum of the 6 seed transactions above.

const double mockMonthEarned = 20000;
const double mockMonthSpent = 7500;
const double mockMonthLeft = 12500;

/// Category spending breakdown for the summary charts.
/// Keys are [Category.id]; values are taka amounts.
const Map<String, double> mockCategoryBreakdown = {
  'food': 3000,
  'rent': 2250,
  'transport': 1500,
  'other_expense': 750,
};

/// Category breakdown as percentages (0–100).
const Map<String, double> mockCategoryPercent = {
  'food': 40,
  'rent': 30,
  'transport': 20,
  'other_expense': 10,
};

/// Weekly income figures (weeks 1–4 of October).
const List<double> mockWeeklyIncome = [8000, 4000, 3000, 5000];

/// Weekly expense figures (weeks 1–4 of October).
const List<double> mockWeeklyExpenses = [3200, 1900, 1300, 1100];

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATIONS
// ─────────────────────────────────────────────────────────────────────────────

final List<AppNotification> mockNotifications = [
  AppNotification(
    id: 'n001',
    title: "You've gone over your budget",
    body: "You're ৳500 over your ৳20,000 limit. Let's take a look together.",
    time: DateTime(2026, 10, 15, 9, 41), // today 9:41 AM
    type: NotificationType.budgetOver,
    unread: true,
  ),
  AppNotification(
    id: 'n002',
    title: "You've used 80% of your monthly budget",
    body:
        '৳16,000 spent of ৳20,000. A little heads-up for the month ahead.',
    time: DateTime(2026, 10, 14, 18, 20), // yesterday 6:20 PM
    type: NotificationType.budgetWarning,
    unread: true,
  ),
  AppNotification(
    id: 'n003',
    title: 'Your October budget is ready',
    body: "Your monthly limit is ৳20,000. You've got a plan!",
    time: DateTime(2026, 10, 1, 9, 0), // Oct 1 9:00 AM
    type: NotificationType.budgetSet,
    unread: false,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MANAGED CATEGORIES  (Manage Categories screen)
// ─────────────────────────────────────────────────────────────────────────────

/// Seed data for the Manage Categories screen.
/// Colors are intentional model data, not UI constants.
final List<ManagedCategory> mockManagedCategories = [
  const ManagedCategory(
    id: 'mc1',
    name: 'Groceries',
    icon: Icons.shopping_basket_rounded,
    color: Color(0xFF00897B),
    description: 'The everyday essentials',
  ),
  const ManagedCategory(
    id: 'mc2',
    name: 'Food & drink',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFFFB300),
    description: 'Coffee, bites & nights out',
  ),
  const ManagedCategory(
    id: 'mc3',
    name: 'Transport',
    icon: Icons.directions_car_rounded,
    color: Color(0xFF2196F3),
    description: 'From here to there',
  ),
  const ManagedCategory(
    id: 'mc4',
    name: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFF7E57C2),
    description: 'A little something for you',
  ),
  const ManagedCategory(
    id: 'mc5',
    name: 'Home & bills',
    icon: Icons.home_rounded,
    color: Color(0xFFE53935),
    description: 'Keeping life running',
  ),
  const ManagedCategory(
    id: 'mc6',
    name: 'Entertainment',
    icon: Icons.movie_rounded,
    color: Color(0xFFEC407A),
    description: 'All the good times',
  ),
  const ManagedCategory(
    id: 'mc7',
    name: 'Health',
    icon: Icons.favorite_rounded,
    color: Color(0xFF00897B),
    description: 'Taking care of yourself',
  ),
];
