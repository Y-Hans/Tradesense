import 'package:flutter/material.dart';

class CryptoLoadingIndicator extends StatelessWidget {
  const CryptoLoadingIndicator({
    super.key,
    this.size = 60.0,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/animations/bitcoin_loading.gif',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
