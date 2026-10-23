# Where Did It Go? — Manual Test Plan

> Last updated: 2026-10  
> Automated coverage: `flutter test` — 61 unit tests, all passing  
> Analyzer: `flutter analyze --no-pub` — 0 issues

---

## How to run automated tests

```bash
flutter test                  # all tests
flutter test test/validators_test.dart        # auth-form validators
flutter test test/budget_threshold_test.dart  # budget logic + quiet-hours
```

---

## Manual test table

Each row is one test case. **Steps** are numbered; **Expected result** is what you should see if everything works correctly.

---

### 1. Registration

| # | Steps | Expected result |
|---|-------|-----------------|
| 1.1 | Open the app fresh (no account). Tap **Get Started** through onboarding. | Login screen appears. |
| 1.2 | Tap **Create account**. Leave all fields blank, tap **Create account** button. | SnackBar: "Please enter your full name." No navigation. |
| 1.3 | Enter name `A` (one character), valid email, strong password. Submit. | SnackBar: "Name must be at least 2 characters." |
| 1.4 | Enter a valid name, type `notanemail` in the email field. Submit. | SnackBar: "Please enter a valid email address." |
| 1.5 | Enter valid name + email, type `abc` (5 chars) as password. Submit. | SnackBar: "Password must be at least 6 characters." |
| 1.6 | Enter valid name + email + 6-char password, type different confirm password. Submit. | SnackBar: "Passwords do not match." |
| 1.7 | Fill all fields correctly (name ≥ 2 chars, valid email, passwords match ≥ 6 chars). Submit. | Loading indicator shows, then Home screen opens. User is signed in. |
| 1.8 | Try to register again with the **same email**. Submit. | SnackBar: "An account with this email already exists." |

---

### 2. Login

| # | Steps | Expected result |
|---|-------|-----------------|
| 2.1 | Open login screen. Leave both fields blank. Tap **Log in**. | SnackBar: "Please enter a valid email address." |
| 2.2 | Enter a valid email, leave password blank. Tap **Log in**. | SnackBar: "Please enter your password." |
| 2.3 | Enter correct email, wrong password. Tap **Log in**. | SnackBar: "Incorrect password. Please try again." |
| 2.4 | Enter email that has never been registered. Tap **Log in**. | SnackBar: "No account found for that email." or "Incorrect password…" (Firebase merges these for security). |
| 2.5 | Enter correct credentials. Tap **Log in**. | Home screen opens with user's name and transactions. |

---

### 3. Wrong password / lockout

| # | Steps | Expected result |
|---|-------|-----------------|
| 3.1 | Enter correct email, wrong password, and tap **Log in** 5+ times quickly. | SnackBar: "Too many attempts. Please wait a moment and try again." |

---

### 4. Forgot password

| # | Steps | Expected result |
|---|-------|-----------------|
| 4.1 | On the login screen tap **Forgot password?**. Enter a non-existent email. Submit. | Firebase still shows a success message (security best practice). No crash. |
| 4.2 | Tap **Forgot password?**. Enter a registered email. Submit. | SnackBar or dialog: confirmation that the email was sent. Check the inbox for a Firebase reset email. |
| 4.3 | Follow the reset link, set a new password. Return to the app. Log in with the new password. | Login succeeds. |

---

### 5. Logout

| # | Steps | Expected result |
|---|-------|-----------------|
| 5.1 | Go to **Profile → Log out**. Confirm in the dialog. | App returns to the login screen. No data from the previous user is visible. |
| 5.2 | Immediately after logout, tap Back. | App stays on login screen (no way back to authenticated area). |

---

### 6. Add a transaction

| # | Steps | Expected result |
|---|-------|-----------------|
| 6.1 | Tap the **＋** FAB. Select **Expense**. Leave amount blank. Tap **Save**. | SnackBar: "Please enter an amount greater than zero." |
| 6.2 | Enter `0`. Tap **Save**. | SnackBar: "Please enter an amount greater than zero." |
| 6.3 | Enter a valid amount but no category. Tap **Save**. | SnackBar: "Please select a category." |
| 6.4 | Enter amount `500`, select a category, optionally add a note. Tap **Save**. | SnackBar: "Expense saved." Form closes. Transaction appears at the top of the list. |
| 6.5 | Add an Income transaction (toggle to **Income** tab). Fill and save. | SnackBar: "Income saved." Transaction appears with green amount. |

---

### 7. Edit a transaction

| # | Steps | Expected result |
|---|-------|-----------------|
| 7.1 | Tap on any transaction in the list to open detail. Tap the **edit** icon. | Edit form opens pre-filled with the transaction's data. |
| 7.2 | Change the amount to `999`. Tap **Save**. | SnackBar: "Transaction updated." List shows updated amount. |
| 7.3 | Change the date to a different day. Save. | Transaction moves to the correct day in the list (ordered by date). |

---

### 8. Delete a transaction

| # | Steps | Expected result |
|---|-------|-----------------|
| 8.1 | Open a transaction detail. Tap the **delete** icon. Confirm. | Transaction is removed from the list immediately. |
| 8.2 | Go offline (disable Wi-Fi/data). Delete a transaction. Re-enable network. | Deletion was queued locally and syncs to Firestore automatically. |

---

### 9. Restart persistence (offline cache)

| # | Steps | Expected result |
|---|-------|-----------------|
| 9.1 | While online, add two transactions. Force-close the app. Reopen it. | Both transactions are visible immediately (loaded from Firestore cache). |
| 9.2 | Enable **Airplane mode**. Open the app. | Home screen shows cached transactions with no crash or blank screen. |

---

### 10. Offline add, later sync

| # | Steps | Expected result |
|---|-------|-----------------|
| 10.1 | Enable Airplane mode. Tap **＋**, fill in a transaction, tap **Save**. | SnackBar: "Expense saved." Transaction appears in the list (pending-write state — sync banner may show). |
| 10.2 | Disable Airplane mode. | Sync banner disappears. Transaction is visible in Firestore console. |
| 10.3 | Open a second device / browser with Firestore console. Confirm the doc appears. | Same transaction doc is present with correct fields. |

---

### 11. Budget alert

| # | Steps | Expected result |
|---|-------|-----------------|
| 11.1 | Go to **Profile → Set Monthly Budget**. Enter a limit of **1000**, threshold **80%**, toggle Notify **on**. Save. | Budget card appears on Home and Reports with the set limit. |
| 11.2 | Add expenses totalling **800** (≥ 80% of 1000). | A budget warning notification appears in the Notifications tab: "You've used 80% of your monthly budget." |
| 11.3 | Add expenses totalling more than **1000**. | A "You've gone over your budget" notification appears. A dialog may also pop up. |
| 11.4 | Add more expenses after the over-limit notification. | No duplicate notifications for the same month. |

---

### 12. Categories

| # | Steps | Expected result |
|---|-------|-----------------|
| 12.1 | Go to **Profile → Manage Categories**. Tap **＋** to add a new category. Fill in name, choose icon and colour. Save. | New category appears in the list and is selectable when adding a transaction. |
| 12.2 | Long-press (or tap edit icon on) an existing category. Change its name. Save. | Updated name appears everywhere (transaction list, add form, reports). |
| 12.3 | Try to delete a category that has existing transactions. | Error/SnackBar: "Can't delete — this category has transactions." Category is not removed. |
| 12.4 | Delete a category that has **no** transactions. Confirm. | Category disappears from the list and from the add-transaction form. |

---

### 13. Reports — real data

| # | Steps | Expected result |
|---|-------|-----------------|
| 13.1 | Open **Reports** tab. Select **Daily** sub-tab. Navigate to today. | Summary cards show today's income/expenses. Bar chart shows one bar for today. Donut reflects categories. |
| 13.2 | Select **Weekly** sub-tab. | Bar chart shows 7 bars (Mon–Sun). Summary cards reflect the week. |
| 13.3 | Select **Monthly** sub-tab. Use the month picker to choose a past month with no data. | All cards show ৳0. Chart is empty. Friendly empty-state message is shown. |
| 13.4 | Navigate to the current month. | Budget card shows the limit and used amount. Correct % fill on the progress bar. |

---

### 14. Dark mode

| # | Steps | Expected result |
|---|-------|-----------------|
| 14.1 | Go to **Profile → Appearance**. Tap **Dark**. | Entire app switches to dark palette immediately. Status-bar icons go light. |
| 14.2 | Force-close the app. Reopen. | Dark mode is still active (persisted in SharedPreferences). No white flash before the first frame. |
| 14.3 | Tap **Light**. | App switches back to light palette. |
| 14.4 | Tap **System**. Change the phone's system theme in Android Settings. | App follows the system setting. |
| 14.5 | While in dark mode, open Add Transaction, Manage Categories, Set Budget, Notifications, Edit Profile, Reports, About. | All screens use dark backgrounds and light text. No white boxes or unreadable text. Charts use dark-mode colours. |

---

### 15. Notification settings persist

| # | Steps | Expected result |
|---|-------|-----------------|
| 15.1 | Go to **Profile → Notifications**. Enable **Expense reminders**. | System permission dialog appears (Android 13+). Grant it. Toggle stays ON. |
| 15.2 | Set interval to **3 hours**, quiet hours **22:00 → 08:00**, **Skip if logged** ON. | Settings are saved. |
| 15.3 | Log out. Log back in. Return to Notifications screen. | All settings are restored from Firestore (reminders on, 3h, same quiet hours, skip on). |
| 15.4 | Toggle reminders OFF. | All scheduled notifications are cancelled. None fires. |

---

### 16. Delete account

| # | Steps | Expected result |
|---|-------|-----------------|
| 16.1 | Go to **Profile → scroll to bottom → Delete account**. Enter wrong password. | SnackBar: "Incorrect password. Please try again." Account is NOT deleted. |
| 16.2 | Enter correct password. Confirm deletion. | Loading indicator, then app returns to login/register screen. |
| 16.3 | Try to log in with the deleted credentials. | SnackBar: "No account found for that email." / "Incorrect password." |
| 16.4 | Open Firestore console. Check `users/{uid}`. | The document and all subcollections (transactions, categories, budgets) are gone. |

---

## Notes on test environment

- **Offline tests**: use Android's quick-settings Wi-Fi toggle or Airplane mode.
- **Budget tests**: it is easiest to set a small limit (e.g. ৳100) and add a ৳90 expense to trigger the 80% threshold.
- **Firebase emulator**: for repeatable automated testing, consider using the Firebase Local Emulator Suite with `flutter test --dart-define=USE_EMULATOR=true`.
- **Battery optimisation**: on some Android devices, notifications may be delayed up to 15 minutes in Doze mode. To get reliable delivery during testing, go to **Settings → Apps → Where Did It Go? → Battery → Unrestricted**.
