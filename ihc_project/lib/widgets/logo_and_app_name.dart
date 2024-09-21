import 'package:flutter/material.dart';

class LogoAndAppName extends StatelessWidget {
  const LogoAndAppName({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        Icon(
          Icons.account_balance_wallet,
          size: 80,
          color: Colors.green,
        ),
        SizedBox(height: 10),
        Text(
          'FinanceTracker',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}
