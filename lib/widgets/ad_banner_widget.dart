import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';

class AdBannerWidget extends StatefulWidget {
  final AdSize adSize;
  final String? placementKey;
  final EdgeInsetsGeometry? margin;

  const AdBannerWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.placementKey,
    this.margin,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    final adService = AdService();
    if (!adService.isBannerPlacementEnabled(widget.placementKey ?? 'default')) {
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
            AnalyticsService.logAdEvent(
              adType: 'banner',
              placement: widget.placementKey ?? 'in_feed_banner',
              eventType: 'impression',
            );
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('AdBannerWidget (${widget.placementKey}) failed to load: $err');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
            });
          }
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adService = AdService();
    if (!adService.isBannerPlacementEnabled(widget.placementKey ?? 'default')) {
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin,
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
