# ecoupon-lib

A flutter plugin used in the [ecoo mobile app](https://github.com/ecoo-app/ecoo-app) that provides: 

- An implementation of the [ecoo-backend](https://github.com/ecoo-app/ecoo-backend) REST API
- Tezos crypto utility functions used to:
    - generate Tezos accounts (public / secret key pairs)
    - sign payloads for meta transactions on the [ecoo smart contract](https://github.com/ecoo-app/ecoo-smart-contract)
- Secure storage implementation for iOS and Android

## Getting Started

See the `WalletService` class in `lib/services/wallet_service.dart` see how to interact with the ecoo-backend.
