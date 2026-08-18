import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/contracts/provider_contracts.dart';
import '../../../shared/models/subscription_status.dart';

class RevenueCatSubscriptionRepository implements SubscriptionProvider {
  @override
  Future<void> initialize() async {
    // Initialization is already done in main.dart via Purchases.configure()
    // Here we can sync the current user ID to RevenueCat
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Purchases.logIn(user.id);
    }
  }

  @override
  Future<SubscriptionStatus> getStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPremium = customerInfo.entitlements.all['premium']?.isActive ?? false;
      return isPremium ? SubscriptionStatus.premium() : SubscriptionStatus.free();
    } catch (e) {
      return SubscriptionStatus.free();
    }
  }

  @override
  Future<bool> purchasePremium() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        final customerInfo = await Purchases.purchasePackage(offerings.current!.availablePackages.first);
        return customerInfo.entitlements.all['premium']?.isActive ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }
}
