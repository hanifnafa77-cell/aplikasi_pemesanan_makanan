# ✅ Revenue Calculation Update - Time Period Based

## Summary
The revenue calculation logic has been updated to use accurate time periods instead of calendar-based calculations, as specified in the requirements.

### Update Date
2024 - Latest

### Changes Applied

#### 1. Historical Revenue Calculation (calculateHistoricalRevenue)
**Location**: `lib/main.dart` ~ RevenueHistoryPersistence class

**Before (Calendar-based - INCORRECT)**:
```dart
if (originalTime.year == now.year) {
  yearRevenue += record.amount;
  if (originalTime.month == now.month) {
    monthRevenue += record.amount;
    if (originalTime.difference(now).inDays >= -6) {
      weekRevenue += record.amount;
      if (originalTime.day == now.day) {
        todayRevenue += record.amount;
      }
    }
  }
}
```

**After (Time-period based - CORRECT)**:
```dart
final daysDifference = now.difference(originalTime).inDays;
final hoursDifference = now.difference(originalTime).inHours;

if (daysDifference >= 0 && daysDifference < 365) {
  yearRevenue += record.amount;
  if (daysDifference < 30) {
    monthRevenue += record.amount;
    if (daysDifference < 7) {
      weekRevenue += record.amount;
      if (hoursDifference < 24) {
        todayRevenue += record.amount;
      }
    }
  }
}
```

#### 2. Current Orders Revenue Calculation (calculateRevenue)
**Location**: `lib/main.dart` ~ AnalyticsCalculator class

**Before (Calendar-based - INCORRECT)**:
```dart
if (order.orderTime.year == now.year) {
  yearRevenue += order.totalPrice;
  if (order.orderTime.month == now.month) {
    monthRevenue += order.totalPrice;
    if (order.orderTime.difference(now).inDays >= -6) {
      weekRevenue += order.totalPrice;
      if (order.orderTime.day == now.day) {
        todayRevenue += order.totalPrice;
      }
    }
  }
}
```

**After (Time-period based - CORRECT)**:
```dart
final daysDifference = now.difference(order.orderTime).inDays;
final hoursDifference = now.difference(order.orderTime).inHours;

if (daysDifference >= 0 && daysDifference < 365) {
  yearRevenue += order.totalPrice;
  if (daysDifference < 30) {
    monthRevenue += order.totalPrice;
    if (daysDifference < 7) {
      weekRevenue += order.totalPrice;
      if (hoursDifference < 24) {
        todayRevenue += order.totalPrice;
      }
    }
  }
}
```

### Calculation Periods (Exact as Specified)

| Period | Calculation | Example |
|--------|-------------|---------|
| **Today** (Sehari) | Last 24 hours | 2024-01-15 14:30 to 2024-01-16 14:30 |
| **Week** (Seminggu) | Last 7 days | 2024-01-09 to 2024-01-16 |
| **Month** (Sebulan) | Last 30 days | 2023-12-17 to 2024-01-16 |
| **Year** (Setahun) | Last 365 days | 2023-01-16 to 2024-01-16 |

### Key Improvements

✅ **Accurate Time Windows**: Revenue now calculated based on actual time periods, not calendar boundaries
✅ **Consistent Logic**: Both historical and current order calculations use identical time-period logic
✅ **Rolling Windows**: Revenue periods roll forward continuously (not fixed to calendar dates)
✅ **Combined Revenue**: The `calculateCombinedRevenue()` method automatically benefits from this fix

### Example Scenarios

**Scenario 1**: Order placed 2 days ago at 14:00, current time 10:00 today
- **Before**: Counted toward WEEK revenue (because same calendar month) ✗
- **After**: Only counted toward WEEK revenue (7 days) ✓

**Scenario 2**: Order placed 25 days ago at 10:00, current time 10:00 today
- **Before**: Counted toward YEAR revenue only (different month) ✗
- **After**: Counted toward MONTH and YEAR (30 days) ✓

**Scenario 3**: Order placed 8 days ago, current time 10:00
- **Before**: May not be counted (depends on calendar alignment) ✗
- **After**: Counted toward MONTH and YEAR, but NOT WEEK (>7 days) ✓

### Files Modified

| File | Line Range | Change |
|------|-----------|--------|
| lib/main.dart | ~514-560 | Updated `calculateHistoricalRevenue()` |
| lib/main.dart | ~570-606 | Updated `calculateRevenue()` |
| lib/main.dart | ~1648-1696 | Removed unused `_RevenueCard` widget |

### Testing Recommendations

1. **Verify Daily Revenue**: Create order, wait a few hours, check dashboard (should still be counted as today)
2. **Verify Weekly Revenue**: Create order from 5 days ago, verify it counts toward week revenue
3. **Verify Monthly Revenue**: Create order from 25 days ago, verify it counts toward month but NOT week
4. **Verify Yearly Revenue**: Create order from 350 days ago, verify it counts toward year only
5. **Check Dashboard**: Revenue cards should show combined totals with new time-period logic

### Backwards Compatibility

✅ **Fully Compatible**: No breaking changes to existing APIs or data structures
✅ **Existing Data**: Historical revenue records continue to work correctly
✅ **Dashboard**: No UI changes required, automatically uses new calculation logic
✅ **Combined Revenue**: `calculateCombinedRevenue()` works seamlessly with updated methods

### Verification

✅ **Compilation Status**: No errors
✅ **Code Format**: Properly formatted
✅ **Unused Code**: Cleaned up (removed `_RevenueCard` widget)
✅ **Ready to Deploy**: Yes

---

## Conclusion

The revenue calculation system now properly uses **rolling time-period windows** (24h, 7d, 30d, 365d) instead of **calendar-based periods**, providing accurate business analytics that meet the specified requirements.
