import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';

class AdNativeCard extends StatefulWidget {
  final String placementKey;
  final bool isMediumTemplate;
  final EdgeInsetsGeometry? margin;

  const AdNativeCard({
    super.key,
    required this.placementKey,
    this.isMediumTemplate = true,
    this.margin,
  });

  @override
  State<AdNativeCard> createState() => _AdNativeCardState();
}

class _AdNativeCardState extends State<AdNativeCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    final adService = AdService();
    if (!adService.isNativePlacementEnabled(widget.placementKey)) {
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: AdService.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _hasError = false;
            });
            AnalyticsService.logAdEvent(
              adType: 'native',
              placement: widget.placementKey,
              eventType: 'impression',
            );
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdNativeCard (${widget.placementKey}) failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _hasError = true;
              _nativeAd = null;
            });
          }
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.isMediumTemplate ? TemplateType.medium : TemplateType.small,
        mainBackgroundColor: Colors.white,
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFFC62828), // Nirma Brand Red
          style: NativeTemplateFontStyle.bold,
          size: 13.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF0F172A),
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF64748B),
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF94A3B8),
          style: NativeTemplateFontStyle.normal,
          size: 11.0,
        ),
      ),
    );

    _nativeAd?.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adService = AdService();
    if (!adService.isNativePlacementEnabled(widget.placementKey) || _hasError) {
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    final double adHeight = widget.isMediumTemplate ? 320.0 : 92.0;

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 320,
            minHeight: adHeight,
            maxHeight: adHeight,
            maxWidth: double.infinity,
          ),
          child: AdWidget(ad: _nativeAd!),
        ),
      ),
    );
  }
}
