// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../core/providers/coins_provider.dart';
// import '../../core/constants/app_constants.dart';

// class DailyRewardCard extends StatelessWidget {
//   final VoidCallback onClaim;

//   const DailyRewardCard({super.key, required this.onClaim});

//   String _formatDuration(Duration duration) {
//     final hours = duration.inHours;
//     final minutes = duration.inMinutes.remainder(60);

//     if (hours > 0) {
//       return '${hours}h ${minutes}m';
//     } else {
//       return '${minutes}m';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final coinsProvider = Provider.of<CoinsProvider>(context);
//     final canClaim = coinsProvider.canClaimDailyReward;
//     final timeUntilNext = coinsProvider.getTimeUntilNextReward();

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: canClaim
//               ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
//               : [Colors.grey.shade400, Colors.grey.shade600],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: (canClaim ? Colors.amber : Colors.grey).withOpacity(0.4),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Icon
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(
//               Icons.card_giftcard,
//               color: Colors.white,
//               size: 32,
//             ),
//           ),

//           const SizedBox(width: 16),

//           // Content
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Daily Reward',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   canClaim
//                       ? 'Claim ${AppConstants.dailyRewardCoins} coins!'
//                       : (timeUntilNext != null
//                             ? 'Next reward in ${_formatDuration(timeUntilNext)}'
//                             : 'Loading...'),
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.white.withOpacity(0.9),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Claim Button
//           if (canClaim)
//             ElevatedButton(
//               onPressed: () async {
//                 final success = await coinsProvider.claimDailyReward();
//                 if (success) {
//                   onClaim();
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 foregroundColor: Colors.orange,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: const Text(
//                 'Claim',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
