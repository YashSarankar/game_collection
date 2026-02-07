// import 'package:flutter/foundation.dart';
// import '../services/storage_service.dart';
// import '../constants/app_constants.dart';

// /// Provider for managing coins and rewards
// class CoinsProvider extends ChangeNotifier {
//   final StorageService _storage;

//   int _totalCoins = 0;
//   DateTime? _lastDailyRewardClaim;
//   bool _canClaimDailyReward = false;

//   CoinsProvider(this._storage) {
//     _loadData();
//   }

//   int get totalCoins => _totalCoins;
//   bool get canClaimDailyReward => _canClaimDailyReward;
//   DateTime? get lastDailyRewardClaim => _lastDailyRewardClaim;

//   Future<void> _loadData() async {
//     _totalCoins = await _storage.getTotalCoins();
//     _lastDailyRewardClaim = await _storage.getLastDailyRewardClaim();
//     _canClaimDailyReward = await _storage.canClaimDailyReward();
//     notifyListeners();
//   }

//   Future<void> addCoins(int amount) async {
//     await _storage.addCoins(amount);
//     _totalCoins += amount;
//     notifyListeners();
//   }

//   Future<bool> spendCoins(int amount) async {
//     if (_totalCoins >= amount) {
//       final success = await _storage.spendCoins(amount);
//       if (success) {
//         _totalCoins -= amount;
//         notifyListeners();
//         return true;
//       }
//     }
//     return false;
//   }

//   Future<bool> claimDailyReward() async {
//     if (_canClaimDailyReward) {
//       await _storage.setDailyRewardClaimed();
//       await addCoins(AppConstants.dailyRewardCoins);
//       _lastDailyRewardClaim = DateTime.now();
//       _canClaimDailyReward = false;
//       notifyListeners();
//       return true;
//     }
//     return false;
//   }

//   Duration? getTimeUntilNextReward() {
//     if (_lastDailyRewardClaim == null) return null;

//     final nextClaimTime = _lastDailyRewardClaim!.add(
//       AppConstants.dailyRewardCooldown,
//     );
//     final now = DateTime.now();

//     if (nextClaimTime.isAfter(now)) {
//       return nextClaimTime.difference(now);
//     }
//     return null;
//   }
// }
