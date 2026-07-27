# Privacy Policy & Account Deletion Architecture

## Account Deletion Compliance
To comply with Google Play Store data policy guidelines:
1. Users can request total account deletion directly within the mobile app (`ProfileScreen -> Delete Account`).
2. Calling `AuthRepository.deleteAccount()` triggers a cascade deletion on PostgreSQL tables:
   - `profiles`
   - `virtual_wallets`
   - `holdings`
   - `trades`
   - `stop_loss_orders`
   - `portfolio_snapshots`
   - `risk_scores`
   - `discipline_scores`
   - `ai_interactions`

No user trading or profile data is retained following account deletion.
