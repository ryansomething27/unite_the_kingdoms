// lib/services/ads_service.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService extends ChangeNotifier {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  
  bool get isRewardedAdReady => _isRewardedAdReady;

  void initialize() {
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdReady = false;
          notifyListeners();
        },
      ),
    );
  }

  Future<bool> showRewardedAd() async {
    if (!_isRewardedAdReady || _rewardedAd == null) return false;

    bool rewardEarned = false;
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isRewardedAdReady = false;
        _loadRewardedAd();
        notifyListeners();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isRewardedAdReady = false;
        _loadRewardedAd();
        notifyListeners();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
      },
    );

    return rewardEarned;
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }
}