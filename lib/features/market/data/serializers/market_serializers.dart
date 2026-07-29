import '../../../../core/cache/data/serializers/cache_serializer.dart';
import '../../../../shared/models/crypto_asset.dart';
import '../../../../shared/models/market_ticker.dart';

/// Serializer for `List<CryptoAsset>` payload.
class CryptoAssetListSerializer extends JsonCacheSerializer<List<CryptoAsset>> {
  CryptoAssetListSerializer()
      : super(
          toJson: (list) => list.map((asset) => asset.toJson()).toList(),
          fromJson: (json) {
            final list = json as List<dynamic>;
            return list
                .map((e) => CryptoAsset.fromJson(e as Map<String, dynamic>))
                .toList();
          },
        );
}

/// Serializer for `Map<String, MarketTicker>` payload.
class MarketTickersMapSerializer
    extends JsonCacheSerializer<Map<String, MarketTicker>> {
  MarketTickersMapSerializer()
      : super(
          toJson: (map) => map.map((k, v) => MapEntry(k, v.toJson())),
          fromJson: (json) {
            final map = json as Map<String, dynamic>;
            return map.map(
              (k, v) => MapEntry(k, MarketTicker.fromJson(v as Map<String, dynamic>)),
            );
          },
        );
}

/// Serializer for single `MarketTicker` payload.
class MarketTickerSerializer extends JsonCacheSerializer<MarketTicker> {
  MarketTickerSerializer()
      : super(
          toJson: (ticker) => ticker.toJson(),
          fromJson: (json) => MarketTicker.fromJson(json as Map<String, dynamic>),
        );
}

/// Serializer for `List<MarketCandle>` payload.
class MarketCandleListSerializer extends JsonCacheSerializer<List<MarketCandle>> {
  MarketCandleListSerializer()
      : super(
          toJson: (list) => list.map((candle) => candle.toJson()).toList(),
          fromJson: (json) {
            final list = json as List<dynamic>;
            return list
                .map((e) => MarketCandle.fromJson(e as Map<String, dynamic>))
                .toList();
          },
        );
}
